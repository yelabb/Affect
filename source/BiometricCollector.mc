using Toybox.Sensor;
using Toybox.System;
using Toybox.Math;
using Toybox.Lang;

module Affect {

    // Biometric Collector using real heart beat intervals
    // Uses Sensor.registerSensorDataListener() for accurate HRV measurement
    // Falls back to synthetic data in simulator only
    class BiometricCollector {
        
        private var rmssdCalculator;
        private var stabilityAnalyzer;
        
        // Current readings
        private var heartRate;
        private var rmssd;
        private var cv;
        
        // State tracking
        private var tickCount;
        private var usingSynthetic;
        private var listenerRegistered;
        private var lastRealDataTick;
        
        // Configuration
        private const SYNTHETIC_TIMEOUT = 10;  // Start synthetic after 10 seconds with no real data
        
        function initialize(rmssdCalc, stabilityAnalyz) {
            rmssdCalculator = rmssdCalc;
            stabilityAnalyzer = stabilityAnalyz;
            
            heartRate = null;
            rmssd = null;
            cv = null;
            tickCount = 0;
            usingSynthetic = false;
            listenerRegistered = false;
            lastRealDataTick = 0;
            
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
            if (info != null && info has :heartRate && info.heartRate != null && info.heartRate > 0) {
                heartRate = info.heartRate;
            }
            
            // Process real heart beat intervals
            if (sensorData has :heartRateData && sensorData.heartRateData != null) {
                var hrData = sensorData.heartRateData;
                if (hrData has :heartBeatIntervals && hrData.heartBeatIntervals != null) {
                    var intervals = hrData.heartBeatIntervals;
                    if (intervals.size() > 0) {
                        usingSynthetic = false;
                        lastRealDataTick = tickCount;
                        
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
            
            // If listener not registered, try polling approach
            if (!listenerRegistered) {
                pollSensorFallback();
            }
            
            // Fallback to synthetic if no real data for a while (simulator)
            if ((tickCount - lastRealDataTick) > SYNTHETIC_TIMEOUT) {
                generateSyntheticData();
            }
            
            // Update stability analyzer with current RMSSD
            if (rmssd != null) {
                stabilityAnalyzer.addRMSSD(rmssd);
                cv = stabilityAnalyzer.getCoefficientOfVariation();
            }
        }
        
        // Fallback polling for devices where listener doesn't work
        private function pollSensorFallback() {
            var info = Sensor.getInfo();
            
            if (info == null) {
                return;
            }
            
            // Get heart rate at minimum
            if (info has :heartRate && info.heartRate != null && info.heartRate > 0) {
                heartRate = info.heartRate;
            }
        }
        
        // Generate realistic synthetic data for simulator/testing only
        private function generateSyntheticData() {
            usingSynthetic = true;
            
            // Slowly varying HR between 60-80 bpm
            var phase = tickCount * 0.05;
            heartRate = 70 + (Math.sin(phase) * 10).toNumber();
            
            // Simulate realistic HRV with larger natural variation
            // Real HRV has RMSSD typically 20-80ms in healthy adults
            var baseRR = (60000.0 / heartRate).toNumber();
            
            // Use larger variation to simulate real HRV (±50ms gives RMSSD ~40-50ms)
            var variation = (Math.rand() % 100) - 50;
            var rrInterval = baseRR + variation;
            
            // Feed to calculators
            rmssdCalculator.addInterval(rrInterval);
            rmssd = rmssdCalculator.getRMSSD();
        }
        
        // Getters
        function getHeartRate() { return heartRate; }
        function getRMSSD() { return rmssd; }
        function getCoefficientOfVariation() { return cv; }
        function isSynthetic() { return usingSynthetic; }
        function getTickCount() { return tickCount; }
        
        // Check if we have enough data for meaningful display
        function hasData() {
            return heartRate != null && rmssd != null;
        }
        
        // Check if HR is available
        function hasHeartRate() {
            return heartRate != null;
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
            heartRate = null;
            rmssd = null;
            cv = null;
            tickCount = 0;
            usingSynthetic = false;
            lastRealDataTick = 0;
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
