using Toybox.Application.Storage;
using Toybox.Math;

module Affect {

    // Calibration state constants
    const CALIBRATION_NOT_STARTED = 0;
    const CALIBRATION_IN_PROGRESS = 1;
    const CALIBRATION_COMPLETED = 2;

    // Baseline Calibration Manager
    // Performs 2-minute calibration to establish user's resting baseline
    // Uses streaming statistics for memory efficiency
    class CalibrationManager {
        
        // Calibration duration (120 seconds)
        private const CALIBRATION_DURATION = 120;
        
        // Minimum samples needed for valid calibration
        private const MIN_SAMPLES = 30;
        
        // Absolute minimum for demo/simulator mode
        private const MIN_SAMPLES_FALLBACK = 10;
        
        private var state;
        private var startTime;
        private var elapsedSeconds;
        
        // Streaming statistics for HR
        private var hrCount;
        private var hrSum;
        private var hrMean;
        private var hrM2;
        
        // Streaming statistics for RMSSD
        private var rmssdCount;
        private var rmssdSum;
        private var rmssdMean;
        private var rmssdM2;
        
        // Baseline values (stored after calibration)
        private var baselineHR;
        private var baselineHRStdDev;
        private var baselineRMSSD;
        private var baselineRMSSDStdDev;
        
        // Storage keys
        private const KEY_BASELINE_HR = "baseline_hr";
        private const KEY_BASELINE_HR_SD = "baseline_hr_sd";
        private const KEY_BASELINE_RMSSD = "baseline_rmssd";
        private const KEY_BASELINE_RMSSD_SD = "baseline_rmssd_sd";
        private const KEY_CALIBRATION_TIME = "calibration_time";
        
        function initialize() {
            state = CALIBRATION_NOT_STARTED;
            
            // Try to load existing baseline from storage
            loadBaseline();
            
            resetStats();
        }
        
        // Start calibration process
        function startCalibration() {
            state = CALIBRATION_IN_PROGRESS;
            startTime = Toybox.System.getTimer();
            elapsedSeconds = 0;
            resetStats();
        }
        
        // Reset statistics
        private function resetStats() {
            hrCount = 0;
            hrSum = 0.0;
            hrMean = 0.0;
            hrM2 = 0.0;
            
            rmssdCount = 0;
            rmssdSum = 0.0;
            rmssdMean = 0.0;
            rmssdM2 = 0.0;
        }
        
        // Update calibration with new data
        // @param hr Heart rate in bpm
        // @param rmssd RMSSD value in milliseconds
        // @return true if calibration complete
        function updateCalibration(hr, rmssd) {
            if (state != CALIBRATION_IN_PROGRESS) {
                return false;
            }
            
            // Update elapsed time
            var currentTime = Toybox.System.getTimer();
            elapsedSeconds = (currentTime - startTime) / 1000;
            
            // Check if time is up first
            if (elapsedSeconds >= CALIBRATION_DURATION) {
                // If we have enough samples, complete normally
                if (hrCount >= MIN_SAMPLES && rmssdCount >= MIN_SAMPLES) {
                    completeCalibration();
                    return true;
                }
                // If we have HR but limited RMSSD, use HR-only baseline
                if (hrCount >= MIN_SAMPLES && rmssdCount >= MIN_SAMPLES_FALLBACK) {
                    completeCalibration();
                    return true;
                }
                // If time is up and we have SOME data, use it
                // This handles devices with limited HRV support
                if (hrCount >= MIN_SAMPLES_FALLBACK) {
                    completeCalibration();
                    return true;
                }
                // Time is up but not enough samples - keep waiting
                elapsedSeconds = CALIBRATION_DURATION;
            }
            
            // Add HR data using Welford's algorithm
            if (hr != null && hr > 0) {
                hrCount++;
                var delta = hr - hrMean;
                hrMean += delta / hrCount;
                var delta2 = hr - hrMean;
                hrM2 += delta * delta2;
                hrSum += hr;
            }
            
            // Add RMSSD data using Welford's algorithm
            if (rmssd != null && rmssd > 0) {
                rmssdCount++;
                var delta = rmssd - rmssdMean;
                rmssdMean += delta / rmssdCount;
                var delta2 = rmssd - rmssdMean;
                rmssdM2 += delta * delta2;
                rmssdSum += rmssd;
            }
            
            // Check if calibration is complete
            if (elapsedSeconds >= CALIBRATION_DURATION && 
                hrCount >= MIN_SAMPLES && 
                rmssdCount >= MIN_SAMPLES) {
                completeCalibration();
                return true;
            }
            
            return false;
        }
        
        // Complete calibration and save baseline
        private function completeCalibration() {
            // Calculate baseline HR
            if (hrCount > 0) {
                baselineHR = hrMean;
                baselineHRStdDev = Math.sqrt(hrM2 / hrCount);
            } else {
                // Fallback defaults if no HR data
                baselineHR = 70.0;
                baselineHRStdDev = 10.0;
            }
            
            // Calculate baseline RMSSD
            if (rmssdCount > 0) {
                baselineRMSSD = rmssdMean;
                baselineRMSSDStdDev = Math.sqrt(rmssdM2 / rmssdCount);
            } else {
                // Fallback: estimate from HR (rough approximation)
                // Typical RMSSD at rest is ~30-50ms
                baselineRMSSD = 40.0;
                baselineRMSSDStdDev = 15.0;
            }
            
            // Save to storage
            saveBaseline();
            
            state = CALIBRATION_COMPLETED;
        }
        
        // Save baseline to persistent storage
        private function saveBaseline() {
            Storage.setValue(KEY_BASELINE_HR, baselineHR);
            Storage.setValue(KEY_BASELINE_HR_SD, baselineHRStdDev);
            Storage.setValue(KEY_BASELINE_RMSSD, baselineRMSSD);
            Storage.setValue(KEY_BASELINE_RMSSD_SD, baselineRMSSDStdDev);
            Storage.setValue(KEY_CALIBRATION_TIME, Toybox.Time.now().value());
        }
        
        // Load baseline from persistent storage
        private function loadBaseline() {
            baselineHR = Storage.getValue(KEY_BASELINE_HR);
            baselineHRStdDev = Storage.getValue(KEY_BASELINE_HR_SD);
            baselineRMSSD = Storage.getValue(KEY_BASELINE_RMSSD);
            baselineRMSSDStdDev = Storage.getValue(KEY_BASELINE_RMSSD_SD);
            
            if (baselineHR != null && baselineRMSSD != null) {
                state = CALIBRATION_COMPLETED;
            }
        }
        
        // Get calibration state
        function getState() {
            return state;
        }
        
        // Get calibration progress (0.0 to 1.0)
        function getProgress() {
            if (state != CALIBRATION_IN_PROGRESS) {
                return 0.0;
            }
            return elapsedSeconds.toFloat() / CALIBRATION_DURATION;
        }
        
        // Get remaining seconds
        function getRemainingSeconds() {
            if (state != CALIBRATION_IN_PROGRESS) {
                return 0;
            }
            var remaining = CALIBRATION_DURATION - elapsedSeconds;
            return remaining > 0 ? remaining : 0;
        }
        
        // Get sample counts for debugging
        function getHRSampleCount() {
            return hrCount;
        }
        
        function getRMSSDSampleCount() {
            return rmssdCount;
        }
        
        // Check if baseline is available
        function hasBaseline() {
            return baselineHR != null && baselineRMSSD != null;
        }
        
        // Get baseline HR
        function getBaselineHR() {
            return baselineHR;
        }
        
        // Get baseline HR standard deviation
        function getBaselineHRStdDev() {
            return baselineHRStdDev;
        }
        
        // Get baseline RMSSD
        function getBaselineRMSSD() {
            return baselineRMSSD;
        }
        
        // Get baseline RMSSD standard deviation
        function getBaselineRMSSDStdDev() {
            return baselineRMSSDStdDev;
        }
        
        // Clear baseline and restart calibration
        function resetBaseline() {
            baselineHR = null;
            baselineHRStdDev = null;
            baselineRMSSD = null;
            baselineRMSSDStdDev = null;
            
            Storage.deleteValue(KEY_BASELINE_HR);
            Storage.deleteValue(KEY_BASELINE_HR_SD);
            Storage.deleteValue(KEY_BASELINE_RMSSD);
            Storage.deleteValue(KEY_BASELINE_RMSSD_SD);
            Storage.deleteValue(KEY_CALIBRATION_TIME);
            
            state = CALIBRATION_NOT_STARTED;
        }
    }
}
