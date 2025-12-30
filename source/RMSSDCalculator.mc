using Toybox.Math;

module Affect {

    // Memory-efficient RMSSD calculator using fixed-size circular buffer
    // Maintains constant memory footprint regardless of session length
    class RMSSDCalculator {
        
        // Circular buffer for RR intervals (milliseconds)
        // Size: 90 intervals (~60-90s of data at 60-90 bpm)
        private const BUFFER_SIZE = 90;
        private var rrIntervals;
        private var bufferIndex;
        private var bufferFull;
        
        // Running RMSSD value (milliseconds)
        private var currentRMSSD;
        
        // Minimum intervals needed for valid RMSSD
        private const MIN_INTERVALS = 10;
        
        function initialize() {
            rrIntervals = new [BUFFER_SIZE];
            bufferIndex = 0;
            bufferFull = false;
            currentRMSSD = null;
        }
        
        // Add new RR interval and recalculate RMSSD incrementally
        // @param rrInterval RR interval in milliseconds
        function addInterval(rrInterval) {
            if (rrInterval == null || rrInterval <= 0) {
                return;
            }
            
            // Add to circular buffer
            rrIntervals[bufferIndex] = rrInterval;
            bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
            
            if (bufferIndex == 0) {
                bufferFull = true;
            }
            
            // Recalculate RMSSD using available data
            calculateRMSSD();
        }
        
        // Calculate RMSSD from current buffer
        // RMSSD = sqrt(mean(successive_differences^2))
        private function calculateRMSSD() {
            var count = bufferFull ? BUFFER_SIZE : bufferIndex;
            
            if (count < MIN_INTERVALS) {
                currentRMSSD = null;
                return;
            }
            
            // Calculate sum of squared successive differences
            var sumSquaredDiffs = 0.0;
            var validDiffs = 0;
            
            for (var i = 1; i < count; i++) {
                var prevIndex = (bufferIndex - count + i - 1 + BUFFER_SIZE) % BUFFER_SIZE;
                var currIndex = (bufferIndex - count + i + BUFFER_SIZE) % BUFFER_SIZE;
                
                var prev = rrIntervals[prevIndex];
                var curr = rrIntervals[currIndex];
                
                if (prev != null && curr != null) {
                    var diff = curr - prev;
                    sumSquaredDiffs += diff * diff;
                    validDiffs++;
                }
            }
            
            if (validDiffs > 0) {
                var meanSquaredDiff = sumSquaredDiffs / validDiffs;
                currentRMSSD = Math.sqrt(meanSquaredDiff);
            } else {
                currentRMSSD = null;
            }
        }
        
        // Get current RMSSD value
        // @return RMSSD in milliseconds, or null if insufficient data
        function getRMSSD() {
            return currentRMSSD;
        }
        
        // Check if we have enough data for valid RMSSD
        function hasValidData() {
            return currentRMSSD != null;
        }
        
        // Get number of intervals in buffer
        function getIntervalCount() {
            return bufferFull ? BUFFER_SIZE : bufferIndex;
        }
        
        // Reset calculator (for calibration restart)
        function reset() {
            for (var i = 0; i < BUFFER_SIZE; i++) {
                rrIntervals[i] = null;
            }
            bufferIndex = 0;
            bufferFull = false;
            currentRMSSD = null;
        }
    }
}
