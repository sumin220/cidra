# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cidra is a macOS native menu bar utility for managing external monitors — brightness/volume control via DDC/CI and text sharpening (HiDPI) via virtual screens. It targets macOS 14 Sonoma+ and follows a "Simple is Best" design philosophy.

## Tech Stack

- Swift 5.9+, SwiftUI, AppKit
- MenuBarExtra (.window style) menu bar app
- Multi-process architecture: main app + XPC services (DisplayEngineXPC, DDCServiceXPC)
- Swift Package Manager for dependencies
- App Sandbox enabled, LSUIElement = YES (no Dock icon)

## Build & Run

```bash
# Build
xcodebuild -scheme Cidra -configuration Debug build

# Run tests
xcodebuild -scheme Cidra test

# Build release
./Scripts/build-release.sh

# Notarize
./Scripts/notarize.sh
```

Open `Cidra.xcodeproj` in Xcode for development. Deployment target: macOS 14.0. Bundle ID: `com.cidra.app`.

## Architecture

```
Cidra.app (UI + Business Logic)
  ├── UI Layer: MenuBarPanel, SettingsView, OSDOverlay, Onboarding
  ├── Application Layer: PresetManager, AutoTriggerEngine, MonitorRegistry, LicenseManager
  └── XPC Communication
        ├── DisplayEngineXPC (com.cidra.display-engine) — virtual screens, HiDPI, XDR brightness
        └── DDCServiceXPC (com.cidra.ddc-service) — DDC/CI hardware control via IOAVService/IOI2CInterface
```

Private APIs are isolated in XPC services so crashes don't affect the main app. XPC protocols use `@objc` + `Codable` data transfer.

## Source Layout (TRD Section 6.1)

- `Sources/App/` — Entry point (CidraApp, AppDelegate)
- `Sources/UI/MenuBar/` — Main panel (MenuBarPanel, MonitorControlCard, ControlCenterSlider, PresetGrid)
- `Sources/UI/Settings/` — Preferences window
- `Sources/UI/OSD/` — On-screen display overlay (AppKit NSWindow)
- `Sources/UI/Onboarding/` — First-run flow
- `Sources/Core/` — Business logic (Presets, Monitors, License, XPC)
- `Sources/Intents/` — App Intents for Spotlight/Siri/Shortcuts
- `DisplayEngineXPC/` — XPC service for display configuration
- `DDCServiceXPC/` — XPC service for DDC hardware control

## Design Specifications

All design docs are in `docs/`:
- `Cidra_PRD_v2.md` — Product requirements, Free/Pro tiers, business model
- `Cidra_TRD.md` — Technical architecture, XPC protocols, pseudo-code for all modules
- `Cidra_ScreenSpec.md` — UI specs: color tokens, typography, spacing, component states, interactions
- `docs/screens/` — Stitch-exported design screenshots (dark/light, free/pro variants)

## Key Design Rules

- **Panel width: 272px.** Custom capsule sliders (22px height, 11px radius). SF Symbols only, no emoji.
- **"Simple is Best"**: Menu bar panel shows only sliders + toggle + presets. No technical terms (DDC, virtual screen, oversampling) exposed to users.
- **System colors first** (`Color(.labelColor)`, `Color(.systemBlue)`), custom color tokens only for fine-tuning.
- **Free tier**: presets dimmed (opacity 0.3), tap shows Pro upsell. **Pro tier**: active preset gets accent border.
- **User-facing label**: "Sharpening" (not "HiDPI" or "virtual screen").

## Privacy

- **No analytics, no tracking, no data collection.** Zero network calls.
- Free, open-source, MIT license.

## Project Status

Personal macOS display utility. Free and open-source. No commercial intent.
Built as a learning project for macOS system programming (DDC/CI, HiDPI, IOKit, CoreGraphics).

## Dependencies (SPM)

- KeyboardShortcuts — global hotkeys

## Distribution

App Store is not possible (private API usage). Distributed via GitHub Releases (.dmg) and Homebrew Cask. Requires Developer ID signing + Apple Notarization for distribution.
