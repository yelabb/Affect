using Toybox.Math;

module Affect {

    // HRV Stability Analyzer using Welford's online algorithm for variance
    // Tracks variance of RMSSD values over 60s window for valence estimation
    // Memory-efficient: stores only 60 RMSSD values in circular buffer
    class HRVStabilityAnalyzer {
        
        // Circular buffer for RMSSD values (one per second)
        private const WINDOW_SIZE = 60; // 60 seconds
        private var rmssdBuffer;
        private var bufferIndex;
        private var bufferFull;
        
        // Welford's algorithm state variables
        private var count;
        private var mean;
        private var m2; // Sum of squared differences from mean
        
        // Current stability metrics
        private var variance;
        private var stdDev;
        private var coefficientOfVariation; // CV = stdDev / mean
        
        private const MIN_SAMPLES = 30; // Need 30s of data minimum
        
        function initialize() {
            rmssdBuffer = new [WINDOW_SIZE];
            bufferIndex = 0;
            bufferFull = false;
            
            count = 0;
            mean = 0.0;
            m2 = 0.0;
            
            variance = null;
            stdDev = null;
            coefficientOfVariation = null;
        }
        
        // Add new RMSSD value and update stability metrics
        // @param rmssd RMSSD value in milliseconds
        function addRMSSD(rmssd) {
            if (rmssd == null || rmssd <= 0) {
                return;
            }
            
            // If buffer is full, we need to remove the oldest value first
            var oldValue = null;
            if (bufferFull) {
                oldValue = rmssdBuffer[bufferIndex];
            }
            
            // Add new value to buffer
            rmssdBuffer[bufferIndex] = rmssd;
            bufferIndex = (bufferIndex + 1) % WINDOW_SIZE;
            
            if (bufferIndex == 0) {
                bufferFull = true;
            }
            
            // Update Welford's algorithm
            if (oldValue != null) {
                // Remove old value from running statistics
                removeValue(oldValue);
            }
            
            // Add new value to running statistics
            addValue(rmssd);
            
            // Calculate stability metrics
            calculateStability();
        }
        
        // Add value using Welford's online algorithm
        private function addValue(value) {
            count++;
            var delta = value - mean;
            mean += delta / count;
            var delta2 = value - mean;
            m2 += delta * delta2;
        }
        
        // Remove value from running statistics (for sliding window)
        private function removeValue(value) {
            if (count <= 1) {
                count = 0;
                mean = 0.0;
                m2 = 0.0;
                return;
            }
            
            var delta = value - mean;
            mean = (mean * count - value) / (count - 1);
            var delta2 = value - mean;
            m2 -= delta * delta2;
            count--;
            
            // Prevent negative m2 due to floating point errors
            if (m2 < 0) {
                m2 = 0.0;
            }
        }
        
        // Calculate stability metrics from current state
        private function calculateStability() {
            if (count < MIN_SAMPLES) {
                variance = null;
                stdDev = null;
                coefficientOfVariation = null;
                return;
            }
            
            // Calculate variance
            variance = m2 / count;
            
            // Calculate standard deviation
            stdDev = Math.sqrt(variance);
            
            // Calculate coefficient of variation (CV)
            // CV = stdDev / mean, expressed as ratio
            // High CV = erratic HRV = negative valence
            // Low CV = stable HRV = positive valence
            if (mean > 0.1) { // Avoid division by near-zero
                coefficientOfVariation = stdDev / mean;
            } else {
                coefficientOfVariation = null;
            }
        }
        
        // Get coefficient of variation for valence calculation
        // @return CV value, or null if insufficient data
        function getCoefficientOfVariation() {
            return coefficientOfVariation;
        }
        
        // Get standard deviation
        function getStdDev() {
            return stdDev;
        }
        
        // Get variance
        function getVariance() {
            return variance;
        }
        
        // Get mean RMSSD over window
        function getMean() {
            return count >= MIN_SAMPLES ? mean : null;
        }
        
        // Check if we have enough data for valid stability metrics
        function hasValidData() {
            return coefficientOfVariation != null;
        }
        
        // Get sample count
        function getSampleCount() {
            return count;
        }
        
        // Reset analyzer
        function reset() {
            for (var i = 0; i < WINDOW_SIZE; i++) {
                rmssdBuffer[i] = null;
            }
            bufferIndex = 0;
            bufferFull = false;
            
            count = 0;
            mean = 0.0;
            m2 = 0.0;
            
            variance = null;
            stdDev = null;
            coefficientOfVariation = null;
        }
    }
}
