# Cidra

A simple macOS menu bar utility for controlling external monitor brightness, volume, and HiDPI text sharpening.

## Features

- **Brightness control** — DDC/CI for supported monitors, gamma fallback for the rest, DisplayServices for built-in displays
- **Volume control** — DDC/CI for external monitors with built-in speakers
- **Software dimming** — Drag the slider below 0% to dim further than the hardware minimum
- **XDR brightness** — Push built-in displays beyond the SDR 500-nit cap (Apple Silicon)
- **Sharpening** — One-time setup adds HiDPI modes to your monitor for sharper text
- **Presets** — Save and apply brightness/volume combinations across all monitors with one click
- **Auto triggers** — Apply presets automatically based on time of day or app activation
- **BlackOut** — `⌘⇧B` to instantly turn off all displays and mute audio
- **Ambient Light Sync** — Mirror MacBook's ambient light brightness to external monitors
- **Keyboard shortcuts** — F1/F2 for brightness, custom for volume and BlackOut

## Privacy

No analytics. No tracking. No network calls. No telemetry. Ever.

## Status

Personal project. MIT licensed. Pull requests welcome.

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon recommended (DDC/CI requires it)

## Build

```bash
brew install xcodegen
xcodegen generate
xcodebuild -scheme Cidra -configuration Release build
```

Open `Cidra.xcodeproj` in Xcode for development.

## Why?

I built this to learn macOS system programming — DDC/CI, HiDPI virtual displays, IOKit, CoreGraphics private APIs, Keychain. If it's useful to you too, great.


## License

MIT — see [LICENSE](LICENSE).
