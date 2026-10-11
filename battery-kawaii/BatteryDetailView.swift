//
//  BatteryDetailView.swift
//  battery-kawaii
//
//  Created by 布川のぞみ on 2026/01/04.
//

import SwiftUI

struct BatteryDetailView: View {
    @ObservedObject var monitor: BatteryMonitor
    @Binding var design: BatteryDesign

    var body: some View {
        VStack(spacing: 16) {
            // バッテリーアイコンと残量
            HStack(spacing: 12) {
                BatteryCharacterView(batteryLevel: monitor.batteryLevel, isCharging: monitor.isCharging, design: design, size: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(monitor.batteryLevel)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(batteryColor)

                    Text(monitor.statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)

            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray)
                        .frame(width: geometry.size.width * CGFloat(monitor.batteryLevel) / 100, height: 12)
                        .animation(.easeInOut(duration: 0.5), value: monitor.batteryLevel)
                }
            }
            .frame(height: 12)
            .padding(.horizontal)

            Divider()

            // 詳細情報
            VStack(spacing: 8) {
                DetailRow(title: "残り時間", value: monitor.timeRemainingText)
                DetailRow(title: "バッテリー健康状態", value: monitor.batteryHealth)
                if let cycles = monitor.cycleCount {
                    DetailRow(title: "サイクルカウント", value: "\(cycles)回")
                }
            }
            .padding(.horizontal)

            Divider()

            BatteryDesignPicker(selection: $design, batteryLevel: monitor.batteryLevel, isCharging: monitor.isCharging)
                .padding(.horizontal)

            Divider()

            // 終了ボタン
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("終了")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 8)
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            monitor.refreshBatteryDetailsIfNeeded()
        }
    }

    var batteryColor: Color {
        switch monitor.batteryLevel {
        case 0...20:
            return .red
        case 21...50:
            return .orange
        default:
            return .green
        }
    }

    var batteryGradient: LinearGradient {
        switch monitor.batteryLevel {
        case 0...20:
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        case 21...50:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.system(size: 13))
    }
}

#Preview {
    BatteryDetailView(monitor: BatteryMonitor(), design: .constant(.classic))
}
