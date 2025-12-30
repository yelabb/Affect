using Toybox.Math;

module Affect {

    // Emotional quadrants constants
    // Reframed as Threat-Challenge / Tension-Engagement model
    const QUADRANT_EXCITED = 0;  // High arousal, positive valence (engaged/challenged)
    const QUADRANT_STRESSED = 1; // High arousal, negative valence (tense/threatened)
    const QUADRANT_CALM = 2;     // Low arousal, positive valence (restful/recovered)
    const QUADRANT_TIRED = 3;    // Low arousal, negative valence (depleted/fatigued)

    // Circumplex Mapper - Maps physiological data to Russell's Circumplex Model
    // f(HRV_RMSSD, HR) -> (Arousal, Valence)
    // 
    // Valence approach: "RMSSD preservation under arousal"
    // - Stress: HR high + RMSSD suppressed (PNS withdrawal)
    // - Excitement: HR high + RMSSD preserved (PNS maintained)
    // This separates threat response from challenge/engagement
    class CircumplexMapper {
        
        // Population average baselines (no calibration needed)
        private const BASELINE_HR = 70.0;
        private const BASELINE_HR_SD = 12.0;
        private const BASELINE_RMSSD = 40.0;
        private const BASELINE_RMSSD_SD = 20.0;
        
        // Arousal calculation weights
        private const AROUSAL_HR_WEIGHT = 0.6;
        private const AROUSAL_RMSSD_WEIGHT = 0.4;
        
        // Valence calculation parameters
        // Valence = Z_RMSSD - TENSION_PENALTY * max(0, Z_HR)
        // When HR is elevated, RMSSD must be preserved for positive valence
        private const TENSION_PENALTY = 0.5;  // How much HR elevation penalizes valence
        
        // Arousal gating: at low arousal, valence behavior differs
        private const AROUSAL_LOW_GATE = 0.15;  // Below this, use pure RMSSD for valence
        private const AROUSAL_HIGH_GATE = 0.4;  // Above this, full tension-challenge logic
        
        function initialize() {
        }
        
        // Calculate arousal from HR and RMSSD
        // Low RMSSD + High HR = High Arousal
        // High RMSSD + Low HR = Low Arousal
        // @param hr Current heart rate (bpm)
        // @param rmssd Current RMSSD (ms)
        // @return Arousal value from -1.0 (low) to +1.0 (high), or null
        function calculateArousal(hr, rmssd) {
            if (hr == null || rmssd == null) {
                return null;
            }
            
            // Normalize HR (z-score)
            // Higher HR relative to baseline = higher arousal
            var hrZScore = (hr - BASELINE_HR) / BASELINE_HR_SD;
            
            // Normalize RMSSD (z-score, inverted)
            // Lower RMSSD relative to baseline = higher arousal
            var rmssdZScore = -(rmssd - BASELINE_RMSSD) / BASELINE_RMSSD_SD;
            
            // Weighted combination
            var arousal = (AROUSAL_HR_WEIGHT * hrZScore) + 
                         (AROUSAL_RMSSD_WEIGHT * rmssdZScore);
            
            // Clamp to [-1, 1]
            arousal = clamp(arousal / 3.0, -1.0, 1.0);
            
            return arousal;
        }
        
        // Calculate valence from RMSSD preservation under arousal
        // Stress vs Excitement separation:
        // - Excitement/Challenge: HR elevated but RMSSD preserved (PNS maintained)
        // - Stress/Threat: HR elevated and RMSSD suppressed (PNS withdrawn)
        // 
        // @param hr Current heart rate (bpm)
        // @param rmssd Current RMSSD (ms)
        // @param arousal Already-calculated arousal value (used for gating)
        // @return Valence value from -1.0 (stressed/threatened) to +1.0 (engaged/positive)
        function calculateValence(hr, rmssd, arousal) {
            if (hr == null || rmssd == null) {
                return null;
            }
            
            // Normalize RMSSD (z-score)
            // Higher RMSSD = more positive (parasympathetic tone preserved)
            var rmssdZScore = (rmssd - BASELINE_RMSSD) / BASELINE_RMSSD_SD;
            
            // Normalize HR (z-score)
            var hrZScore = (hr - BASELINE_HR) / BASELINE_HR_SD;
            
            var valence;
            
            // Calculate arousal magnitude for gating (use absolute if provided, else estimate)
            var arousalMag = (arousal != null) ? 
                ((arousal < 0) ? -arousal : arousal) : 0.0;
            
            if (arousalMag < AROUSAL_LOW_GATE) {
                // Low arousal: valence reflects recovery/restoration state
                // High RMSSD = calm/positive, Low RMSSD = tired/depleted
                valence = rmssdZScore / 2.0;
            } else if (arousalMag >= AROUSAL_HIGH_GATE) {
                // High arousal: valence reflects threat vs challenge
                // Excitement: HR up but RMSSD preserved (positive)
                // Stress: HR up and RMSSD down (negative)
                var hrPenalty = (hrZScore > 0) ? (TENSION_PENALTY * hrZScore) : 0.0;
                valence = (rmssdZScore - hrPenalty) / 2.0;
            } else {
                // Transition zone: blend between low and high arousal behaviors
                var blend = (arousalMag - AROUSAL_LOW_GATE) / (AROUSAL_HIGH_GATE - AROUSAL_LOW_GATE);
                
                // Low arousal valence (pure RMSSD)
                var lowArousalValence = rmssdZScore / 2.0;
                
                // High arousal valence (tension-challenge)
                var hrPenalty = (hrZScore > 0) ? (TENSION_PENALTY * hrZScore) : 0.0;
                var highArousalValence = (rmssdZScore - hrPenalty) / 2.0;
                
                valence = lowArousalValence * (1.0 - blend) + highArousalValence * blend;
            }
            
            // Clamp to [-1, 1]
            valence = clamp(valence, -1.0, 1.0);
            
            return valence;
        }
        
        // Get emotional state coordinates
        // @param hr Current HR
        // @param rmssd Current RMSSD
        // @param cv Coefficient of variation (optional, kept for API compat but not used for valence)
        // @return Dictionary with arousal, valence, quadrant
        function getEmotionalState(hr, rmssd, cv) {
            var arousal = calculateArousal(hr, rmssd);
            var valence = calculateValence(hr, rmssd, arousal);
            
            if (arousal == null || valence == null) {
                return null;
            }
            
            var quadrant = classifyQuadrant(arousal, valence);
            
            return {
                "arousal" => arousal,
                "valence" => valence,
                "quadrant" => quadrant
            };
        }
        
        // Classify emotional quadrant based on arousal/valence
        // Reframed as tension-engagement / threat-challenge model
        private function classifyQuadrant(arousal, valence) {
            if (arousal >= 0 && valence >= 0) {
                return QUADRANT_EXCITED;   // Engaged/Challenged
            } else if (arousal >= 0 && valence < 0) {
                return QUADRANT_STRESSED;  // Tense/Threatened
            } else if (arousal < 0 && valence >= 0) {
                return QUADRANT_CALM;      // Restful/Recovered
            } else {
                return QUADRANT_TIRED;     // Depleted/Fatigued
            }
        }
        
        // Get quadrant name as string
        function getQuadrantName(quadrant) {
            switch (quadrant) {
                case QUADRANT_EXCITED:
                    return "Engaged";
                case QUADRANT_STRESSED:
                    return "Stressed";
                case QUADRANT_CALM:
                    return "Calm";
                case QUADRANT_TIRED:
                    return "Tired";
                default:
                    return "Unknown";
            }
        }
        
        // Utility: clamp value to range
        private function clamp(value, minVal, maxVal) {
            if (value < minVal) {
                return minVal;
            } else if (value > maxVal) {
                return maxVal;
            }
            return value;
        }
    }
}
