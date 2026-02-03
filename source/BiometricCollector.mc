using Toybox.Sensor;
using Toybox.System;
using Toybox.Math;
using Toybox.Lang;

module Affect {

    // Biometric Collector using real heart beat intervals
    // Uses Sensor.registerSensorDataListener() for accurate HRV measurement
    // NO synthetic data on real devices - only shows real measurements
    class BiometricCollector {
        
        private var rmssdCalculator;
        private var stabilityAnalyzer;
        
        // Current readings
        private var currentHR;
        private var rmssd;
        private var cv;
        
        // State tracking
        private var tickCount;
        private var listenerRegistered;
        private var hasReceivedRealData;
        
        function initialize(rmssdCalc, stabilityAnalyz) {
            rmssdCalculator = rmssdCalc;
            stabilityAnalyzer = stabilityAnalyz;
            
            currentHR = null;
            rmssd = null;
            cv = null;
            tickCount = 0;
            listenerRegistered = false;
            hasReceivedRealData = false;
            
            // Register for real heart beat interval data
            registerHeartBeatListener();
        }
        
        // Register sensor data listener for real RR intervals
        private function registerHeartBeatListener() {
            try {
                // Enable heart rate sensor first
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
                
                // Register for heart beat interval data (real RR intervals!)
                var options = {
                    :period => 1,  // 1 second batches
                    :heartBeatIntervals => {
                        :enabled => true
                    }
                };
                Sensor.registerSensorDataListener(method(:onSensorData) as Lang.Method, options);
                listenerRegistered = true;
            } catch (e) {
                // Sensor listener not available (older device or simulator)
                listenerRegistered = false;
            }
        }
        
        // Callback for real heart beat interval data
        // This receives actual beat-to-beat timing from the optical HR sensor
        function onSensorData(sensorData as Sensor.SensorData) {
            // Get heart rate from sensor info
            var info = Sensor.getInfo();
            if (info != null) {
                var hr = info.heartRate;
                if (hr != null && hr > 0) {
                    currentHR = hr;
                }
            }
            
            // Process real heart beat intervals
            if (sensorData has :heartRateData && sensorData.heartRateData != null) {
                var hrData = sensorData.heartRateData;
                if (hrData has :heartBeatIntervals && hrData.heartBeatIntervals != null) {
                    var intervals = hrData.heartBeatIntervals;
                    if (intervals.size() > 0) {
                        hasReceivedRealData = true;
                        
                        // Feed each real RR interval to the calculator
                        for (var i = 0; i < intervals.size(); i++) {
                            var rrInterval = intervals[i];
                            if (rrInterval != null && rrInterval > 0) {
                                rmssdCalculator.addInterval(rrInterval);
                            }
                        }
                        rmssd = rmssdCalculator.getRMSSD();
                    }
                }
            }
        }
        
        // Called every second by the view timer
        function update() {
            tickCount++;
            
            // If listener not registered, try polling for HR at minimum
            if (!listenerRegistered) {
                pollSensorFallback();
            }
            
            // Update stability analyzer with current RMSSD
            if (rmssd != null) {
                stabilityAnalyzer.addRMSSD(rmssd);
                cv = stabilityAnalyzer.getCoefficientOfVariation();
            }
        }
        
        // Fallback polling for HR only (no fake RR intervals)
        private function pollSensorFallback() {
            var info = Sensor.getInfo();
            
            if (info != null) {
                // Get heart rate only - we won't fake RR intervals
                var hr = info.heartRate;
                if (hr != null && hr > 0) {
                    currentHR = hr;
                }
            }
        }
        
        // Getters
        function getHeartRate() { return currentHR; }
        function getRMSSD() { return rmssd; }
        function getCoefficientOfVariation() { return cv; }
        function getTickCount() { return tickCount; }
        
        // Check if we have enough data for meaningful display
        function hasData() {
            return currentHR != null && rmssd != null;
        }
        
        // Check if HR is available
        function hasHeartRate() {
            return currentHR != null;
        }
        
        // Check if we're receiving real HRV data
        function hasRealHRVData() {
            return hasReceivedRealData && rmssd != null;
        }
        
        // Check if HRV is unavailable (for showing appropriate message)
        function isHRVUnavailable() {
            // After 15 seconds with no real RR data, HRV is unavailable
            return tickCount > 15 && !hasReceivedRealData;
        }
        
        // Get RMSSD readiness as percentage (0-100)
        function getReadinessPercent() {
            var intervalCount = rmssdCalculator.getIntervalCount();
            var minNeeded = 10;
            if (intervalCount >= minNeeded) {
                return 100;
            }
            return (intervalCount * 100) / minNeeded;
        }
        
        // Reset state
        function reset() {
            currentHR = null;
            rmssd = null;
            cv = null;
            tickCount = 0;
            hasReceivedRealData = false;
            rmssdCalculator.reset();
            stabilityAnalyzer.reset();
        }
        
        // Clean up sensor listener
        function cleanup() {
            if (listenerRegistered) {
                try {
                    Sensor.unregisterSensorDataListener();
                } catch (e) {
                    // Ignore cleanup errors
                }
                listenerRegistered = false;
            }
        }
    }
}
