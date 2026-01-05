//
//  BatteryCharacterView.swift
//  battery-kawaii
//
//  Created by 布川のぞみ on 2026/01/05.
//

import SwiftUI
import AppKit

// MARK: - SwiftUI View を NSImage に変換する拡張
extension View {
    @MainActor
    func renderAsImage(size: CGSize) -> NSImage {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = 2.0  // Retina対応

        if let cgImage = renderer.cgImage {
            return NSImage(cgImage: cgImage, size: size)
        }
        return NSImage()
    }
}

// MARK: - メニューバー用の Image を生成
struct MenuBarCharacterProvider {
    @MainActor
    static func getImage(batteryLevel: Int, isCharging: Bool) -> Image {
        let view = BatteryCharacterView(batteryLevel: batteryLevel, isCharging: isCharging)
        let nsImage = view.renderAsImage(size: CGSize(width: 18, height: 22))
        nsImage.isTemplate = false  // カラーで表示
        return Image(nsImage: nsImage)
    }
}

struct BatteryCharacterView: View {
    let batteryLevel: Int
    let isCharging: Bool

    var body: some View {
        ZStack {
            // バッテリー本体
            BatteryBody(fillLevel: batteryLevel, color: batteryColor)

            // 顔
            VStack(spacing: 1) {
                // 目
                HStack(spacing: 3) {
                    EyeView(style: eyeStyle)
                    EyeView(style: eyeStyle)
                }

                // 口
                MouthView(style: mouthStyle)
            }
            .offset(y: -1)
        }
        .frame(width: 18, height: 22)
    }

    // 残量に応じた色
    var batteryColor: Color {
        if isCharging {
            return .green
        }
        switch batteryLevel {
        case 0...20:
            return .red
        case 21...50:
            return .orange
        default:
            return .green
        }
    }

    // 目のスタイル
    var eyeStyle: EyeStyle {
        if isCharging {
            return .heart
        }
        if batteryLevel >= 100 {
            return .star
        }
        switch batteryLevel {
        case 0...20:
            return .dizzy
        case 21...50:
            return .tired
        case 51...80:
            return .normal
        default:
            return .sparkle
        }
    }

    // 口のスタイル
    var mouthStyle: MouthStyle {
        if isCharging || batteryLevel >= 100 {
            return .happy
        }
        switch batteryLevel {
        case 0...20:
            return .worried
        case 21...50:
            return .wavy
        case 51...80:
            return .neutral
        default:
            return .happy
        }
    }
}

// MARK: - バッテリー本体
struct BatteryBody: View {
    let fillLevel: Int
    let color: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            // バッテリー外枠
            VStack(spacing: 0) {
                // 突起部分
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 6, height: 2)

                // 本体
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.primary.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 14, height: 18)
            }

            // 残量表示（塗りつぶし）
            VStack(spacing: 0) {
                Spacer().frame(height: 2) // 突起分のオフセット
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.clear)
                        .frame(width: 12, height: 16)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.3))
                        .frame(width: 12, height: max(2, 16 * CGFloat(fillLevel) / 100))
                }
            }
        }
    }
}

// MARK: - 目のスタイル
enum EyeStyle {
    case sparkle  // キラキラ ◉
    case normal   // 普通 ・
    case tired    // 疲れ 一
    case dizzy    // 目が回る ×
    case heart    // ハート ♡
    case star     // 星 ★
}

struct EyeView: View {
    let style: EyeStyle

    var body: some View {
        switch style {
        case .sparkle:
            Circle()
                .fill(Color.primary)
                .frame(width: 3, height: 3)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 1, height: 1)
                        .offset(x: -0.5, y: -0.5)
                )
        case .normal:
            Circle()
                .fill(Color.primary)
                .frame(width: 2, height: 2)
        case .tired:
            RoundedRectangle(cornerRadius: 0.5)
                .fill(Color.primary)
                .frame(width: 3, height: 1)
        case .dizzy:
            Text("×")
                .font(.system(size: 5, weight: .bold))
                .foregroundColor(.primary)
        case .heart:
            Text("♥")
                .font(.system(size: 5))
                .foregroundColor(.pink)
        case .star:
            Text("★")
                .font(.system(size: 5))
                .foregroundColor(.yellow)
        }
    }
}

// MARK: - 口のスタイル
enum MouthStyle {
    case happy    // 笑顔 ∪
    case neutral  // 普通 ー
    case wavy     // 困り 〜
    case worried  // 焦り △
}

struct MouthView: View {
    let style: MouthStyle

    var body: some View {
        switch style {
        case .happy:
            // 笑顔（U字型）
            Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                .stroke(Color.primary, lineWidth: 1)
                .frame(width: 4, height: 2)
        case .neutral:
            // 普通（横線）
            RoundedRectangle(cornerRadius: 0.5)
                .fill(Color.primary)
                .frame(width: 4, height: 1)
        case .wavy:
            // 困り顔（波線）
            WavyLine()
                .stroke(Color.primary, lineWidth: 1)
                .frame(width: 5, height: 2)
        case .worried:
            // 焦り（小さい三角）
            Triangle()
                .fill(Color.primary)
                .frame(width: 4, height: 2)
        }
    }
}

// MARK: - カスタムシェイプ
struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width / 2, y: rect.midY),
            control: CGPoint(x: rect.width / 4, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.midY),
            control: CGPoint(x: rect.width * 3 / 4, y: rect.height)
        )
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            VStack {
                BatteryCharacterView(batteryLevel: 100, isCharging: false)
                Text("100%")
            }
            VStack {
                BatteryCharacterView(batteryLevel: 70, isCharging: false)
                Text("70%")
            }
            VStack {
                BatteryCharacterView(batteryLevel: 40, isCharging: false)
                Text("40%")
            }
            VStack {
                BatteryCharacterView(batteryLevel: 15, isCharging: false)
                Text("15%")
            }
        }
        HStack(spacing: 20) {
            VStack {
                BatteryCharacterView(batteryLevel: 50, isCharging: true)
                Text("充電中")
            }
        }
    }
    .padding()
}
