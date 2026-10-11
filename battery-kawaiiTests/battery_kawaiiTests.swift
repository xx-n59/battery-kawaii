//
//  battery_kawaiiTests.swift
//  battery-kawaiiTests
//
//  Created by 布川のぞみ on 2026/01/04.
//

import Testing
import Combine
import IOKit.ps
import SwiftUI
@testable import battery_kawaii

@MainActor
struct battery_kawaiiTests {
    private static func powerInfo() -> [String: Any] {
        [
            kIOPSCurrentCapacityKey: 70,
            kIOPSIsChargingKey: false,
            kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
            kIOPSTimeToEmptyKey: 120,
            kIOPSTimeToFullChargeKey: 45
        ]
    }

    @Test func unchangedPowerInfoDoesNotPublish() {
        var info = Self.powerInfo()
        let monitor = BatteryMonitor(automaticallyMonitors: false, powerSourceProvider: { info })
        monitor.updateBatteryInfo()

        var changes = 0
        let subscription = monitor.objectWillChange.sink { changes += 1 }
        withExtendedLifetime(subscription) {
            for _ in 0..<100 {
                monitor.updateBatteryInfo()
            }
            #expect(changes == 0)

            info[kIOPSTimeToEmptyKey] = 119
            monitor.updateBatteryInfo()
            #expect(changes == 1)
            #expect(monitor.timeRemaining == 119)
        }
    }

    @Test func detailsAreLazyAndCachedForFiveMinutes() {
        var reads = 0
        let monitor = BatteryMonitor(
            automaticallyMonitors: false,
            powerSourceProvider: { Self.powerInfo() },
            detailsProvider: {
                reads += 1
                return .init(cycleCount: 123, health: "95%")
            }
        )
        for _ in 0..<100 {
            monitor.updateBatteryInfo()
        }
        #expect(reads == 0)

        monitor.refreshBatteryDetailsIfNeeded(at: 100)
        #expect(reads == 1)
        #expect(monitor.cycleCount == 123)
        #expect(monitor.batteryHealth == "95%")

        monitor.refreshBatteryDetailsIfNeeded(at: 399)
        #expect(reads == 1)

        var changes = 0
        let subscription = monitor.objectWillChange.sink { changes += 1 }
        withExtendedLifetime(subscription) {
            monitor.refreshBatteryDetailsIfNeeded(at: 400)
            #expect(reads == 2)
            #expect(changes == 0)
        }
    }

    @Test func unavailableDetailsAreAlsoCached() {
        var reads = 0
        let monitor = BatteryMonitor(automaticallyMonitors: false, detailsProvider: {
            reads += 1
            return .init()
        })
        monitor.refreshBatteryDetailsIfNeeded(at: 100)
        monitor.refreshBatteryDetailsIfNeeded(at: 101)
        #expect(reads == 1)
        #expect(monitor.cycleCount == nil)
        #expect(monitor.batteryHealth == "不明")
    }

    @Test func chargingStateSelectsTheCorrectTime() {
        var info = Self.powerInfo()
        let monitor = BatteryMonitor(automaticallyMonitors: false, powerSourceProvider: { info })
        monitor.updateBatteryInfo()
        #expect(monitor.timeRemaining == 120)

        info[kIOPSIsChargingKey] = true
        info[kIOPSPowerSourceStateKey] = kIOPSACPowerValue
        monitor.updateBatteryInfo()
        #expect(monitor.timeRemaining == 45)

        info[kIOPSIsChargingKey] = false
        monitor.updateBatteryInfo()
        #expect(monitor.timeRemaining == nil)
        #expect(monitor.timeRemainingText == "—")

        info[kIOPSCurrentCapacityKey] = 100
        monitor.updateBatteryInfo()
        #expect(monitor.timeRemainingText == "充電完了")
    }

    @Test func monitoringCanRestartAndDoesNotRetainTheMonitor() {
        var reads = 0
        var monitor: BatteryMonitor? = BatteryMonitor(powerSourceProvider: {
            reads += 1
            return Self.powerInfo()
        })
        weak var weakMonitor = monitor
        #expect(reads == 1)
        monitor?.startMonitoring()
        #expect(reads == 1)
        monitor?.stopMonitoring()
        monitor?.stopMonitoring()
        monitor?.startMonitoring()
        #expect(reads == 2)
        monitor = nil
        #expect(weakMonitor == nil)
    }

    @Test func menuBarImageCacheTracksAppearanceAndKeepsOnlyTheLatestImage() {
        let original = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: false, colorScheme: .light, scale: 2)
        let repeated = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: false, colorScheme: .light, scale: 2)
        #expect(original === repeated)

        let differentLevel = MenuBarCharacterProvider.getNSImage(batteryLevel: 69, isCharging: false, colorScheme: .light, scale: 2)
        #expect(original !== differentLevel)
        let originalAgain = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: false, colorScheme: .light, scale: 2)
        #expect(original !== originalAgain)

        let charging = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: true, colorScheme: .light, scale: 2)
        #expect(originalAgain !== charging)
        let dark = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: true, colorScheme: .dark, scale: 2)
        #expect(charging !== dark)
        let smaller = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: true, colorScheme: .dark, scale: 1)
        #expect(dark !== smaller)

        // 残量が変わらなくても、デザイン選択ですぐ画像が切り替わる。
        var previous = smaller
        for design in BatteryDesign.allCases where design != .classic {
            let selected = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: true, colorScheme: .dark, scale: 1, design: design)
            #expect(previous !== selected)
            #expect(previous.tiffRepresentation != selected.tiffRepresentation)
            let repeated = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: true, colorScheme: .dark, scale: 1, design: design)
            #expect(selected === repeated)
            previous = selected
        }
        let restored = MenuBarCharacterProvider.getNSImage(batteryLevel: 70, isCharging: true, colorScheme: .dark, scale: 1, design: .classic)
        #expect(previous !== restored)
        #expect(smaller.tiffRepresentation == restored.tiffRepresentation)
    }
}
