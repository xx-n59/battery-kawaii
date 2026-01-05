//
//  BatteryMonitor.swift
//  battery-kawaii
//
//  Created by 布川のぞみ on 2026/01/04.
//

import Foundation
import IOKit.ps

class BatteryMonitor: ObservableObject {
    @Published var batteryLevel: Int = 100
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var timeRemaining: Int? = nil
    @Published var cycleCount: Int? = nil
    @Published var batteryHealth: String = "不明"

    private var timer: Timer?

    init() {
        updateBatteryInfo()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateBatteryInfo()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func updateBatteryInfo() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int {
                self.batteryLevel = currentCapacity
            }

            if let isCharging = info[kIOPSIsChargingKey] as? Bool {
                self.isCharging = isCharging
            }

            if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
                self.isPluggedIn = (powerSource == kIOPSACPowerValue)
            }

            if let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int, timeToEmpty > 0 {
                self.timeRemaining = timeToEmpty
            } else if let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
                self.timeRemaining = timeToFull
            } else {
                self.timeRemaining = nil
            }

            self.cycleCount = self.getCycleCount()
            self.batteryHealth = self.getBatteryHealth()
        }
    }

    private func getCycleCount() -> Int? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOServiceClose(service) }

        if let cycleCountRef = IORegistryEntryCreateCFProperty(service, "CycleCount" as CFString, kCFAllocatorDefault, 0) {
            return cycleCountRef.takeRetainedValue() as? Int
        }
        return nil
    }

    private func getBatteryHealth() -> String {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return "不明" }
        defer { IOServiceClose(service) }

        if let maxCapacityRef = IORegistryEntryCreateCFProperty(service, "MaxCapacity" as CFString, kCFAllocatorDefault, 0),
           let designCapacityRef = IORegistryEntryCreateCFProperty(service, "DesignCapacity" as CFString, kCFAllocatorDefault, 0) {
            let maxCapacity = maxCapacityRef.takeRetainedValue() as? Int ?? 0
            let designCapacity = designCapacityRef.takeRetainedValue() as? Int ?? 1
            let healthPercent = (maxCapacity * 100) / designCapacity
            return "\(healthPercent)%"
        }
        return "不明"
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
            return "充電中"
        } else if isPluggedIn && batteryLevel >= 100 {
            return "完全充電済み"
        } else if isPluggedIn {
            return "電源接続中"
        } else {
            return "バッテリー駆動"
        }
    }

    var timeRemainingText: String {
        guard let minutes = timeRemaining else {
            return "計算中..."
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if isCharging {
            return "完了まで \(hours)時間\(mins)分"
        } else {
            return "残り \(hours)時間\(mins)分"
        }
    }
}
