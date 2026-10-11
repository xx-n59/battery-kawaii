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
    func renderAsImage(size: CGSize, scale: CGFloat) -> NSImage {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = scale

        if let cgImage = renderer.cgImage {
            return NSImage(cgImage: cgImage, size: size)
        }
        return NSImage()
    }
}

// MARK: - メニューバー用の Image を生成
@MainActor
struct MenuBarCharacterProvider {
    private struct CacheKey: Equatable {
        let batteryLevel: Int
        let isCharging: Bool
        let colorScheme: ColorScheme
        let scale: CGFloat
        let design: BatteryDesign
    }

    // 直近の一枚だけ保持し、残り時間などの更新で画像を作り直さない。
    private static var cachedImage: (key: CacheKey, image: NSImage)?

    static func getImage(batteryLevel: Int, isCharging: Bool, colorScheme: ColorScheme, scale: CGFloat, design: BatteryDesign = .classic) -> Image {
        Image(nsImage: getNSImage(batteryLevel: batteryLevel, isCharging: isCharging, colorScheme: colorScheme, scale: scale, design: design))
    }

    static func getNSImage(batteryLevel: Int, isCharging: Bool, colorScheme: ColorScheme, scale: CGFloat, design: BatteryDesign = .classic) -> NSImage {
        let key = CacheKey(batteryLevel: batteryLevel, isCharging: isCharging, colorScheme: colorScheme, scale: scale, design: design)
        if let cachedImage, cachedImage.key == key {
            return cachedImage.image
        }
        let view = BatteryCharacterView(batteryLevel: batteryLevel, isCharging: isCharging, design: design)
            .environment(\.colorScheme, colorScheme)
        let nsImage = view.renderAsImage(size: CGSize(width: 18, height: 22), scale: scale)
        nsImage.isTemplate = false  // カラーで表示
        cachedImage = (key, nsImage)
        return nsImage
    }
}

struct BatteryCharacterView: View {
    let batteryLevel: Int
    let isCharging: Bool
    var design: BatteryDesign = .classic
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            // バッテリー本体
            BatteryBody(fillLevel: batteryLevel, color: batteryColor, design: design)

            faceDecoration

            // 顔
            VStack(spacing: 1) {
                // 目
                HStack(spacing: 3) {
                    EyeView(style: eyeStyle, isPixel: design == .pixel)
                    EyeView(style: eyeStyle, isPixel: design == .pixel)
                }

                // 口
                MouthView(style: mouthStyle, isPixel: design == .pixel)
            }
            .offset(y: design == .classic ? -1 : 1)
        }
        .frame(width: 18, height: 22)
        .scaleEffect(size / 22)
        .frame(width: 18 * size / 22, height: size)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var faceDecoration: some View {
        switch design {
        case .cat:
            Path { path in
                for x: CGFloat in [1, 14] {
                    path.move(to: CGPoint(x: x, y: 13))
                    path.addLine(to: CGPoint(x: x + 3, y: 13.5))
                    path.move(to: CGPoint(x: x, y: 15))
                    path.addLine(to: CGPoint(x: x + 3, y: 14.5))
                }
            }
            .stroke(Color.primary.opacity(0.8), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
        case .bunny, .bear:
            HStack(spacing: 8) {
                Ellipse().fill(Color.pink.opacity(0.5))
                Ellipse().fill(Color.pink.opacity(0.5))
            }
            .frame(width: 13, height: 1.8)
            .offset(y: 3)
        case .robot:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.primary.opacity(0.08))
                .frame(width: 11, height: 7)
                .offset(y: 0.5)
        case .classic, .pixel:
            EmptyView()
        }
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
            return design.accentColor
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
    let design: BatteryDesign

    var body: some View {
        ZStack {
            decorations

            BatteryShell(design: design)
                .fill(color.opacity(0.06))

            // 全デザインで下から残量を表示する。耳などの飾りは残量に含めない。
            Rectangle()
                .fill(color.opacity(0.35))
                .frame(width: 18, height: fillHeight)
                .position(x: 9, y: 21 - fillHeight / 2)
                .clipShape(BatteryShell(design: design))

            BatteryShell(design: design)
                .stroke(Color.primary.opacity(0.65), style: StrokeStyle(lineWidth: 1.2, lineJoin: design == .pixel ? .miter : .round))
        }
        .frame(width: 18, height: 22)
    }

    private var fillHeight: CGFloat {
        16 * CGFloat(min(100, max(0, fillLevel))) / 100
    }

    @ViewBuilder
    private var decorations: some View {
        switch design {
        case .classic, .pixel:
            RoundedRectangle(cornerRadius: design == .pixel ? 0 : 1)
                .fill(Color.primary.opacity(0.65))
                .frame(width: 6, height: 2)
                .position(x: 9, y: 3)
        case .cat:
            HStack(spacing: 6) {
                Triangle().fill(Color.pink.opacity(0.5))
                Triangle().fill(Color.pink.opacity(0.5))
            }
            .frame(width: 12, height: 3)
            .position(x: 9, y: 4.5)
        case .bunny:
            ForEach([5.0, 13.0], id: \.self) { x in
                Capsule()
                    .fill(color.opacity(0.18))
                    .overlay { Capsule().stroke(Color.primary.opacity(0.65), lineWidth: 1.1) }
                    .overlay { Capsule().fill(Color.pink.opacity(0.4)).frame(width: 1.2, height: 3.5) }
                    .frame(width: 3.5, height: 7)
                    .rotationEffect(.degrees(x < 9 ? -8 : 8))
                    .position(x: x, y: 4.2)
            }
        case .bear:
            ForEach([4.0, 14.0], id: \.self) { x in
                Circle()
                    .fill(color.opacity(0.3))
                    .overlay { Circle().stroke(Color.primary.opacity(0.65), lineWidth: 1.1) }
                    .overlay { Circle().fill(color.opacity(0.4)).padding(1.5) }
                    .frame(width: 5, height: 5)
                    .position(x: x, y: 4)
            }
        case .robot:
            Path { path in
                path.move(to: CGPoint(x: 9, y: 2))
                path.addLine(to: CGPoint(x: 9, y: 5))
            }
            .stroke(Color.primary.opacity(0.65), lineWidth: 1)
            Circle().fill(color).frame(width: 2.5, height: 2.5).position(x: 9, y: 1.8)
            ForEach([1.0, 17.0], id: \.self) { x in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.primary.opacity(0.65))
                    .frame(width: 1.5, height: 5)
                    .position(x: x, y: 12)
            }
        }
    }
}

private struct BatteryShell: Shape {
    let design: BatteryDesign

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch design {
        case .cat:
            path.move(to: CGPoint(x: 2, y: 18))
            path.addLine(to: CGPoint(x: 2, y: 2))
            path.addLine(to: CGPoint(x: 6.5, y: 6))
            path.addQuadCurve(to: CGPoint(x: 11.5, y: 6), control: CGPoint(x: 9, y: 5))
            path.addLine(to: CGPoint(x: 16, y: 2))
            path.addLine(to: CGPoint(x: 16, y: 18))
            path.addQuadCurve(to: CGPoint(x: 13, y: 21), control: CGPoint(x: 16, y: 21))
            path.addLine(to: CGPoint(x: 5, y: 21))
            path.addQuadCurve(to: CGPoint(x: 2, y: 18), control: CGPoint(x: 2, y: 21))
            path.closeSubpath()
        case .pixel:
            path.move(to: CGPoint(x: 4, y: 5))
            for point in [CGPoint(x: 14, y: 5), CGPoint(x: 14, y: 7), CGPoint(x: 16, y: 7),
                          CGPoint(x: 16, y: 19), CGPoint(x: 14, y: 19), CGPoint(x: 14, y: 21),
                          CGPoint(x: 4, y: 21), CGPoint(x: 4, y: 19), CGPoint(x: 2, y: 19),
                          CGPoint(x: 2, y: 7), CGPoint(x: 4, y: 7)] {
                path.addLine(to: point)
            }
            path.closeSubpath()
        case .classic, .bunny, .bear, .robot:
            let top: CGFloat = design == .bunny ? 6 : 4.5
            let radius: CGFloat = design == .robot ? 1.5 : (design == .classic ? 3 : 5)
            path.addRoundedRect(in: CGRect(x: 2, y: top, width: 14, height: 21 - top), cornerSize: CGSize(width: radius, height: radius))
        }
        return path.applying(CGAffineTransform(scaleX: rect.width / 18, y: rect.height / 22))
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
    var isPixel = false

    var body: some View {
        switch style {
        case .sparkle:
            RoundedRectangle(cornerRadius: isPixel ? 0 : 1.5)
                .fill(Color.primary)
                .frame(width: 3, height: 3)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 1, height: 1)
                        .offset(x: -0.5, y: -0.5)
                )
        case .normal:
            RoundedRectangle(cornerRadius: isPixel ? 0 : 1)
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
    var isPixel = false

    var body: some View {
        switch style {
        case .happy:
            // 笑顔（U字型）
            if isPixel {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 2))
                    path.addLine(to: CGPoint(x: 4, y: 2))
                    path.addLine(to: CGPoint(x: 4, y: 0))
                }
                .stroke(Color.primary, lineWidth: 1)
                .frame(width: 4, height: 2)
            } else {
                Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    .stroke(Color.primary, lineWidth: 1)
                    .frame(width: 4, height: 2)
            }
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
