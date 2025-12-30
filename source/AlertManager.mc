using Toybox.Attention;
using Toybox.System;
using Toybox.Math;

module Affect {

    // Early Warning Alert System for Alexithymia Support
    // Detects trajectory toward extreme states and provides haptic nudges
    // before the user reaches overwhelming intensity
    class AlertManager {
        
        // Alert thresholds
        private const APPROACHING_THRESHOLD = 0.55;  // Start watching
        private const WARNING_THRESHOLD = 0.70;      // Gentle nudge
        private const URGENT_THRESHOLD = 0.85;       // Strong alert
        
        // Cooldown periods (in ticks, ~1 tick per second)
        private const ALERT_COOLDOWN = 300;          // 5 minutes between alerts
        private const RECOVERY_COOLDOWN = 180;       // 3 minutes before recovery feedback
        
        // Trend detection
        private const TREND_WINDOW = 10;             // Samples for trend calculation
        private const RISING_TREND_THRESHOLD = 0.02; // Intensity increase per sample
        
        // State tracking
        private var intensityHistory;
        private var historyIndex;
        private var historyFull;
        
        private var lastAlertTick;
        private var lastRecoveryTick;
        private var tickCount;
        
        private var wasInExtreme;
        private var alertLevel;  // 0=none, 1=approaching, 2=warning, 3=urgent
        
        // Startup grace period (don't vibrate on app open)
        private const STARTUP_GRACE_PERIOD = 30;  // 30 ticks (~30 seconds)
        
        // Vibration patterns
        private var vibeShort;
        private var vibeDouble;
        private var vibeRecovery;
        
        function initialize() {
            intensityHistory = new [TREND_WINDOW];
            historyIndex = 0;
            historyFull = false;
            
            lastAlertTick = -ALERT_COOLDOWN;  // Allow immediate first alert
            lastRecoveryTick = -RECOVERY_COOLDOWN;
            tickCount = 0;
            
            wasInExtreme = false;
            alertLevel = 0;
            
            // Define vibration patterns
            // Short single pulse - "heads up"
            vibeShort = [
                new Attention.VibeProfile(50, 200)
            ];
            
            // Double pulse - "warning"
            vibeDouble = [
                new Attention.VibeProfile(75, 150),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(75, 150)
            ];
            
            // Soft long pulse - "recovery" (positive feedback)
            vibeRecovery = [
                new Attention.VibeProfile(25, 400)
            ];
        }
        
        // Called every update cycle with current emotional state
        // Returns true if an alert was triggered
        function checkState(arousal, valence, quadrant) {
            tickCount++;
            
            if (arousal == null || valence == null) {
                return false;
            }
            
            // Calculate intensity (distance from center)
            var intensity = Math.sqrt(arousal * arousal + valence * valence);
            
            // Track history for trend detection
            addToHistory(intensity);
            
            // Determine if this is a "bad" state (stressed or depleted)
            var isNegativeState = (quadrant == QUADRANT_STRESSED || quadrant == QUADRANT_TIRED);
            
            // Check for alerts
            var alertTriggered = false;
            
            if (isNegativeState) {
                alertTriggered = checkForAlert(intensity);
            }
            
            // Check for recovery feedback
            if (!alertTriggered && wasInExtreme && !isNegativeState) {
                checkForRecovery(intensity);
            }
            
            // Track if we're in extreme state
            wasInExtreme = (intensity > WARNING_THRESHOLD && isNegativeState);
            
            return alertTriggered;
        }
        
        // Add intensity to history buffer
        private function addToHistory(intensity) {
            intensityHistory[historyIndex] = intensity;
            historyIndex = (historyIndex + 1) % TREND_WINDOW;
            if (historyIndex == 0) {
                historyFull = true;
            }
        }
        
        // Calculate trend (positive = rising, negative = falling)
        private function calculateTrend() {
            if (!historyFull) {
                return 0.0;
            }
            
            // Simple linear regression slope
            var sumX = 0.0;
            var sumY = 0.0;
            var sumXY = 0.0;
            var sumX2 = 0.0;
            var n = TREND_WINDOW;
            
            for (var i = 0; i < n; i++) {
                var idx = (historyIndex + i) % n;
                var x = i.toFloat();
                var y = intensityHistory[idx];
                if (y == null) { return 0.0; }
                
                sumX += x;
                sumY += y;
                sumXY += x * y;
                sumX2 += x * x;
            }
            
            var denominator = (n * sumX2 - sumX * sumX);
            if (denominator == 0) { return 0.0; }
            
            var slope = (n * sumXY - sumX * sumY) / denominator;
            return slope;
        }
        
        // Check if we should trigger an alert
        private function checkForAlert(intensity) {
            // Respect startup grace period (no vibration on app open)
            if (tickCount < STARTUP_GRACE_PERIOD) {
                return false;
            }
            
            // Respect cooldown
            if (tickCount - lastAlertTick < ALERT_COOLDOWN) {
                return false;
            }
            
            var trend = calculateTrend();
            var isRising = (trend > RISING_TREND_THRESHOLD);
            
            // Urgent: already in extreme zone
            if (intensity > URGENT_THRESHOLD) {
                triggerUrgentAlert();
                return true;
            }
            
            // Warning: approaching extreme and rising
            if (intensity > WARNING_THRESHOLD && isRising) {
                triggerWarningAlert();
                return true;
            }
            
            // Approaching: early heads-up if clearly trending toward trouble
            if (intensity > APPROACHING_THRESHOLD && isRising && alertLevel == 0) {
                triggerApproachingAlert();
                return true;
            }
            
            return false;
        }
        
        // Check if user has recovered (for positive feedback)
        private function checkForRecovery(intensity) {
            if (tickCount - lastRecoveryTick < RECOVERY_COOLDOWN) {
                return;
            }
            
            // Recovered: intensity dropped below approaching threshold
            if (intensity < APPROACHING_THRESHOLD) {
                triggerRecoveryFeedback();
            }
        }
        
        // Trigger approaching alert (subtle)
        private function triggerApproachingAlert() {
            try {
                if (Attention has :vibrate) {
                    Attention.vibrate(vibeShort);
                }
            } catch (e) {
                // Vibration not supported
            }
            alertLevel = 1;
            lastAlertTick = tickCount;
        }
        
        // Trigger warning alert (moderate)
        private function triggerWarningAlert() {
            try {
                if (Attention has :vibrate) {
                    Attention.vibrate(vibeDouble);
                }
            } catch (e) {
                // Vibration not supported
            }
            alertLevel = 2;
            lastAlertTick = tickCount;
        }
        
        // Trigger urgent alert (strong)
        private function triggerUrgentAlert() {
            try {
                if (Attention has :vibrate) {
                    // Triple pulse for urgent
                    var vibeUrgent = [
                        new Attention.VibeProfile(100, 200),
                        new Attention.VibeProfile(0, 100),
                        new Attention.VibeProfile(100, 200),
                        new Attention.VibeProfile(0, 100),
                        new Attention.VibeProfile(100, 200)
                    ];
                    Attention.vibrate(vibeUrgent);
                }
            } catch (e) {
                // Vibration not supported
            }
            alertLevel = 3;
            lastAlertTick = tickCount;
        }
        
        // Trigger recovery feedback (gentle positive reinforcement)
        private function triggerRecoveryFeedback() {
            try {
                if (Attention has :vibrate) {
                    Attention.vibrate(vibeRecovery);
                }
            } catch (e) {
                // Vibration not supported
            }
            alertLevel = 0;
            wasInExtreme = false;
            lastRecoveryTick = tickCount;
        }
        
        // Get current alert level for UI indication
        function getAlertLevel() {
            return alertLevel;
        }
        
        // Reset alert state
        function reset() {
            for (var i = 0; i < TREND_WINDOW; i++) {
                intensityHistory[i] = null;
            }
            historyIndex = 0;
            historyFull = false;
            alertLevel = 0;
            wasInExtreme = false;
        }
    }
}
