import Foundation
import IOKit.ps
import Testing
@testable import battery_kawaii

@MainActor
struct LocalizationTests {
    private var appBundle: Bundle { Bundle(for: BatteryMonitor.self) }

    @Test func appSupportsSystemLanguageSelection() {
        #expect(appBundle.localizations.contains("en"))
        #expect(appBundle.localizations.contains("ja"))
        #expect(appBundle.developmentLocalization == "en")
        #expect(Bundle.preferredLocalizations(from: appBundle.localizations, forPreferences: ["ja-JP", "en-US"]).first == "ja")
        #expect(Bundle.preferredLocalizations(from: appBundle.localizations, forPreferences: ["en-GB", "ja-JP"]).first == "en")
        #expect(Bundle.preferredLocalizations(from: appBundle.localizations, forPreferences: ["fr-FR", "ja-JP", "en-US"]).first == "ja")
    }

    @Test(arguments: ["en", "ja"])
    func translatedFormatsPreserveValuesAndPluralForms(language: String) throws {
        let path = try #require(appBundle.path(forResource: language, ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        let locale = Locale(identifier: language)
        let japanese = language == "ja"

        for count in [0, 1, 2, 123] {
            let actual = String(localized: "\(count) cycles", bundle: bundle, locale: locale)
            let expected = japanese ? "\(count)回" : "\(count) \(count == 1 ? "cycle" : "cycles")"
            #expect(actual == expected)
        }

        let hours = 2
        let minutes = 5
        #expect(String(localized: "\(hours) hr \(minutes) min remaining", bundle: bundle, locale: locale)
                == (japanese ? "残り2時間5分" : "2 hr 5 min remaining"))
        #expect(String(localized: "\(hours) hr \(minutes) min until full", bundle: bundle, locale: locale)
                == (japanese ? "完了まで2時間5分" : "2 hr 5 min until full"))

        let name = String(localized: "Cat", bundle: bundle, locale: locale)
        #expect(String(localized: "Show \(name) in the menu bar", bundle: bundle, locale: locale)
                == (japanese ? "ねこをメニューバーに表示" : "Show Cat in the menu bar"))
    }

    // XcodeのTest Languageを切り替え、実際に選ばれたアプリ言語で表示値を検証する。
    @Test func displayedStringsFollowTheAppLanguage() {
        let japanese = appBundle.preferredLocalizations.first == "ja"
        var info: [String: Any] = [
            kIOPSCurrentCapacityKey: 70,
            kIOPSIsChargingKey: false,
            kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
            kIOPSTimeToEmptyKey: 120,
            kIOPSTimeToFullChargeKey: 45
        ]
        let monitor = BatteryMonitor(automaticallyMonitors: false, powerSourceProvider: { info })
        monitor.updateBatteryInfo()
        #expect(monitor.statusText == (japanese ? "バッテリー駆動" : "On battery power"))
        #expect(monitor.timeRemainingText == (japanese ? "残り2時間0分" : "2 hr 0 min remaining"))
        #expect(monitor.batteryHealth == (japanese ? "不明" : "Unknown"))

        info[kIOPSIsChargingKey] = true
        info[kIOPSPowerSourceStateKey] = kIOPSACPowerValue
        monitor.updateBatteryInfo()
        #expect(monitor.statusText == (japanese ? "充電中" : "Charging"))
        #expect(monitor.timeRemainingText == (japanese ? "完了まで0時間45分" : "0 hr 45 min until full"))

        info[kIOPSIsChargingKey] = false
        monitor.updateBatteryInfo()
        #expect(monitor.statusText == (japanese ? "電源接続中" : "Power adapter connected"))
        #expect(monitor.timeRemainingText == "—")

        info[kIOPSCurrentCapacityKey] = 100
        monitor.updateBatteryInfo()
        #expect(monitor.statusText == (japanese ? "完全充電済み" : "Fully charged"))
        #expect(monitor.timeRemainingText == (japanese ? "充電完了" : "Charge complete"))

        info[kIOPSPowerSourceStateKey] = kIOPSBatteryPowerValue
        info[kIOPSTimeToEmptyKey] = nil
        monitor.updateBatteryInfo()
        #expect(monitor.timeRemainingText == (japanese ? "計算中…" : "Calculating…"))

        let names = BatteryDesign.allCases.map(\.name)
        #expect(names == (japanese ? ["クラシック", "ねこ", "うさぎ", "くま", "ロボット", "ピクセル"]
                                  : ["Classic", "Cat", "Bunny", "Bear", "Robot", "Pixel"]))
        #expect(MenuBarLabel(batteryLevel: 70, isCharging: false, design: .cat).accessibilityDescription
                == (japanese ? "バッテリー 70%、ねこ" : "Battery 70%, Cat"))
        #expect(MenuBarLabel(batteryLevel: 70, isCharging: true, design: .cat).accessibilityDescription
                == (japanese ? "バッテリー 70%、ねこ、充電中" : "Battery 70%, Cat, charging"))
    }
}
