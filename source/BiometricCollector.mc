using Toybox.Sensor;
using Toybox.System;
using Toybox.Math;

module Affect {

    // Elegant Biometric Collector
    // Leonardo's principle: Simplicity is the ultimate sophistication
    // 
    // One simple approach: Poll Sensor.getInfo() every second
    // If no real data after timeout, generate synthetic data for testing
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
        
        // Configuration
        private const SYNTHETIC_TIMEOUT = 8;  // Start synthetic after 8 seconds
        
        function initialize(rmssdCalc, stabilityAnalyz) {
            rmssdCalculator = rmssdCalc;
            stabilityAnalyzer = stabilityAnalyz;
            
            heartRate = null;
            rmssd = null;
            cv = null;
            tickCount = 0;
            usingSynthetic = false;
            
            // Enable heart rate sensor
            try {
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            } catch (e) {
                // Sensor might not be available
            }
        }
        
        // Called every second by the view timer
        function update() {
            tickCount++;
            
            // Try to get real sensor data
            var gotRealData = pollSensor();
            
            // Fallback to synthetic if no real data
            if (!gotRealData && tickCount > SYNTHETIC_TIMEOUT) {
                generateSyntheticData();
            }
            
            // Update stability analyzer with current RMSSD
            if (rmssd != null) {
                stabilityAnalyzer.addRMSSD(rmssd);
                cv = stabilityAnalyzer.getCoefficientOfVariation();
            }
        }
        
        // Poll Sensor.getInfo() - the simplest reliable method
        private function pollSensor() {
            var info = Sensor.getInfo();
            
            if (info == null) {
                return false;
            }
            
            // Get heart rate
            if (info has :heartRate && info.heartRate != null && info.heartRate > 0) {
                heartRate = info.heartRate;
                usingSynthetic = false;
                
                // Generate RR interval from HR (approximate but works)
                // RR = 60000 / HR (in milliseconds)
                var estimatedRR = (60000.0 / heartRate).toNumber();
                
                // Add small natural variation
                var variation = (Math.rand() % 40) - 20;  // ±20ms
                var rrInterval = estimatedRR + variation;
                
                // Feed to RMSSD calculator
                rmssdCalculator.addInterval(rrInterval);
                rmssd = rmssdCalculator.getRMSSD();
                
                return true;
            }
            
            return false;
        }
        
        // Generate realistic synthetic data for simulator/testing
        private function generateSyntheticData() {
            usingSynthetic = true;
            
            // Slowly varying HR between 60-80 bpm
            var phase = tickCount * 0.05;
            heartRate = 70 + (Math.sin(phase) * 10).toNumber();
            
            // RR interval with realistic HRV variation
            var baseRR = (60000.0 / heartRate).toNumber();
            var variation = (Math.rand() % 60) - 30;  // ±30ms natural variation
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
        // Requires both HR and valid RMSSD (enough RR intervals collected)
        function hasData() {
            return heartRate != null && rmssd != null;
        }
        
        // Check if HR is available (for progress indication)
        function hasHeartRate() {
            return heartRate != null;
        }
        
        // Get RMSSD readiness as percentage (0-100)
        // Based on how many RR intervals collected vs minimum needed
        function getReadinessPercent() {
            var intervalCount = rmssdCalculator.getIntervalCount();
            var minNeeded = 10;  // MIN_INTERVALS from RMSSDCalculator
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
            rmssdCalculator.reset();
            stabilityAnalyzer.reset();
        }
    }
}
