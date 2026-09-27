# MoodMap — Geometric Shape & Color Wave Engine (macOS Swift)
### DEVELOPER TEXT HERE (REAL HOOMAN)
This entire project is created using Gemini Antigravity prompts!  
Here are the prompts I used [ai-prompts.md](ai-prompts.md)
### AI GENERATED TEXT BEGINS
A native macOS application built with Swift and SpriteKit that reads geometric shapes from JSON data files, rasterizes them into discrete square pixel nodes (from $4\times 4$ up to $32\times 32$ pixels), and animates them using dynamic color wave patterns loaded from JSON mood files.

---

## Features

- **Geometric Shape Rasterizer**: Automatically converts vector shapes defined in JSON into discrete square pixel grids. Supported shapes:
  - `square`
  - `rectangle`
  - `circle`
  - `ring` / `donut`
  - `triangle` (with directional orientation: `up`, `down`, `left`, `right`)
  - `diamond`
  - `star` (configurable points, inner/outer radius)
  - `cross`
  - `polygon`
- **Variable Node Sizing**:
  - Chunky $32\times 32$ px nodes (retro arcade aesthetic)
  - Standard $16\times 16$ px / $12\times 12$ px nodes
  - Fine $8\times 8$ px nodes
  - High-density $4\times 4$ px micro nodes
- **Algorithmic Wave & Mood Engine**:
  - Color transitions driven by multi-stop palettes in JSON.
  - 10 procedural propagation patterns:
    - `insideOut`: Expanding radial pulse from map center
    - `outsideIn`: Concentric wave collapsing inward
    - `topDown`: Vertical cascade from screen top to bottom
    - `bottomUp`: Upward surge from screen bottom to top
    - `leftToRight`: Horizontal wave from left to right
    - `rightToLeft`: Horizontal wave from right to left
    - `diagonal`: 45-degree planar refraction wave
    - `spiral`: Archimedean vortex wave
    - `radialPulse`: Synchronized heartbeat pulse
    - `harmonicWave`: 2D spatial sine interference
- **Interactive Keyboard Controls**:
  - `←` / `→` (Left / Right Arrow): Cycle between Map files with smooth staggered wave dissolve/assembly transitions.
  - `↑` / `↓` (Up / Down Arrow): Cycle between Mood files with continuous color cross-fading.
  - `+` / `-` (or `=` / `-`): Dynamically scale node size up or down in real time (from 4px to 64px).
  - `Space`: Pause / Resume animation.
  - `R`: Randomize map & mood combination.
  - `H`: Toggle the diagnostic HUD overlay.
- **Metal Hardware Acceleration**: High frame rates (60/120 FPS on ProMotion) utilizing SpriteKit batched rendering.

---

## Quick Start & Running

### 1. Open with Xcode:
Double-click or run:
```bash
open MoodMap.xcodeproj
```
Select the `MoodMap` scheme in the toolbar and hit **Run (⌘R)**! All Swift source files and JSON Map/Mood assets are organized into groups in the Project Navigator.

### 2. Build and Run via Terminal (SwiftPM):
```bash
# Build the project
swift build

# Run the app
swift run
```

Or run the built binary directly:
```bash
./.build/out/Products/Debug/MoodMap
```

### 2. Run Automated Verification Tests:
```bash
./.build/out/Products/Debug/MoodMap --test
```

---

## JSON File Formats

### 1. Map Configuration (`Sources/Resources/Maps/*.json`)
```json
{
  "id": "my_custom_map",
  "name": "My Custom Map",
  "description": "Square, circle and triangle composition",
  "canvas": {
    "width": 1024,
    "height": 768
  },
  "nodeSize": 16,
  "spacing": 2,
  "shapes": [
    {
      "type": "circle",
      "center": { "x": 300, "y": 400 },
      "radius": 120,
      "filled": true
    },
    {
      "type": "square",
      "center": { "x": 700, "y": 400 },
      "size": 180,
      "filled": true
    },
    {
      "type": "triangle",
      "center": { "x": 500, "y": 200 },
      "width": 200,
      "height": 160,
      "direction": "up",
      "filled": true
    }
  ]
}
```

### 2. Mood Configuration (`Sources/Resources/Moods/*.json`)
```json
{
  "id": "neon_abyss",
  "name": "Neon Abyss",
  "palette": [
    "#FF007F",
    "#7928CA",
    "#0070F3",
    "#00DFD8",
    "#FF007F"
  ],
  "pattern": {
    "type": "insideOut",
    "wavelength": 220.0,
    "speed": 1.3,
    "cycleDuration": 3.5
  },
  "visuals": {
    "minAlpha": 0.45,
    "maxAlpha": 1.0,
    "scalePulse": 0.08
  }
}
```

---

## Bundled Sample Assets

### Maps
1. **01_geometric_quartet.json**: Square, Circle, Triangle, Rectangle, and Ring (16px nodes).
2. **02_mandala_rings.json**: Concentric rings, starbursts, and diamonds (8px nodes).
3. **03_retro_arcade.json**: Chunky 8-bit style spacecraft motif (32px nodes).
4. **04_dual_pyramids.json**: Mirrored pyramids, diamond gateway, and orbit spheres (12px nodes).
5. **05_micro_stellar_lattice.json**: High-density planetary system (4px nodes).

### Moods
1. **01_cyberpunk_neon.json**: Electric magenta, cyan, and violet expanding radially (`insideOut`).
2. **02_aurora_borealis.json**: Cascading emerald, violet, and sky blue (`topDown`).
3. **03_solar_flare.json**: Incandescent crimson, ember orange, and gold (`leftToRight`).
4. **04_vortex_spiral.json**: Cosmic vortex in indigo, magenta, and teal (`spiral`).
5. **05_bioluminescent_abyss.json**: Hydrothermal ocean flow ascending (`bottomUp`).
6. **06_prismatic_horizon.json**: 45-degree diagonal refraction wave (`diagonal`).
7. **07_monochrome_pulse.json**: High-contrast silver, charcoal, and white heartbeat (`radialPulse`).
8. **08_harmonic_matrix.json**: 2D spatial harmonic interference (`harmonicWave`).
