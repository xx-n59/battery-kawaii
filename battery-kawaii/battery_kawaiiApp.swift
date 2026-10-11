//
//  battery_kawaiiApp.swift
//  battery-kawaii
//
//  Created by 布川のぞみ on 2026/01/04.
//

import SwiftUI

@main
@MainActor
struct battery_kawaiiApp: App {
    @StateObject private var batteryMonitor = BatteryMonitor()

    var body: some Scene {
        MenuBarExtra {
            BatteryDetailView(monitor: batteryMonitor)
        } label: {
            MenuBarLabel(batteryLevel: batteryMonitor.batteryLevel, isCharging: batteryMonitor.isCharging)
        }
        .menuBarExtraStyle(.window)
    }
}

// メニューバー用のラベル
struct MenuBarLabel: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    let batteryLevel: Int
    let isCharging: Bool

    var body: some View {
        HStack(spacing: 3) {
            MenuBarCharacterProvider.getImage(batteryLevel: batteryLevel, isCharging: isCharging, colorScheme: colorScheme, scale: displayScale)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 18)

            Text("\(batteryLevel)%")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
    }
}
