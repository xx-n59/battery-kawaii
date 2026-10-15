# battery-kawaii

[日本語](README.md) | **English**

A macOS menu bar app that displays your battery level alongside a character whose expression changes with its charge. Built with SwiftUI and IOKit.

## Features

- **Battery level and charging status**: Check your battery at a glance in the menu bar.
- **Expressive characters**: Heart-shaped eyes while charging, star-shaped eyes at full charge, and tired expressions as the battery runs low.
- **Six designs**: Choose Classic, Cat, Bunny, Bear, Robot, or Pixel. Your selection is saved across app launches.
- **Battery details**: View the estimated time remaining or time to full charge, battery health, and cycle count.
- **Dark mode support**: Colors adapt to your macOS appearance settings.
- **Japanese and English**: The interface follows your macOS language preferences.

## Requirements

- macOS 15.4 or later
- A Mac with a built-in battery, such as a MacBook Air or MacBook Pro
- To build the app: Xcode with the macOS 15.4 SDK or later

No third-party dependencies are required. Battery information is read from your Mac. The availability of time estimates, battery health, and other details depends on the hardware and the information provided by macOS.

## Build and run

1. Clone the repository and open the project in Xcode.

   ```sh
   git clone https://github.com/xx-n59/battery-kawaii.git
   cd battery-kawaii
   open battery-kawaii.xcodeproj
   ```

2. Select the `battery-kawaii` scheme and the `My Mac` run destination.
3. If Xcode asks for signing configuration, select your development team under the app target's **Signing & Capabilities** tab.
4. Press `⌘R` to build and run.

The character and battery percentage appear in the menu bar. The app does not open a regular app window or show a Dock icon.

## Usage

1. Click the character or battery percentage in the menu bar to open the details panel.
2. Choose a character under **Design**. The menu bar updates immediately.
3. Click **Quit** in the details panel to close the app.

## Language support

The app and README support Japanese and English. The app automatically selects a supported language in the order of your macOS preferred languages. It falls back to English if neither Japanese nor English is in that list.

If you set a language specifically for this app in macOS **Language & Region**, that setting takes priority. Quit and reopen the app after changing language settings. Your selected character design is preserved.

## Development

The main source files are:

| File | Purpose |
| --- | --- |
| [battery_kawaiiApp.swift](battery-kawaii/battery_kawaiiApp.swift) | App entry point, menu bar display, and saved design preference |
| [BatteryMonitor.swift](battery-kawaii/BatteryMonitor.swift) | Battery data retrieval and monitoring |
| [BatteryCharacterView.swift](battery-kawaii/BatteryCharacterView.swift) | Character and expression rendering, and menu bar image caching |
| [BatteryDesign.swift](battery-kawaii/BatteryDesign.swift) | Design definitions and the design picker |
| [BatteryDetailView.swift](battery-kawaii/BatteryDetailView.swift) | Battery details panel |
| [Localizable.xcstrings](battery-kawaii/Localizable.xcstrings) | Japanese and English translations and plural forms |
| [battery_kawaiiTests.swift](battery-kawaiiTests/battery_kawaiiTests.swift) | Unit tests for monitoring and image caching |
| [LocalizationTests.swift](battery-kawaiiTests/LocalizationTests.swift) | Tests for language selection, translations, time, and cycle counts |

To limit background work, the app normally updates in response to power-source change notifications. It falls back to polling every 60 seconds only if notification registration fails. Battery health and cycle count are fetched when the details panel opens and cached for five minutes.

### Tests

Run the following command from the repository root. Adjust `DEVELOPER_DIR` if Xcode is installed elsewhere.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project battery-kawaii.xcodeproj \
  -scheme battery-kawaii \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/battery-kawaii-build \
  -only-testing:battery-kawaiiTests \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual
```

This command checks monitoring lifecycle, updates only when values change, battery-detail caching, remaining-time logic, and image caching across appearance and design changes. Actual battery readings and UI interactions require separate checks on a Mac.

To check a specific language, add `-testLanguage ja -testRegion JP` or `-testLanguage en -testRegion US` to the command above. Translations are maintained in `Localizable.xcstrings`. To add a language, add its translations and include it in the project's supported languages.
