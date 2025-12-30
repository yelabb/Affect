using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Math;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Time.Gregorian;

module Affect {

    // Cinematic Affect View - Emotion-first, artistic UI
    // Designed for alexithymia support with early warning system
    class AffectView extends WatchUi.View {
        
        // Components
        private var rmssdCalculator;
        private var stabilityAnalyzer;
        private var biometricCollector;
        private var circumplexMapper;
        private var alertManager;
        
        // Display state
        private var emotionalState;
        private var smoothedArousal;
        private var smoothedValence;
        
        // Timer
        private var updateTimer;
        
        // Animation
        private var pulsePhase;
        private var breathPhase;
        
        // Procedural instability rendering
        private var noiseSeeds;  // Array of random seeds for organic jitter
        
        // View mode: 0 = emotion (main), 1 = metrics, 2 = guidance
        private var viewMode;
        
        // Guidance view state
        private var breathingPhase;  // For breathing pacer
        
        function initialize() {
            View.initialize();
            
            rmssdCalculator = new RMSSDCalculator();
            stabilityAnalyzer = new HRVStabilityAnalyzer();
            biometricCollector = new BiometricCollector(rmssdCalculator, stabilityAnalyzer);
            circumplexMapper = new CircumplexMapper();
            alertManager = new AlertManager();
            
            emotionalState = null;
            smoothedArousal = 0.0;
            smoothedValence = 0.0;
            pulsePhase = 0.0;
            breathPhase = 0.0;
            viewMode = 0;
            breathingPhase = 0.0;
            
            // Initialize noise seeds for organic jitter
            noiseSeeds = new [8];
            for (var i = 0; i < 8; i++) {
                noiseSeeds[i] = Math.rand() % 1000;
            }
        }

        function onLayout(dc) {
        }

        function onShow() {
            updateTimer = new Timer.Timer();
            updateTimer.start(method(:onTick) as Lang.Method, 50, true);  // Faster for smooth animation
        }

        function onHide() {
            if (updateTimer != null) {
                updateTimer.stop();
                updateTimer = null;
            }
        }

        function onTick() {
            pulsePhase += 0.08;
            breathPhase += 0.03;  // Slow breathing animation
            
            // Refresh noise seeds periodically for organic jitter
            if ((pulsePhase * 100).toNumber() % 30 == 0) {
                for (var i = 0; i < noiseSeeds.size(); i++) {
                    noiseSeeds[i] = (noiseSeeds[i] + Math.rand() % 100) % 1000;
                }
            }
            
            // Update guidance breathing phase
            if (viewMode == 2) {
                breathingPhase += 0.02;  // 4-second breath cycle
            }
            
            // Update biometrics less frequently
            if ((pulsePhase * 10).toNumber() % 20 == 0) {
                biometricCollector.update();
                
                var hr = biometricCollector.getHeartRate();
                var rmssd = biometricCollector.getRMSSD();
                var cv = biometricCollector.getCoefficientOfVariation();
                
                if (hr != null) {
                    emotionalState = circumplexMapper.getEmotionalState(hr, rmssd, cv);
                    
                    if (emotionalState != null) {
                        var alpha = 0.15;  // Smoother transitions
                        smoothedArousal = smoothedArousal * (1 - alpha) + emotionalState["arousal"] * alpha;
                        smoothedValence = smoothedValence * (1 - alpha) + emotionalState["valence"] * alpha;
                        
                        // Check for early warning alerts
                        alertManager.checkState(smoothedArousal, smoothedValence, emotionalState["quadrant"]);
                    }
                }
            }
            
            WatchUi.requestUpdate();
        }
        
        // Cycle through views: emotion -> metrics -> guidance -> emotion
        function toggleView() {
            viewMode = (viewMode + 1) % 3;
            WatchUi.requestUpdate();
        }
        
        function onUpdate(dc) {
            var w = dc.getWidth();
            var h = dc.getHeight();
            var cx = w / 2;
            var cy = h / 2;
            
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            if (!biometricCollector.hasData()) {
                drawWaitingScreen(dc, w, h, cx, cy);
            } else if (viewMode == 2) {
                drawGuidanceScreen(dc, w, h, cx, cy);
            } else if (viewMode == 1) {
                drawMetricsScreen(dc, w, h, cx, cy);
            } else {
                drawCinematicEmotionScreen(dc, w, h, cx, cy);
            }
        }
        
        private function drawWaitingScreen(dc, w, h, cx, cy) {
            var tick = biometricCollector.getTickCount();
            
            // Center pulsing dot
            var pulse = Math.sin(pulsePhase) * 0.15 + 1.0;
            var dotSize = (6 + Math.sin(pulsePhase * 2) * 3).toNumber();
            dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, dotSize + 3);
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, dotSize);
            
            // Title
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.25, Graphics.FONT_MEDIUM, "SENSING", Graphics.TEXT_JUSTIFY_CENTER);
            
            // Progress indicator (animated dots)
            var dotCount = (tick % 4);
            var dots = "";
            for (var i = 0; i < 3; i++) { 
                if (i < dotCount) {
                    dots = dots + "●";
                } else {
                    dots = dots + "○";
                }
                if (i < 2) { dots = dots + " "; }
            }
            dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.62, Graphics.FONT_TINY, dots, Graphics.TEXT_JUSTIFY_CENTER);
            
            // Status text with progress
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            if (!biometricCollector.hasHeartRate()) {
                dc.drawText(cx, h * 0.72, Graphics.FONT_XTINY, "acquiring signal", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                var readiness = biometricCollector.getReadinessPercent();
                if (readiness < 100) {
                    dc.drawText(cx, h * 0.72, Graphics.FONT_XTINY, "HRV " + readiness + "%", Graphics.TEXT_JUSTIFY_CENTER);
                } else {
                    dc.drawText(cx, h * 0.72, Graphics.FONT_XTINY, "ready", Graphics.TEXT_JUSTIFY_CENTER);
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // CINEMATIC EMOTION SCREEN - Full artistic expression
        // ═══════════════════════════════════════════════════════════════
        private function drawCinematicEmotionScreen(dc, w, h, cx, cy) {
            var quadrant = QUADRANT_CALM;
            if (emotionalState != null) {
                quadrant = emotionalState["quadrant"];
            }
            
            var color = getQuadrantColor(quadrant);
            var dimColor = getQuadrantDimColor(quadrant);
            
            // === EMOTION LABEL - Hero text (draw first, at top) ===
            var label = getEmotiveLabel(quadrant, smoothedArousal, smoothedValence);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.12, Graphics.FONT_MEDIUM, label, Graphics.TEXT_JUSTIFY_CENTER);
            
            // Poetic sublabel
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.26, Graphics.FONT_XTINY, getEmotiveSublabel(quadrant), Graphics.TEXT_JUSTIFY_CENTER);
            
            // === MAIN EMOTION ORB (centered lower) ===
            // Calculate instability from physiology
            var cv = biometricCollector.getCoefficientOfVariation();
            var instability = calculateInstability(quadrant, smoothedArousal, cv);
            
            var orbY = cy + (h * 0.08).toNumber();  // Shifted down to avoid text
            var baseRadius = (w * 0.22).toNumber();
            
            // Draw procedurally unstable circle
            drawInstableOrb(dc, cx, orbY, baseRadius, color, dimColor, instability);
            
            // === POSITION INDICATOR ===
            // Crosshair inside the orb
            var crossSize = baseRadius - 12;
            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(cx - crossSize, orbY, cx + crossSize, orbY);
            dc.drawLine(cx, orbY - crossSize, cx, orbY + crossSize);
            
            // Position dot - where you are in the emotional space
            var dotX = cx + (smoothedValence * crossSize * 0.85).toNumber();
            var dotY = orbY - (smoothedArousal * crossSize * 0.85).toNumber();
            
            var pulseSize = (Math.sin(pulsePhase * 2) * 2 + 8).toNumber();
            
            // Glow
            dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dotX, dotY, pulseSize + 3);
            
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dotX, dotY, pulseSize);
            
            // Bright core
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dotX, dotY, 4);
            
            // === CURRENT TIME - Bottom center ===
            drawCurrentTime(dc, cx, h);
        }
        
        // ═══════════════════════════════════════════════════════════════
        // METRICS SCREEN - Clean data view (accessed via swipe/tap)
        // ═══════════════════════════════════════════════════════════════
        private function drawMetricsScreen(dc, w, h, cx, cy) {
            var hr = biometricCollector.getHeartRate();
            var rmssd = biometricCollector.getRMSSD();
            var cv = biometricCollector.getCoefficientOfVariation();
            
            var quadrant = QUADRANT_CALM;
            if (emotionalState != null) {
                quadrant = emotionalState["quadrant"];
            }
            var color = getQuadrantColor(quadrant);
            
            // === HEART RATE - Large hero metric at top ===
            var row1Y = (h * 0.12).toNumber();
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, row1Y, Graphics.FONT_XTINY, "HEART RATE", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var hrText = hr != null ? hr.format("%d") : "--";
            dc.drawText(cx, row1Y + 18, Graphics.FONT_LARGE, hrText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // === HRV & STABILITY - Two columns ===
            var col1X = cx - (w * 0.24).toNumber();
            var col2X = cx + (w * 0.24).toNumber();
            var row2Y = (h * 0.44).toNumber();
            
            // HRV
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawText(col1X, row2Y, Graphics.FONT_XTINY, "HRV", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var hrvText = rmssd != null ? rmssd.format("%.0f") : "--";
            dc.drawText(col1X, row2Y + 18, Graphics.FONT_MEDIUM, hrvText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // STABILITY
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawText(col2X, row2Y, Graphics.FONT_XTINY, "STABILITY", Graphics.TEXT_JUSTIFY_CENTER);
            var stabilityPercent = cv != null ? ((1.0 - cv) * 100).toNumber() : 0;
            if (stabilityPercent < 0) { stabilityPercent = 0; }
            if (stabilityPercent > 100) { stabilityPercent = 100; }
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(col2X, row2Y + 18, Graphics.FONT_MEDIUM, stabilityPercent.format("%d") + "%", Graphics.TEXT_JUSTIFY_CENTER);
            
            // === AROUSAL / VALENCE - Bottom row ===
            var row3Y = (h * 0.68).toNumber();
            
            // Arousal
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawText(col1X, row3Y, Graphics.FONT_XTINY, "AROUSAL", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
            dc.drawText(col1X, row3Y + 18, Graphics.FONT_SMALL, formatValue(smoothedArousal), Graphics.TEXT_JUSTIFY_CENTER);
            
            // Valence
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawText(col2X, row3Y, Graphics.FONT_XTINY, "VALENCE", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
            dc.drawText(col2X, row3Y + 18, Graphics.FONT_SMALL, formatValue(smoothedValence), Graphics.TEXT_JUSTIFY_CENTER);
            
            // === CURRENT TIME - Bottom center ===
            drawCurrentTime(dc, cx, h);
        }
        
        private function formatValue(val) {
            if (val >= 0) {
                return "+" + val.format("%.1f");
            }
            return val.format("%.1f");
        }
        
        // Body-focused labels for alexithymia support
        // Describes physical state, not abstract emotions
        private function getEmotiveLabel(quadrant, arousal, valence) {
            var intensity = Math.sqrt(arousal * arousal + valence * valence);
            
            if (quadrant == QUADRANT_EXCITED) {
                // High arousal + preserved HRV = activated but coping
                if (intensity > 0.7) { return "HIGH ENERGY"; }
                if (intensity > 0.4) { return "ACTIVATED"; }
                return "ALERT";
            }
            if (quadrant == QUADRANT_STRESSED) {
                // High arousal + suppressed HRV = activated and tense
                if (intensity > 0.7) { return "VERY TENSE"; }
                if (intensity > 0.4) { return "TENSE"; }
                return "UNSETTLED";
            }
            if (quadrant == QUADRANT_CALM) {
                // Low arousal + preserved HRV = relaxed
                if (intensity > 0.5) { return "RELAXED"; }
                if (intensity > 0.25) { return "AT EASE"; }
                return "STILL";
            }
            // TIRED quadrant: Low arousal + suppressed HRV = depleted
            if (intensity > 0.5) { return "DEPLETED"; }
            if (intensity > 0.25) { return "LOW ENERGY"; }
            return "RESTING";
        }
        
        // Body-based explanations of what the label means
        private function getEmotiveSublabel(quadrant) {
            if (quadrant == QUADRANT_EXCITED) { 
                return "heart active, body coping"; 
            }
            if (quadrant == QUADRANT_STRESSED) { 
                return "heart active, body tight"; 
            }
            if (quadrant == QUADRANT_CALM) { 
                return "heart calm, body loose"; 
            }
            return "heart calm, body needs rest";
        }
        
        private function getQuadrantColor(quadrant) {
            if (quadrant == QUADRANT_EXCITED) { return 0xFFBB00; }  // Warm gold
            if (quadrant == QUADRANT_STRESSED) { return 0xFF6666; }    // Soft coral-red
            if (quadrant == QUADRANT_CALM) { return 0x44DDBB; }     // Tranquil teal
            return 0x7799FF;  // Soft lavender-blue (tired)
        }
        
        // Dimmed version of quadrant colors for glow effects
        private function getQuadrantDimColor(quadrant) {
            if (quadrant == QUADRANT_EXCITED) { return 0x332600; }
            if (quadrant == QUADRANT_STRESSED) { return 0x331515; }
            if (quadrant == QUADRANT_CALM) { return 0x0D3329; }
            return 0x192040;
        }
        
        // Guidance screen with calming messages
        private function drawGuidanceScreen(dc, w, h, cx, cy) {
            var quadrant = QUADRANT_CALM;
            if (emotionalState != null) {
                quadrant = emotionalState["quadrant"];
            }
            
            // Choose content based on state
            if (quadrant == QUADRANT_STRESSED) {
                drawCalmingMessage(dc, w, h, cx, cy, quadrant);
            } else if (quadrant == QUADRANT_TIRED) {
                drawRestMessage(dc, w, h, cx, cy);
            } else {
                drawPositiveMessage(dc, w, h, cx, cy, quadrant);
            }
        }
        
        // Humorous calming messages for stressed states
        private function drawCalmingMessage(dc, w, h, cx, cy, quadrant) {
            var phrases = [
                ["Plot twist:", "You survive", "100% of these."],
                ["Your brain is", "doing that thing", "again. Classic."],
                ["Reminder:", "Anxiety lies.", "You're fine."],
                ["Breathe.", "Or don't.", "You'll do it anyway."],
                ["This too shall", "become a funny", "story later."],
                ["Your heart's", "just practicing", "for a marathon."],
                ["Congrats!", "You noticed.", "That's step one."]
            ];
            
            var idx = (breathingPhase.toNumber() / 8) % phrases.size();
            var phrase = phrases[idx];
            
            // Soft background glow
            dc.setColor(0x1a0a0a, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, (w * 0.35).toNumber());
            
            // Main message - use XTINY with more spacing
            dc.setColor(0xFF9999, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 28, Graphics.FONT_XTINY, phrase[0], Graphics.TEXT_JUSTIFY_CENTER);
            
            dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 2, Graphics.FONT_XTINY, phrase[1], Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, cy + 24, Graphics.FONT_XTINY, phrase[2], Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Humorous rest messages for tired states
        private function drawRestMessage(dc, w, h, cx, cy) {
            var phrases = [
                ["Horizontal is", "a valid life", "choice today."],
                ["Achievement", "unlocked:", "Still alive."],
                ["Your battery", "is at 2%.", "This is fine."],
                ["Plot twist:", "Doing nothing", "IS something."],
                ["Today's goal:", "Exist.", "Nailed it."],
                ["You're not lazy.", "You're on", "energy-saving mode."],
                ["Even sloths", "take breaks.", "Be the sloth."]
            ];
            
            var idx = (breathingPhase.toNumber() / 8) % phrases.size();
            var phrase = phrases[idx];
            
            // Soft background glow
            dc.setColor(0x0a0a1a, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, (w * 0.35).toNumber());
            
            // Main message - use XTINY with more spacing
            dc.setColor(0x99AAFF, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 28, Graphics.FONT_XTINY, phrase[0], Graphics.TEXT_JUSTIFY_CENTER);
            
            dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 2, Graphics.FONT_XTINY, phrase[1], Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, cy + 24, Graphics.FONT_XTINY, phrase[2], Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Positive messages for calm/excited states
        private function drawPositiveMessage(dc, w, h, cx, cy, quadrant) {
            var phrases;
            var color;
            
            if (quadrant == QUADRANT_EXCITED) {
                phrases = [
                    ["Look at you,", "out here", "thriving."],
                    ["Main character", "energy", "detected."],
                    ["Your vibe is", "immaculate", "right now."]
                ];
                color = 0xFFCC66;
            } else {
                phrases = [
                    ["Peak chill", "achieved.", "Well done."],
                    ["You're basically", "a meditation", "app right now."],
                    ["Zen master", "mode:", "Activated."]
                ];
                color = 0x66DDBB;
            }
            
            var idx = (breathingPhase.toNumber() / 8) % phrases.size();
            var phrase = phrases[idx];
            
            // Soft background glow
            dc.setColor(0x0a1a15, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, (w * 0.35).toNumber());
            
            // Main message - use XTINY with more spacing
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 28, Graphics.FONT_XTINY, phrase[0], Graphics.TEXT_JUSTIFY_CENTER);
            
            dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 2, Graphics.FONT_XTINY, phrase[1], Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, cy + 24, Graphics.FONT_XTINY, phrase[2], Graphics.TEXT_JUSTIFY_CENTER);
            
            // === CURRENT TIME - Bottom center ===
            drawCurrentTime(dc, cx, h);
        }
        
        // Helper function to draw current time at bottom center
        private function drawCurrentTime(dc, cx, h) {
            var now = Time.now();
            var info = Gregorian.info(now, Time.FORMAT_SHORT);
            var timeString = Lang.format("$1$:$2$", [
                info.hour.format("%02d"),
                info.min.format("%02d")
            ]);
            
            dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h - 40, Graphics.FONT_XTINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // ═══════════════════════════════════════════════════════════════
        // PROCEDURAL INSTABILITY RENDERING
        // Visual tension maps directly to physiological tension
        // ═══════════════════════════════════════════════════════════════
        
        // Calculate how unstable/jittery the visualization should be
        // Returns 0.0 (perfectly calm) to 1.0 (extremely tense)
        private function calculateInstability(quadrant, arousal, cv) {
            var baseInstability = 0.0;
            
            // Quadrant-based baseline
            if (quadrant == QUADRANT_STRESSED) {
                baseInstability = 0.6;  // High baseline tension
            } else if (quadrant == QUADRANT_EXCITED) {
                baseInstability = 0.3;  // Moderate activation
            } else if (quadrant == QUADRANT_TIRED) {
                baseInstability = 0.25;  // Low-grade depletion jitter
            } else {
                baseInstability = 0.05;  // Calm, minimal jitter
            }
            
            // Arousal amplifies instability (more arousal = more jitter)
            var arousalFactor = arousal.abs() * 0.4;
            
            // Low HRV stability = more visual instability
            var stabilityPenalty = 0.0;
            if (cv != null && cv > 0.3) {
                stabilityPenalty = (cv - 0.3) * 0.5;  // Unstable HRV = unstable visuals
            }
            
            var total = baseInstability + arousalFactor + stabilityPenalty;
            if (total > 1.0) { total = 1.0; }
            if (total < 0.0) { total = 0.0; }
            
            return total;
        }
        
        // Draw circle with procedural instability
        // Higher instability = more jitter in radius, position, thickness
        private function drawInstableOrb(dc, cx, cy, baseRadius, color, dimColor, instability) {
            var segments = 24;  // Draw circle as 24 connected line segments
            var points = new [segments + 1];
            
            // Generate perturbed circle points
            for (var i = 0; i <= segments; i++) {
                var angle = (i.toFloat() / segments) * Math.PI * 2;
                
                // Perturb radius with layered noise
                var radiusNoise = 0.0;
                if (instability > 0.01) {
                    // Low-frequency wobble (slow shape deformation)
                    var wobble1 = Math.sin(angle * 2.3 + pulsePhase * 0.7 + noiseSeeds[0] * 0.01) * instability * 8;
                    // High-frequency jitter (nervous tremor)
                    var wobble2 = Math.sin(angle * 7.1 + pulsePhase * 2.1 + noiseSeeds[1] * 0.01) * instability * 3;
                    // Random component (chaos)
                    var chaos = ((noiseSeeds[i % 8] + pulsePhase.toNumber() * 10) % 100 - 50) * instability * 0.15;
                    
                    radiusNoise = wobble1 + wobble2 + chaos;
                }
                
                var r = baseRadius + radiusNoise;
                var x = cx + (Math.cos(angle) * r).toNumber();
                var y = cy + (Math.sin(angle) * r).toNumber();
                
                points[i] = [x, y];
            }
            
            // Draw glow (only if calm-ish)
            if (instability < 0.4) {
                dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, cy, baseRadius + 6);
            }
            
            // Draw main outer ring with variable thickness
            var thickness = 3;
            if (instability > 0.5) {
                // Stressed states: jitter the line thickness too
                thickness = 2 + ((Math.sin(pulsePhase * 3.7) * 0.5 + 0.5) * instability * 3).toNumber();
            }
            
            dc.setPenWidth(thickness);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < segments; i++) {
                dc.drawLine(points[i][0], points[i][1], points[i + 1][0], points[i + 1][1]);
            }
            
            // Draw inner ring (scaled down)
            var innerScale = 0.7;
            dc.setPenWidth(1);
            for (var i = 0; i < segments; i++) {
                var x1 = cx + ((points[i][0] - cx) * innerScale).toNumber();
                var y1 = cy + ((points[i][1] - cy) * innerScale).toNumber();
                var x2 = cx + ((points[i + 1][0] - cx) * innerScale).toNumber();
                var y2 = cy + ((points[i + 1][1] - cy) * innerScale).toNumber();
                dc.drawLine(x1, y1, x2, y2);
            }
            
            // For very tense states, add visual "spikes" radiating outward
            if (instability > 0.65) {
                dc.setPenWidth(1);
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                var spikeCount = 8;
                for (var i = 0; i < spikeCount; i++) {
                    var angle = (i.toFloat() / spikeCount) * Math.PI * 2;
                    var spikeIntensity = Math.sin(angle * 3 + pulsePhase * 2) * 0.5 + 0.5;
                    
                    if (spikeIntensity > 0.4) {
                        var innerR = baseRadius * 1.05;
                        var outerR = baseRadius * (1.05 + spikeIntensity * instability * 0.3);
                        
                        var x1 = cx + (Math.cos(angle) * innerR).toNumber();
                        var y1 = cy + (Math.sin(angle) * innerR).toNumber();
                        var x2 = cx + (Math.cos(angle) * outerR).toNumber();
                        var y2 = cy + (Math.sin(angle) * outerR).toNumber();
                        
                        dc.drawLine(x1, y1, x2, y2);
                    }
                }
            }
        }
        
        function retry() {
            viewMode = 0;
            biometricCollector.reset();
            alertManager.reset();
            emotionalState = null;
            smoothedArousal = 0.0;
            smoothedValence = 0.0;
            breathingPhase = 0.0;
            WatchUi.requestUpdate();
        }
    }
}
