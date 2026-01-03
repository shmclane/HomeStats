import SwiftUI

// MARK: - Garage Section

struct GarageSectionView: View {
    let doorState: String
    let cameraURL: URL?
    let onToggle: () -> Void
    var compact: Bool = false

    private var isOpen: Bool { doorState == "open" }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 20) {
            // Header
            HStack {
                Image(systemName: "door.garage.closed")
                    .font(compact ? .title3 : .title2)
                    .foregroundColor(isOpen ? .red : .green)
                Text("Garage")
                    .font(compact ? .headline : .title3.bold())
                Spacer()
                doorStatusBadge
            }

            if compact {
                compactLayout
            } else {
                fullLayout
            }
        }
        .padding(compact ? 16 : 24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private var doorStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOpen ? Color.red : Color.green)
                .frame(width: 10, height: 10)
            Text(isOpen ? "OPEN" : "CLOSED")
                .font(.caption.bold())
                .foregroundColor(isOpen ? .red : .green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background((isOpen ? Color.red : Color.green).opacity(0.2))
        .cornerRadius(20)
    }

    private var fullLayout: some View {
        HStack(spacing: 20) {
            // Camera preview
            AsyncImage(url: cameraURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                case .failure:
                    cameraPlaceholder
                case .empty:
                    ProgressView()
                @unknown default:
                    cameraPlaceholder
                }
            }
            .frame(width: 320, height: 180)
            .cornerRadius(12)
            .clipped()

            // Control button
            VStack(spacing: 12) {
                Button(action: onToggle) {
                    VStack(spacing: 8) {
                        Image(systemName: isOpen ? "arrow.down.to.line" : "arrow.up.to.line")
                            .font(.system(size: 40))
                        Text(isOpen ? "Close Door" : "Open Door")
                            .font(.headline)
                    }
                    .frame(width: 140, height: 120)
                    .background(isOpen ? Color.orange : Color.blue.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(TVButtonStyle())
            }
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 16) {
            // Mini camera
            AsyncImage(url: cameraURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                } else {
                    cameraPlaceholder
                }
            }
            .frame(width: 160, height: 90)
            .cornerRadius(8)
            .clipped()

            Spacer()

            // Compact button
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: isOpen ? "arrow.down.to.line" : "arrow.up.to.line")
                    Text(isOpen ? "Close" : "Open")
                        .font(.subheadline.bold())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isOpen ? Color.orange : Color.blue.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(TVButtonStyle())
        }
    }

    private var cameraPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "video.slash")
                    .font(.title)
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Temperature Section

struct TemperatureSectionView: View {
    let familyRoomTemp: Double?
    let masterBedroomTemp: Double?
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 16) {
            if !compact {
                HStack {
                    Image(systemName: "thermometer")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Temperature")
                        .font(.title3.bold())
                }
            }

            HStack(spacing: compact ? 20 : 40) {
                TempCard(
                    room: "Family Room",
                    temp: familyRoomTemp,
                    icon: "sofa.fill",
                    compact: compact
                )
                TempCard(
                    room: "Master Bedroom",
                    temp: masterBedroomTemp,
                    icon: "bed.double.fill",
                    compact: compact
                )
            }
        }
        .padding(compact ? 16 : 24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct TempCard: View {
    let room: String
    let temp: Double?
    let icon: String
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(room)
                    .font(compact ? .caption : .subheadline)
                    .foregroundColor(.secondary)
            }
            Text(temp.map { "\(Int($0))°" } ?? "--°")
                .font(compact ? .title2.bold() : .system(size: 44, weight: .bold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Weather Section

struct WeatherSectionView: View {
    let heberWeather: WeatherData?
    let bigforkWeather: WeatherData?
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 16) {
            if !compact {
                HStack {
                    Image(systemName: "cloud.sun.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Weather")
                        .font(.title3.bold())
                }
            }

            HStack(spacing: compact ? 20 : 40) {
                if let heber = heberWeather {
                    HomeWeatherCard(weather: heber, compact: compact)
                }
                if let bigfork = bigforkWeather {
                    HomeWeatherCard(weather: bigfork, compact: compact)
                } else {
                    // Placeholder for Bigfork until added
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bigfork")
                            .font(compact ? .caption : .subheadline)
                            .foregroundColor(.secondary)
                        Text("--")
                            .font(compact ? .title3 : .title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(compact ? 16 : 24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct HomeWeatherCard: View {
    let weather: WeatherData
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            Text(weather.location)
                .font(compact ? .caption : .subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Image(systemName: weather.icon)
                    .font(compact ? .title3 : .title)
                    .foregroundColor(.blue)
                Text(weather.temperature.map { "\(Int($0))°" } ?? "--°")
                    .font(compact ? .title2.bold() : .system(size: 36, weight: .bold))
            }

            Text(weather.condition)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Lights Section

struct LightsSectionView: View {
    let title: String
    let icon: String
    let groups: [LightGroup]
    let onToggle: (LightGroup) -> Void
    var compact: Bool = false

    private var anyOn: Bool { groups.contains { $0.isOn } }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 16) {
            HStack {
                Image(systemName: icon)
                    .font(compact ? .headline : .title2)
                    .foregroundColor(anyOn ? .yellow : .gray)
                Text(title)
                    .font(compact ? .headline : .title3.bold())
                Spacer()
                if anyOn {
                    Text("\(groups.filter { $0.isOn }.count) on")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            if compact {
                compactLightGrid
            } else {
                fullLightGrid
            }
        }
        .padding(compact ? 16 : 24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private var fullLightGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(groups) { group in
                LightGroupCard(group: group, compact: false, onToggle: { onToggle(group) })
            }
        }
    }

    private var compactLightGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(groups) { group in
                LightGroupCard(group: group, compact: true, onToggle: { onToggle(group) })
            }
        }
    }
}

struct LightGroupCard: View {
    let group: LightGroup
    var compact: Bool = false
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: compact ? 4 : 8) {
                Image(systemName: group.icon)
                    .font(compact ? .title3 : .title2)
                    .foregroundColor(group.isOn ? .yellow : .gray)

                Text(group.name)
                    .font(compact ? .caption : .subheadline)
                    .lineLimit(1)

                Text(group.statusText)
                    .font(.caption2)
                    .foregroundColor(group.isOn ? .yellow : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 70 : 100)
            .background(group.isOn ? Color.yellow.opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(TVButtonStyle())
    }
}

// MARK: - TV Button Style

struct TVButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.white : Color.clear, lineWidth: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.05 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - All Lights Off Button

struct AllLightsOffButton: View {
    let anyLightsOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.slash.fill")
                Text("All Lights Off")
                    .font(.headline)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(anyLightsOn ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(TVButtonStyle())
        .disabled(!anyLightsOn)
    }
}
