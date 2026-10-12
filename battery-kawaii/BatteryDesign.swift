import SwiftUI

enum BatteryDesign: String, CaseIterable, Identifiable {
    case classic
    case cat
    case bunny
    case bear
    case robot
    case pixel

    static let storageKey = "batteryCharacterDesign"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: String(localized: "Classic")
        case .cat: String(localized: "Cat")
        case .bunny: String(localized: "Bunny")
        case .bear: String(localized: "Bear")
        case .robot: String(localized: "Robot")
        case .pixel: String(localized: "Pixel")
        }
    }

    var accentColor: Color {
        switch self {
        case .classic: .green
        case .cat: Color(red: 0.95, green: 0.60, blue: 0.27)
        case .bunny: .pink
        case .bear: Color(red: 0.65, green: 0.43, blue: 0.26)
        case .robot: .cyan
        case .pixel: .mint
        }
    }
}

struct BatteryDesignPicker: View {
    @Binding var selection: BatteryDesign
    let batteryLevel: Int
    let isCharging: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Design")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(selection.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(BatteryDesign.allCases) { design in
                    Button {
                        selection = design
                    } label: {
                        VStack(spacing: 6) {
                            BatteryCharacterView(
                                batteryLevel: batteryLevel,
                                isCharging: isCharging,
                                design: design,
                                size: 30
                            )
                            Text(design.name)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection == design ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.035))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(selection == design ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: 1)
                        }
                        .overlay(alignment: .topTrailing) {
                            if selection == design {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                                    .padding(5)
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "Show \(design.name) in the menu bar", comment: "Tooltip for choosing a character design. The argument is its localized name."))
                    .accessibilityLabel(design.name)
                    .accessibilityAddTraits(selection == design ? [.isSelected] : [])
                    .accessibilityIdentifier("battery-design-\(design.rawValue)")
                }
            }
        }
    }
}
