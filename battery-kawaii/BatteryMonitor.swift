//
//  BatteryMonitor.swift
//  battery-kawaii
//
//  Created by 布川のぞみ on 2026/01/04.
//

import Foundation
import Combine
import IOKit.ps

@MainActor
final class BatteryMonitor: ObservableObject {
    struct BatteryDetails {
        var cycleCount: Int? = nil
        var health: String = String(localized: "Unknown")
    }

    @Published private(set) var batteryLevel: Int = 100
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isPluggedIn: Bool = false
    @Published private(set) var timeRemaining: Int? = nil
    @Published private(set) var cycleCount: Int? = nil
    @Published private(set) var batteryHealth: String = String(localized: "Unknown")

    private var notificationSource: CFRunLoopSource?
    private var fallbackTimer: Timer?
    private var lastDetailsUpdate: TimeInterval?
    private let powerSourceProvider: () -> [String: Any]?
    private let detailsProvider: () -> BatteryDetails

    init(
        automaticallyMonitors: Bool = true,
        powerSourceProvider: @escaping () -> [String: Any]? = BatteryMonitor.readPowerSourceInfo,
        detailsProvider: @escaping () -> BatteryDetails = BatteryMonitor.readBatteryDetails
    ) {
        self.powerSourceProvider = powerSourceProvider
        self.detailsProvider = detailsProvider
        if automaticallyMonitors {
            startMonitoring()
        }
    }

    deinit {
        if let notificationSource {
            CFRunLoopSourceInvalidate(notificationSource)
        }
        fallbackTimer?.invalidate()
    }

    func startMonitoring() {
        guard notificationSource == nil, fallbackTimer == nil else { return }

        // メインRunLoop上で電源情報の変更時だけ読み直す。
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            MainActor.assumeIsolated {
                let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.updateBatteryInfo()
            }
        }, context)?.takeRetainedValue() {
            notificationSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        } else {
            // 通知を登録できなかった場合だけ低頻度のタイマーを使う。
            let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.updateBatteryInfo()
                }
            }
            timer.tolerance = 10
            fallbackTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }

        updateBatteryInfo()
    }

    func stopMonitoring() {
        if let notificationSource {
            CFRunLoopSourceInvalidate(notificationSource)
            self.notificationSource = nil
        }
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    func updateBatteryInfo() {
        guard let info = powerSourceProvider() else { return }

        // 同じ値をPublishedに代入すると再描画が発生するので、変更時だけ通知する。
        if let capacity = info[kIOPSCurrentCapacityKey] as? Int, batteryLevel != capacity {
            batteryLevel = capacity
        }
        if let charging = info[kIOPSIsChargingKey] as? Bool, isCharging != charging {
            isCharging = charging
        }
        if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
            let pluggedIn = powerSource == kIOPSACPowerValue
            if isPluggedIn != pluggedIn {
                isPluggedIn = pluggedIn
            }
        }

        let minutes: Int?
        if isCharging {
            minutes = info[kIOPSTimeToFullChargeKey] as? Int
        } else if !isPluggedIn {
            minutes = info[kIOPSTimeToEmptyKey] as? Int
        } else {
            minutes = nil
        }
        let remaining = minutes.flatMap { $0 >= 0 ? $0 : nil }
        if timeRemaining != remaining {
            timeRemaining = remaining
        }
    }

    // 詳細画面を開いたときだけ取得する。短時間の開閉では再取得しない。
    func refreshBatteryDetailsIfNeeded(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        if let lastDetailsUpdate, uptime - lastDetailsUpdate < 300 { return }
        let details = detailsProvider()
        lastDetailsUpdate = uptime
        if cycleCount != details.cycleCount {
            cycleCount = details.cycleCount
        }
        if batteryHealth != details.health {
            batteryHealth = details.health
        }
    }

    nonisolated private static func readPowerSourceInfo() -> [String: Any]? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
               info[kIOPSTypeKey] as? String == kIOPSInternalBatteryType {
                return info
            }
        }
        return nil
    }

    nonisolated private static func readBatteryDetails() -> BatteryDetails {
        // サイクル数と健康度で同じサービスを共有し、取得・解放は一度にまとめる。
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return BatteryDetails() }
        defer { IOObjectRelease(service) }

        func integerProperty(_ key: String) -> Int? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? Int
        }

        var details = BatteryDetails(cycleCount: integerProperty("CycleCount"))
        #if arch(arm64)
        let maxCapacity = integerProperty("AppleRawMaxCapacity") ?? integerProperty("NominalChargeCapacity")
        #else
        let maxCapacity = integerProperty("MaxCapacity")
        #endif
        if let maxCapacity, maxCapacity > 0,
           let designCapacity = integerProperty("DesignCapacity"), designCapacity > 0 {
            let percent = min(100, Double(maxCapacity) / Double(designCapacity) * 100)
            details.health = "\(Int(percent.rounded()))%"
        }
        return details
    }

    var batteryIcon: String {
        if isCharging {
            return "battery.100percent.bolt"
        }

        switch batteryLevel {
        case 0...10:
            return "battery.0percent"
        case 11...25:
            return "battery.25percent"
        case 26...50:
            return "battery.50percent"
        case 51...75:
            return "battery.75percent"
        default:
            return "battery.100percent"
        }
    }

    var statusText: String {
        if isCharging {
            return String(localized: "Charging")
        } else if isPluggedIn && batteryLevel >= 100 {
            return String(localized: "Fully charged")
        } else if isPluggedIn {
            return String(localized: "Power adapter connected")
        } else {
            return String(localized: "On battery power")
        }
    }

    var timeRemainingText: String {
        if isPluggedIn && !isCharging {
            return batteryLevel >= 100 ? String(localized: "Charge complete") : "—"
        }
        guard let minutes = timeRemaining else {
            return String(localized: "Calculating…")
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if isCharging {
            return String(localized: "\(hours) hr \(mins) min until full", comment: "Estimated time until the battery is fully charged. Arguments are hours and minutes.")
        } else {
            return String(localized: "\(hours) hr \(mins) min remaining", comment: "Estimated battery runtime. Arguments are hours and minutes.")
        }
    }
}
