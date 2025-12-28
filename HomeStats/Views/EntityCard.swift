import SwiftUI

struct EntityCard: View {
    let entity: HAEntity
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: entity.icon)
                    .font(.system(size: 40))
                    .foregroundColor(iconColor)

                // Name
                Text(entity.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // State
                Text(stateText)
                    .font(.title3)
                    .foregroundColor(stateColor)
                    .lineLimit(1)
            }
            .frame(width: 200, height: 180)
            .padding()
            .background(cardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(CardButtonStyle())
    }

    private var stateText: String {
        switch entity.domain {
        case "sensor":
            if let unit = entity.unitOfMeasurement {
                return "\(entity.state) \(unit)"
            }
            return entity.state
        case "binary_sensor":
            return entity.isOn ? "Detected" : "Clear"
        case "light", "switch", "input_boolean", "fan":
            return entity.isOn ? "On" : "Off"
        case "cover":
            return entity.state.capitalized
        case "lock":
            return entity.state == "locked" ? "Locked" : "Unlocked"
        case "person", "device_tracker":
            return entity.state.capitalized
        case "climate":
            return entity.state.capitalized
        case "media_player":
            return entity.state.capitalized
        case "weather":
            return entity.state.replacingOccurrences(of: "-", with: " ").capitalized
        default:
            return entity.state
        }
    }

    private var iconColor: Color {
        switch entity.domain {
        case "light":
            return entity.isOn ? .yellow : .gray
        case "switch", "input_boolean":
            return entity.isOn ? .green : .gray
        case "binary_sensor":
            return entity.isOn ? .orange : .gray
        case "lock":
            return entity.state == "locked" ? .green : .red
        case "climate":
            return .orange
        case "fan":
            return entity.isOn ? .cyan : .gray
        case "media_player":
            return entity.isOn ? .purple : .gray
        case "person", "device_tracker":
            return entity.state.lowercased() == "home" ? .green : .gray
        case "weather":
            return .blue
        default:
            return .primary
        }
    }

    private var stateColor: Color {
        switch entity.domain {
        case "light", "switch", "fan", "input_boolean":
            return entity.isOn ? .green : .secondary
        case "binary_sensor":
            return entity.isOn ? .orange : .secondary
        case "lock":
            return entity.state == "locked" ? .green : .red
        case "person", "device_tracker":
            return entity.state.lowercased() == "home" ? .green : .secondary
        default:
            return .primary
        }
    }

    private var cardBackground: Color {
        #if os(tvOS)
        return Color(white: 0.15)
        #else
        return Color(.systemBackground)
        #endif
    }
}

struct CardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color.white : Color.clear, lineWidth: 4)
            )
            .shadow(color: isFocused ? .white.opacity(0.6) : .clear, radius: 15)
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.1 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    HStack {
        EntityCard(entity: HAEntity(
            entityId: "light.living_room",
            state: "on",
            attributes: HAAttributes(
                friendlyName: "Living Room Light",
                icon: nil,
                unitOfMeasurement: nil,
                brightness: 255,
                colorTemp: nil,
                rgbColor: nil,
                deviceClass: nil
            ),
            lastChanged: Date(),
            lastUpdated: Date()
        ), onToggle: {})

        EntityCard(entity: HAEntity(
            entityId: "sensor.temperature",
            state: "72.5",
            attributes: HAAttributes(
                friendlyName: "Temperature",
                icon: "mdi:thermometer",
                unitOfMeasurement: "F",
                brightness: nil,
                colorTemp: nil,
                rgbColor: nil,
                deviceClass: "temperature"
            ),
            lastChanged: Date(),
            lastUpdated: Date()
        ), onToggle: {})
    }
    .padding()
    .background(Color.black)
}

// Extension to make HAAttributes initializable directly for previews
extension HAAttributes {
    init(friendlyName: String?, icon: String?, unitOfMeasurement: String?,
         brightness: Int?, colorTemp: Int?, rgbColor: [Int]?, deviceClass: String?) {
        self.friendlyName = friendlyName
        self.icon = icon
        self.unitOfMeasurement = unitOfMeasurement
        self.brightness = brightness
        self.colorTemp = colorTemp
        self.rgbColor = rgbColor
        self.deviceClass = deviceClass
    }
}
