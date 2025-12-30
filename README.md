# Affect - Real-Time Affective State Tracker for Garmin

[![Connect IQ](https://img.shields.io/badge/Connect%20IQ-8.4.0+-blue.svg)](https://developer.garmin.com/connect-iq/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Garmin%20Connect%20IQ-orange.svg)](https://apps.garmin.com)

A Garmin Connect IQ **widget** that provides real-time biofeedback on your affective state using Russell's Circumplex Model. It analyzes heart rate and heart rate variability (HRV) to map your physiological state onto two dimensions: **Arousal** (energy/activation) and **Valence** (engagement vs stress).

<p align="center">
  <img width="200" alt="image" src="https://github.com/user-attachments/assets/102a1463-c2cc-4f5e-88b9-9acdc2251ce8" />
  <img width="200" alt="image" src="https://github.com/user-attachments/assets/8e3e6ba3-a7bd-4794-bbcd-3c7e18a99785" />
  <img width="200" alt="image" src="https://github.com/user-attachments/assets/53568788-41a2-4b16-ad21-6d222c8c7cff" />
  <img width="200" alt="image" src="https://github.com/user-attachments/assets/95773903-f049-4bb3-8ccb-88b567d68d4d" />
</p>

## ✨ Key Features

- **Real-Time Affective State Tracking**: Continuous analysis of heart rate and HRV (RMSSD) to map your current state
- **12 Distinct States**: From "Serene" to "Thriving" to "Intense" - detailed emotional state classification
- **Personal Calibration**: 2-minute baseline calibration for accurate, individualized readings
- **Threat–Challenge Model**: Distinguishes between positive high-arousal (excitement/engagement) and negative high-arousal (stress/tension)
- **Predictive Vibration Alerts**: Early warning system detects trajectory toward extreme states and provides haptic nudges before overwhelm
- **Multiple View Modes**: Three distinct screens - cinematic emotion view, detailed metrics, and supportive guidance messages
- **Alexithymia Support**: Body-focused language ("heart active, body tight") instead of abstract emotion labels
- **Visual Instability Rendering**: Dynamic visualization with organic jitter that mirrors your physiological tension in real-time
- **Interactive Controls**: Tap to cycle through views, long-press to recalibrate
- **Memory-Efficient**: Designed for Garmin's strict memory constraints (~600 bytes total buffer usage)
- **Glanceable Widget**: Quick check-ins without launching a full app
- **Visual Circumplex Display**: See your position on the arousal-valence plane at a glance
- **Persistent Calibration**: Baseline stored across sessions - no need to recalibrate constantly
- **75+ Compatible Devices**: Works on Fenix, Forerunner, Venu, Vivoactive, Epix, and more

## 🎯 How It Works

The Affect Engine continuously analyzes biometric data to provide live affective biofeedback:

$$f(HR, HRV_{RMSSD}) \rightarrow (Arousal, Valence)$$

## 🗺️ Understanding Your Affective States

### The Circumplex Model (Threat–Challenge Adaptation)

```
           High Arousal
                 |
     Stressed    |      Engaged
   (tense)       |    (excited)
                 |
─────────────────┼─────────────────
  Negative       |       Positive
  Valence        |       Valence
                 |
      Tired      |       Calm
   (depleted)    |    (restored)
                 |
            Low Arousal
```

This reframes Russell's circumplex using a **Threat–Challenge** model that better maps to what HR + HRV can distinguish physiologically.

### 📊 The 12 Affective States

The app classifies your state into one of 12 labels based on your position in the arousal-valence space. Each state has three intensity levels:

#### 🔥 High Arousal + Positive Valence: **ENGAGED** Quadrant
*"Challenge Response" - High activation with parasympathetic tone preserved*

| State | Arousal | Valence | Description | When You'll See This |
|-------|---------|---------|-------------|---------------------|
| **Engaged** | Medium-High | Slightly Positive | Focused and alert | Working on an interesting problem |
| **Excited** | High | Positive | Energized and enthusiastic | Approaching finish line, anticipation |
| **Thriving** | Very High | Very Positive | Peak performance state | Flow state, optimal challenge |

**Physiology**: Heart rate elevated BUT HRV (RMSSD) preserved → parasympathetic system still engaged

---

#### ⚡ High Arousal + Negative Valence: **STRESSED** Quadrant
*"Threat Response" - High activation with parasympathetic withdrawal*

| State | Arousal | Valence | Description | When You'll See This |
|-------|---------|---------|-------------|---------------------|
| **Tense** | Medium-High | Slightly Negative | Uncomfortable activation | Tight deadline, mild pressure |
| **Stressed** | High | Negative | Overwhelmed and pressured | Difficult workout, conflict |
| **Intense** | Very High | Very Negative | Extreme stress response | Fight-or-flight, panic, overtraining |

**Physiology**: Heart rate elevated AND HRV (RMSSD) suppressed → parasympathetic withdrawal, stress response

---

#### 🌊 Low Arousal + Positive Valence: **CALM** Quadrant
*"Recovery State" - Low activation with good HRV*

| State | Arousal | Valence | Description | When You'll See This |
|-------|---------|---------|-------------|---------------------|
| **Still** | Medium-Low | Slightly Positive | Quiet and present | Light meditation, easy breathing |
| **Calm** | Low | Positive | Relaxed and at peace | Deep relaxation, after-workout rest |
| **Serene** | Very Low | Very Positive | Deeply restored | Deep meditation, restorative sleep |

**Physiology**: Heart rate low AND HRV (RMSSD) high → full parasympathetic dominance, recovery mode

---

#### 😴 Low Arousal + Negative Valence: **TIRED** Quadrant
*"Depletion State" - Low activation with poor HRV*

| State | Arousal | Valence | Description | When You'll See This |
|-------|---------|---------|-------------|---------------------|
| **Resting** | Medium-Low | Slightly Negative | Quietly depleted | End of long day, low energy |
| **Tired** | Low | Negative | Fatigued and drained | Exhaustion, overtraining |
| **Drained** | Very Low | Very Negative | Severe depletion | Burnout, illness, severe fatigue |

**Physiology**: Heart rate low BUT HRV (RMSSD) also low → parasympathetic system depleted

---

### 📖 How to Read Your Display

The widget shows:

1. **Position Dot**: Your current location on the circumplex plane
   - **Horizontal axis**: Valence (left = negative, right = positive)
   - **Vertical axis**: Arousal (bottom = low, top = high)

2. **State Label**: One of the 12 states listed above (e.g., "Calm", "Excited", "Stressed")

3. **Numerical Values**:
   - **Arousal**: -1.0 (lowest) to +1.0 (highest activation)
   - **Valence**: -1.0 (most negative) to +1.0 (most positive)

4. **Raw Metrics** (for transparency):
   - **HR**: Current heart rate in BPM
   - **RMSSD**: Root mean square of successive RR interval differences (milliseconds)
     - Higher RMSSD = better HRV = more parasympathetic tone

### 💡 Interpretation Tips

**Good Signs:**
- **Excited/Thriving** during exercise → optimal challenge level
- **Calm/Serene** during rest → effective recovery
- Moving from **Stressed** to **Engaged** → adapting to challenge
- Moving from **Tired** to **Calm** → recovering properly
- **Smooth orb visuals** → stable autonomic state
- **Single vibration** followed by recovery → successfully caught and managed rising stress

**Warning Signs:**
- Stuck in **Stressed/Intense** → may need to reduce load
- **Tired/Drained** after rest → possible overtraining or illness
- **Tense** during intended relaxation → stress not resolving
- Very low RMSSD (<20ms) for extended periods → autonomic dysfunction
- **Frequent vibration alerts** → consistently hitting extreme states (consider intervention)
- **Jittery, spiked orb** → high physiological instability

**Understanding Vibration Alerts:**
The app uses a predictive early warning system:
- **Single short pulse**: "Approaching" alert - you're trending toward stress but not there yet
- **Double pulse**: "Warning" - you're in elevated stress territory and it's rising
- **Triple pulse**: "Urgent" - you're in extreme stress zone
- **Soft long pulse**: "Recovery" - positive feedback when you've come down from an extreme state
- **5-minute cooldown**: Between alerts to avoid notification fatigue

**Remember**: This is physiology-driven biofeedback, not mind-reading. External factors (caffeine, temperature, altitude, illness, medication) all affect these metrics.

## What this app is (and is not)

**✅ What it IS:**
- **Physiology-driven biofeedback tool** that shows your autonomic nervous system state
- **Training aid** to help you recognize your stress vs recovery patterns
- **Challenge-response monitor** to distinguish excitement from stress
- **Recovery tracker** to see if your downtime is truly restorative
- **Early warning system** for alexithymia support - catches rising stress before you consciously notice
- **Visual biofeedback** with real-time instability rendering that mirrors your physiology
- **Accessible for alexithymia** - uses body-focused language instead of abstract emotion words

**❌ What it is NOT:**
- **Not an emotion detector** - it cannot identify specific emotions like "anger" or "joy"
- **Not medical advice** - this is informational/entertainment only
- **Not a diagnostic tool** - does not diagnose anxiety, depression, or other conditions

The app tracks **physiological activation and autonomic balance**, not subjective feelings. The vibration alerts are predictive nudges, not diagnoses.

### The Two Axes Explained

#### **Arousal Axis** (Vertical: Activation/Energy)
- **What it measures**: Sympathetic vs Parasympathetic nervous system balance
- **High Arousal**: Elevated HR + Suppressed RMSSD = Stress/Excitement
- **Low Arousal**: Lower HR + Higher RMSSD = Rest/Calm
- **Range**: -1.0 (lowest activation) to +1.0 (highest activation)

#### **Valence Axis** (Horizontal: Engagement Quality)
- **What it measures**: RMSSD preservation under arousal (Threat vs Challenge)
- **Positive Valence**: RMSSD maintained despite elevated HR = Challenge response (engaged/recovered)
- **Negative Valence**: RMSSD suppressed alongside elevated HR = Threat response (stressed/depleted)
- **Range**: -1.0 (most negative/stressed) to +1.0 (most positive/engaged)

**Key Insight**: The valence axis doesn't measure "happiness" - it measures whether your parasympathetic nervous system is working WITH your stress response (challenge/engagement) or being shut down by it (threat/depletion).

## 🧮 Algorithm

### Arousal Calculation

Arousal correlates with the balance between Sympathetic (SNS) and Parasympathetic (PNS) nervous systems:

- **Metrics**: HR + RMSSD
- **Logic**:
  - Low RMSSD + High HR = **High arousal** (stress/excitement)
  - High RMSSD + Low HR = **Low arousal** (rest/relaxation)
- **Normalization**: user baseline calibration (see Calibration)

The default weighting (per project constants):

$$Arousal = \frac{0.6 \cdot Z_{HR} + 0.4 \cdot (-Z_{RMSSD})}{3}$$

Clamped to [-1, 1].

### Valence Calculation (RMSSD Preservation / Threat–Challenge)

Valence uses **RMSSD preservation under arousal** to separate stress from excitement:

- **Excitement/Challenge**: HR elevated but RMSSD preserved (parasympathetic tone maintained)
- **Stress/Threat**: HR elevated and RMSSD suppressed (parasympathetic withdrawal)

Formula (at high arousal):

$$Valence \approx \frac{Z_{RMSSD} - 0.5 \times \max(0, Z_{HR})}{2}$$

**Arousal gating**: at low arousal, valence reflects pure RMSSD level (recovery vs depletion).

Constants (per project):
- `TENSION_PENALTY = 0.5` — how much elevated HR penalizes valence
- `AROUSAL_LOW_GATE = 0.15` — below this, valence = pure RMSSD
- `AROUSAL_HIGH_GATE = 0.4` — above this, full stress vs excitement logic

## Memory-Efficient Design

Garmin Connect IQ apps have strict memory limits. The engine uses:

1. Fixed-size circular buffers (e.g., RR buffer ~90 samples)
2. Streaming calculations (Welford/online variance)
3. Incremental statistics (constant memory)
4. No unbounded arrays

## Architecture

Core components (see `source/`):

- `RMSSDCalculator.mc`: RMSSD from RR intervals using circular buffer
- `HRVStabilityAnalyzer.mc`: HRV stability (CV) using online variance
- `CalibrationManager.mc`: baseline calibration with persistent storage
- `CircumplexMapper.mc`: maps (HR, RMSSD) → (Arousal, Valence) using threat–challenge model
- `BiometricCollector.mc`: sensor polling (nominally 1 Hz)
- `AffectView.mc`: UI rendering (calibration + circumplex)

### Data Flow

```
SensorHistory (RR Intervals)
        ↓
  RMSSDCalculator (every beat / every new RR)
        ↓
  CircumplexMapper (threat–challenge mapping)
        ↓
  (Arousal, Valence) → UI
```

## 🚀 Getting Started

### Installation

#### Option 1: Connect IQ Store (Recommended - Coming Soon)
1. Open the Garmin Connect IQ app on your phone
2. Search for "Affect"
3. Install to your compatible watch
4. Add as a widget from your watch's widget menu

#### Option 2: Sideload for Testing (Advanced Users)
1. Build a `.prg` file for your device (see [Build Instructions](#-installation--build) below)
2. Connect your watch via USB
3. Copy the `.prg` to `/GARMIN/APPS/` on your watch
4. Eject and launch the widget

### First Run: Calibration

**Important**: For accurate readings, you must complete the 2-minute calibration on first launch.

1. **Launch the widget** from your watch's widget menu
2. **Stay calm and still** during the 2-minute calibration period
   - Sit or stand comfortably
   - Breathe normally
   - Avoid talking, moving, or fidgeting
3. **Wait for completion** - you'll see a progress bar
4. The widget will automatically switch to live tracking mode
5. **Calibration is saved** - you won't need to repeat it unless you reset the app

**Why calibration matters**: The app uses your personal baseline HR and RMSSD to normalize all readings. Without calibration, the states won't be accurate.

### Daily Use

1. **Swipe to the widget** from your watch face
2. **Glance at your current state**: Look at the position dot and state label
3. **Check the quadrant**:
   - Top-right (Engaged/Excited) = Good challenge level
   - Bottom-right (Calm/Serene) = Good recovery
   - Top-left (Tense/Stressed) = Consider backing off
   - Bottom-left (Resting/Tired) = Need more recovery
4. **Tap to switch views**:
   - **Emotion View** (default): Cinematic visualization with body-focused labels
   - **Metrics View**: Detailed numbers - HR, HRV, stability %, arousal/valence values
   - **Guidance View**: Supportive/humorous messages tailored to your current state
5. **Notice vibration alerts**: The watch will gently vibrate if you're trending toward extreme stress/depletion
6. **Review periodically** throughout your day to build awareness of your patterns

### Recalibration

If you need to recalibrate (e.g., after significant training changes, weight loss/gain, or if readings seem off):

1. Go to your watch's app settings
2. Find "Affect" in the widget list
3. Delete/clear data
4. Relaunch the widget to trigger a new calibration

### Usage

#### Reading the Display (Quick Reference)

#### Reading the Display (Quick Reference)

**Emotion View (Default Screen):**
- **Dynamic orb**: Center visualization with organic movement reflecting your physiological tension
  - Calm states: Smooth, gentle circles
  - Tense states: Jittery, spiked edges that literally show the instability
- **Body-focused labels**: "ACTIVATED", "TENSE", "RELAXED", "DEPLETED" (easier to recognize than abstract emotions)
- **Sublabels**: "heart active, body coping" / "heart calm, body tight" (alexithymia-friendly)
- **Dot position**: Your current state on the arousal-valence crosshair
- **Color coding**: Warm gold (excited), coral-red (stressed), teal (calm), lavender-blue (tired)

**Metrics View (Tap once):**
- **HR**: Current heart rate in beats per minute (large display)
- **HRV**: RMSSD in milliseconds (higher = better parasympathetic tone)
- **Stability**: Percentage showing HRV consistency
- **Arousal value**: -1.0 to +1.0 (activation level)
- **Valence value**: -1.0 to +1.0 (engagement quality)

**Guidance View (Tap twice):**
- **State-appropriate messages**: Supportive/humorous text based on your quadrant
  - Stressed: "Plot twist: You survive 100% of these."
  - Tired: "Horizontal is a valid life choice today."
  - Calm/Excited: Positive affirmations
- **Rotating phrases**: Multiple messages cycle through for variety

**Interactive Controls:**
- **Tap**: Cycle through views (Emotion → Metrics → Guidance → Emotion)
- **Long Press**: Reset and recalibrate
- **Time display**: Current time shown at bottom of most screens

**Quick Interpretation:**
- **Top-right quadrant** = High energy + good HRV = Engaged/Excited
- **Top-left quadrant** = High energy + poor HRV = Tense/Stressed
- **Bottom-right quadrant** = Low energy + good HRV = Calm/Serene
- **Bottom-left quadrant** = Low energy + poor HRV = Resting/Tired

#### (Archive) Old First Run Documentation

<details>
<summary>Previous documentation format (click to expand)</summary>

1. Launch widget
2. Stay calm and still during calibration
3. Baseline HR and RMSSD are calculated and stored
4. Widget switches to live tracking

### Live Tracking

- Dot: current state on circumplex
- Quadrant labels: **Engaged/Stressed/Calm/Tired** (with intensity variants like Thriving, Intense, Serene, Drained)
- Numeric values: Arousal (-1..+1), Valence (-1..+1)
- Metrics: HR and RMSSD displayed for transparency

### Recalibration

Baseline is stored in persistent properties. To recalibrate, clear the app’s stored data (or uninstall/reinstall).

</details>

## 📱 Supported Devices


**Platform Requirements:**
- **App type**: Widget (glanceable, always accessible)
- **Minimum API**: Connect IQ 3.2.0+ (required for `SensorHistory` API)
- **Developed with**: Connect IQ SDK 8.4.0+

**Compatible Device Families** (75+ devices):
- ✅ Fenix 7/8 series
- ✅ Epix 2 / Epix Pro
- ✅ Forerunner: 165, 255, 265, 570, 955, 965, 970
- ✅ Venu 2/3/4 series
- ✅ Vivoactive 5/6
- ✅ Instinct 3 series
- ✅ MARQ Gen 2 series
- ✅ D2 Air / D2 Mach series
- ✅ Enduro 2/3
- ✅ Tactix 7 / Tactix Delta

See [manifest.xml](manifest.xml) for the complete authoritative device list.

**Requirements**: Device must have:
1. Optical heart rate sensor
2. Connect IQ 3.2.0+ support
3. Enough available memory for widget (~600 bytes runtime)

## 🛠️ Installation & Build

### For End Users

**Recommended**: Wait for the Connect IQ Store release (coming soon!)

Alternatively, see [Getting Started](#-getting-started) above for sideloading instructions.

### For Developers

<details>
<summary>Developer Build Instructions (click to expand)</summary>

### Important: PRG vs IQ

- **`.prg`**: device-specific build used for **simulator and USB sideload testing**
- **`.iq`**: **universal** package intended for **Connect IQ Store upload**

For USB sideload testing on a physical watch, build and copy a **`.prg`**.

### Prerequisites (Windows)

1. Garmin Connect IQ SDK **8.4.0+**
2. Java (required by the SDK)
3. OpenSSL (for developer key generation)
4. A developer key (RSA 4096-bit)

### Generate Developer Key (DER format expected by monkeyc)

```powershell
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key -nocrypt
```

### Build Commands (Windows)

If you use the SDK `.bat` wrappers, set your SDK path:

```powershell
$SDK = "C:\Users\user\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.4.0-2025-12-03-5122605dc"
```

Build a **device-specific PRG** for testing/sideloading:

```powershell
& "$SDK\bin\monkeyc.bat" -f monkey.jungle -o bin\Affect.prg -d fenix7 -y developer_key -w
```

Run in the simulator:

```powershell
& "$SDK\bin\connectiq.bat"
& "$SDK\bin\monkeydo.bat" bin\Affect.prg fenix7
```

Build a **universal IQ** for store upload:

```powershell
& "$SDK\bin\monkeyc.bat" -f monkey.jungle -o bin\Affect.iq -y developer_key -r -w
```

### USB sideload (physical watch testing)

1. Build a **PRG for your device ID** (e.g., `vivoactive5`, `fenix7`, etc.)
2. Connect watch via USB (shows as a drive)
3. Copy the `.prg` to:

```
/GARMIN/APPS/
```

4. Eject and launch the widget

### Helper scripts

This repo includes PowerShell/batch helpers (see project root), e.g.:
- `build-iq.ps1` (build package)
- `test-*.ps1` (device/simulator runs)
- `start-simulator.bat`, `run*.bat`

</details>

## 🏗️ Architecture & Memory Design

### Core Components

The app is designed with **strict memory efficiency** for Garmin's constraints (~28-64KB available depending on device):

| Component | Purpose | Memory Strategy |
|-----------|---------|----------------|
| `RMSSDCalculator.mc` | RMSSD from RR intervals | 90-element circular buffer |
| `HRVStabilityAnalyzer.mc` | HRV stability (CV) | Welford's online variance algorithm |
| `CalibrationManager.mc` | Baseline calibration | Persistent storage (AppStorage) |
| `CircumplexMapper.mc` | Maps (HR, RMSSD) → (Arousal, Valence) | Stateless computation |
| `BiometricCollector.mc` | Sensor polling at 1Hz | Direct streaming, no buffering |
| `AlertManager.mc` | Predictive vibration alerts | 10-sample trend detection with linear regression |
| `AffectView.mc` | UI rendering with 3 view modes | Minimal draw calls, procedural rendering |
| `AffectDelegate.mc` | Input handling | Tap/long-press gesture detection |

**Total Memory Footprint**: ~600 bytes for all buffers

### Memory-Efficient Techniques

1. **Fixed-size circular buffers** - No dynamic arrays
2. **Streaming algorithms** - Welford's online variance, running sums
3. **Process and discard** - No raw data storage
4. **Persistent calibration** - Baseline stored in properties, not RAM

### Data Flow

```
SensorHistory (RR Intervals from watch)
        ↓
  RMSSDCalculator (every new RR interval)
        ↓
  CircumplexMapper (applies threat–challenge model)
        ↓
  (Arousal, Valence) → UI Rendering
```

## ⚠️ Limitations & Disclaimers

### Scientific Limitations

1. **Physiology ≠ emotion**: HR/HRV cannot uniquely identify discrete emotions without context.
1. **Physiology ≠ emotion**: HR/HRV cannot uniquely identify discrete emotions without context.
2. **Valence is a proxy**: RMSSD preservation reflects threat–challenge distinction, not hedonic pleasure.
3. **Motion artifacts**: movement and poor sensor contact can dominate short-term HRV features.
4. **Breathing effects**: paced/slow breathing can raise RMSSD without implying "positive emotion."
5. **Individual variation**: population baselines are used; personal calibration would improve accuracy.

### Technical Limitations

1. **Sensor quality varies**: Optical HR sensors are less accurate than chest straps, especially during movement
2. **Update frequency**: Data updates approximately every second, not real-time
3. **Calibration dependency**: Readings are only as good as your initial calibration conditions
4. **No emotion specificity**: Cannot distinguish "angry" from "excited" or "sad" from "tired"

### External Factors That Affect Readings

- ☕ **Caffeine/stimulants** - Elevate HR and may suppress HRV
- 🌡️ **Temperature** - Heat/cold affect HR and HRV
- 🏔️ **Altitude** - Affects HR and respiratory patterns
- 💊 **Medications** - Many affect heart rate and HRV
- 🤒 **Illness** - Infection/inflammation suppresses HRV
- 🍺 **Alcohol** - Suppresses HRV for 12-24 hours after consumption
- 😴 **Sleep quality** - Poor sleep suppresses HRV the next day
- 💪 **Exercise timing** - Recent hard exercise suppresses HRV

### Legal Disclaimer

**This app is for informational and entertainment purposes only.**

- ⚠️ **Not medical advice** - Do not use for diagnosis or treatment
- ⚠️ **Not FDA approved** - This is not a medical device
- ⚠️ **Consult professionals** - See a doctor for health concerns
- ⚠️ **No warranties** - Use at your own risk

## 📚 References & Further Reading

## 📚 References & Further Reading

### Scientific Background

- **Russell, J. A. (1980)**. A circumplex model of affect. *Journal of Personality and Social Psychology*, 39(6), 1161–1178.
  - Original circumplex model of affect
- **Blascovich, J., & Mendes, W. B. (2000)**. Challenge and threat appraisals: The role of affective cues. In *Feeling and Thinking* (pp. 59–82). Cambridge University Press.
  - Theoretical basis for threat–challenge distinction
- **Shaffer, F., & Ginsberg, J. P. (2017)**. An Overview of Heart Rate Variability Metrics and Norms. *Frontiers in Public Health*, 5, 258.
  - Comprehensive HRV metrics guide
- **Task Force of the European Society of Cardiology (1996)**. Heart rate variability: standards of measurement, physiological interpretation and clinical use. *Circulation*, 93(5), 1043–1065.
  - Gold standard HRV guidelines

### Additional Reading

- **Porges, S. W. (2011)**. The Polyvagal Theory: Neurophysiological Foundations of Emotions
  - Understanding the vagal nerve's role in emotion regulation
- **Appelhans, B. M., & Luecken, L. J. (2006)**. Heart rate variability as an index of regulated emotional responding. *Review of General Psychology*, 10(3), 229-240.
  - HRV and emotion regulation

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

**Areas for contribution:**
- Device-specific testing and optimization
- UI/UX improvements
- Additional validation studies
- Documentation improvements
- Translations

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

---

## 💬 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/yelabb/Affect/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yelabb/Affect/discussions)

## 🙏 Acknowledgments

Built with the Garmin Connect IQ SDK. Thanks to the Connect IQ developer community for their support and resources.

---

## Disclaimer

Informational/entertainment only. Not medical advice.

**Made with ❤️ for the quantified self community**




