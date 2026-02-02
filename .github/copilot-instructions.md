# Copilot Instructions for Affect - Real-Time Affective State Tracker

## Project Overview

**Affect** is a Garmin Connect IQ widget in pre-production that provides real-time biofeedback on affective state using Russell's Circumplex Model. It implements a Threat–Challenge adaptation using HRV (RMSSD) and heart rate data to map physiological state onto two dimensions:
- **Arousal** (energy/activation level)
- **Valence** (engagement quality: threat vs challenge response)

### Key Features
- **12 Distinct States**: Detailed classification from "Serene" to "Thriving" to "Intense"
- **Personal Calibration**: 2-minute baseline for individualized readings
- **Memory-Efficient**: ~600 bytes total buffer usage for Garmin's strict constraints
- **Glanceable Widget**: Quick check-ins without full app launch
- **75+ Compatible Devices**: Fenix, Forerunner, Venu, Vivoactive, Epix, etc.
- **Persistent Storage**: Calibration saved across sessions

## Technology Stack

- **Language**: Monkey C (Garmin proprietary)
- **Platform**: Garmin Connect IQ SDK 8.4.0+
- **App Type**: Widget (glanceable interface)
- **Min API Level**: 3.2.0 (required for SensorHistory)

## Key Files

| File | Purpose |
|------|---------|
| `source/RMSSDCalculator.mc` | RMSSD calculation with 90-element circular buffer |
| `source/HRVStabilityAnalyzer.mc` | HRV stability (CV) using Welford's online algorithm (optional, for confidence) |
| `source/CalibrationManager.mc` | 2-minute baseline calibration with persistent storage |
| `source/CircumplexMapper.mc` | Maps (HR, RMSSD) to (Arousal, Valence) using threat–challenge model |
| `source/BiometricCollector.mc` | Sensor polling at 1Hz |
| `source/AffectView.mc` | UI rendering (calibration screen + circumplex plot) |
| `source/AffectApp.mc` | Application entry point |
| `manifest.xml` | App manifest with device list, permissions |
| `monkey.jungle` | Build configuration |

## Build Commands

```powershell
# Set SDK path
$SDK = "C:\Users\guzzi\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.4.0-2025-12-03-5122605dc"

# Build PRG for specific device (for sideloading/testing)
& "$SDK\bin\monkeyc.bat" -f monkey.jungle -o bin/Affect.prg -d fenix7 -y developer_key -w

# Build universal IQ file (for store upload)
& "$SDK\bin\monkeyc.bat" -f monkey.jungle -o bin/Affect.iq -y developer_key -r -w

# Run in simulator
& "$SDK\bin\connectiq.bat"  # Start simulator first
& "$SDK\bin\monkeydo.bat" bin/Affect.prg fenix7
```

## Deployment Methods

### Method 1: Sideload PRG to Device (Testing)
1. Build PRG for specific device: `monkeyc -d vivoactive5 -o bin/Affect.prg ...`
2. Connect watch via USB
3. Copy PRG to `/GARMIN/APPS/` on watch
4. Eject and find app in widgets

### Method 2: Connect IQ Store (Distribution)
1. In VS Code, run command: **Monkey C: Export Project** (Ctrl+Shift+P)
2. Select export destination folder
3. Go to https://developer.garmin.com/connect-iq/submit-an-app/
4. Click **"Submit an App"** and upload the generated `.iq` file
5. Add description, screenshots, and app details
6. Submit for review (typically 72 hours)

**Important**: The IQ file is for store upload only. For USB sideloading, use PRG files.

## Memory Constraints

Garmin watches have strict memory limits (~28-64KB depending on device):
- Use fixed-size circular buffers (not dynamic arrays)
- Use streaming algorithms (Welford's variance, running sums)
- Avoid storing raw data - process and discard immediately
- Current memory footprint: ~600 bytes for all buffers

## Key Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `CALIBRATION_DURATION` | 120s | Baseline calibration time |
| `RR_BUFFER_SIZE` | 90 | Circular buffer for RR intervals |
| `RMSSD_HISTORY_SIZE` | 60 | RMSSD values for stability calculation |
| `TENSION_PENALTY` | 0.5 | How much elevated HR penalizes valence |
| `AROUSAL_LOW_GATE` | 0.15 | Below this, valence = pure RMSSD |
| `AROUSAL_HIGH_GATE` | 0.4 | Above this, full threat–challenge logic |
| `AROUSAL_HR_WEIGHT` | 0.6 | Weight of HR vs RMSSD in arousal |

## Algorithm Summary

### Arousal (SNS/PNS balance)
```
Arousal = (0.6 × Z_HR + 0.4 × (-Z_RMSSD)) / 3
```
- High HR + Low RMSSD = High Arousal (stress, excitement)
- Low HR + High RMSSD = Low Arousal (calm, relaxed)

### Valence (Threat–Challenge / RMSSD Preservation)
```
At high arousal:
  Valence ≈ (Z_RMSSD - 0.5 × max(0, Z_HR)) / 2

At low arousal:
  Valence ≈ Z_RMSSD / 2  (recovery vs depletion)
```
- **Engaged/Excited**: HR elevated + RMSSD preserved (challenge response)
- **Stressed/Tense**: HR elevated + RMSSD suppressed (threat response)
- **Calm/Serene**: HR low + RMSSD high (restored)
- **Tired/Drained**: HR low + RMSSD low (depleted)

### The 12 Affective States

The app classifies user state into one of 12 labels based on arousal-valence coordinates:

#### High Arousal + Positive Valence (ENGAGED Quadrant)
*Challenge Response - High activation with preserved HRV*
- **Engaged** (medium-high arousal, slight +V): Focused and alert
- **Excited** (high arousal, +V): Energized and enthusiastic  
- **Thriving** (very high arousal, very +V): Peak performance/flow state

**Physiology**: HR elevated BUT RMSSD preserved → parasympathetic still engaged

#### High Arousal + Negative Valence (STRESSED Quadrant)
*Threat Response - High activation with HRV suppression*
- **Tense** (medium-high arousal, slight -V): Uncomfortable activation
- **Stressed** (high arousal, -V): Overwhelmed and pressured
- **Intense** (very high arousal, very -V): Extreme stress/fight-or-flight

**Physiology**: HR elevated AND RMSSD suppressed → parasympathetic withdrawal

#### Low Arousal + Positive Valence (CALM Quadrant)
*Recovery State - Low activation with good HRV*
- **Still** (medium-low arousal, slight +V): Quiet and present
- **Calm** (low arousal, +V): Relaxed and at peace
- **Serene** (very low arousal, very +V): Deeply restored

**Physiology**: HR low AND RMSSD high → full parasympathetic dominance

#### Low Arousal + Negative Valence (TIRED Quadrant)
*Depletion State - Low activation with poor HRV*
- **Resting** (medium-low arousal, slight -V): Quietly depleted
- **Tired** (low arousal, -V): Fatigued and drained
- **Drained** (very low arousal, very -V): Severe depletion/burnout

**Physiology**: HR low BUT RMSSD also low → parasympathetic depleted

### Quadrant Constants
| Quadrant | Constant | Labels (by intensity) |
|----------|----------|----------------------|
| High A, +V | `QUADRANT_EXCITED` | Engaged → Excited → Thriving |
| High A, -V | `QUADRANT_STRESSED` | Tense → Stressed → Intense |
| Low A, +V | `QUADRANT_CALM` | Still → Calm → Serene |
| Low A, -V | `QUADRANT_TIRED` | Resting → Tired → Drained |

## Common Issues & Solutions

### "Cannot find entry point class"
- Entry class must be OUTSIDE any module
- Check `AffectApp.mc` - class should not be inside `module Affect`

### "Invalid device id in manifest"
- Device IDs must match SDK's known devices exactly
- Check https://developer.garmin.com/connect-iq/compatible-devices/

### "Error processing manifest file" (store upload)
- Remove invalid device IDs from manifest.xml
- Ensure UUID is valid 128-bit format
- Check permissions are valid for app type

### Timer callback signature error
- Add `as Lang.Method` cast: `timer.start(method(:onUpdate) as Lang.Method, 1000, true);`

## Supported Devices

75+ devices including:
- Fenix 7/8 series, Epix 2
- Venu 2/3/4 series
- Forerunner 165, 255, 265, 570, 955, 965, 970
- Vivoactive 5/6
- Instinct 3 series
- MARQ Gen 2
- D2 Air/Mach series

## Testing Without Physical Device

Use the simulator:
```powershell
.\test-vivoactive5.ps1
# Or manually:
& "$SDK\bin\connectiq.bat"
& "$SDK\bin\monkeydo.bat" bin/Affect.prg vivoactive5
```

Note: Simulator provides limited sensor data. Real device testing required for accurate HRV.

## Project Status

**Current Phase**: Pre-production
- ✅ Core algorithm implemented and tested
- ✅ 12-state classification system complete
- ✅ Memory-efficient design validated
- ✅ Calibration and persistent storage working
- ✅ UI rendering optimized
- ✅ Documentation complete
- ⏳ Awaiting Connect IQ Store submission
- ⏳ Beta testing phase

## Important Notes for AI Assistant

1. **This is physiology-driven biofeedback**, not emotion detection
2. **Valence axis** measures RMSSD preservation under arousal (threat vs challenge), not "happiness"
3. **Always maintain memory efficiency** - use fixed buffers, streaming algorithms
4. **State labels** are descriptive approximations of physiological patterns, not mind-reading
5. **External factors** (caffeine, altitude, illness, etc.) significantly affect readings
6. **Not medical advice** - this is informational/entertainment only

## When Helping Users

- Emphasize that readings show autonomic state, not specific emotions
- Remind about calibration importance for accuracy
- Note that artifacts (motion, poor contact) affect HRV significantly
- Reference the 12 states by their proper names and physiological meanings
- Always consider memory constraints when suggesting code changes
- Use the existing streaming/circular buffer patterns for new features
