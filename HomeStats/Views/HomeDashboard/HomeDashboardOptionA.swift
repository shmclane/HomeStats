import SwiftUI

/// Option A: 3-Column Dashboard Layout
/// - Column 1: Garage Camera + Door Control + Temperatures
/// - Column 2: Lights (Main House + Barn)
/// - Column 3: Weather
/// - Fits on one screen, no scrolling needed
struct HomeDashboardOptionA: View {
    @ObservedObject var service: HomeDashboardService

    private var anyLightsOn: Bool {
        service.mainHouseLights.contains { $0.isOn }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView

            // 3-Column Layout
            HStack(alignment: .top, spacing: 24) {
                // Column 1: Garage + Temperatures
                VStack(spacing: 16) {
                    garageCameraCard
                    garageControlCard
                    temperatureCard
                }
                .frame(maxWidth: .infinity)

                // Column 2: Lights
                VStack(spacing: 16) {
                    mainHouseLightsCard
                    allLightsOffCard
                }
                .frame(maxWidth: .infinity)

                // Column 3: Weather
                VStack(spacing: 16) {
                    weatherCard
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 48)

            Spacer()
        }
        .padding(.top, 20)
        .background(Color.black)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Home")
                    .font(.largeTitle.bold())
                if let lastUpdated = service.lastUpdated {
                    Text("Updated \(lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 48)

            Spacer()

            if service.isLoading {
                ProgressView()
            }

            // Quick status indicators
            HStack(spacing: 16) {
                StatusPill(
                    icon: "door.garage.closed",
                    text: service.garageDoorState == "open" ? "Open" : "Closed",
                    color: service.garageDoorState == "open" ? .red : .green
                )

                if let temp = service.familyRoomTemp {
                    StatusPill(icon: "thermometer", text: "\(Int(temp))°", color: .orange)
                }

                if anyLightsOn {
                    let onCount = service.mainHouseLights.filter { $0.isOn }.count
                    StatusPill(icon: "lightbulb.fill", text: "\(onCount) on", color: .yellow)
                }
            }
            .padding(.trailing, 48)
        }
    }

    // MARK: - Column 1: Garage + Temps

    private var garageCameraCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Garage Camera", icon: "video.fill")

            AsyncImage(url: service.garageCameraURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                case .failure:
                    cameraPlaceholder
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                @unknown default:
                    cameraPlaceholder
                }
            }
            .frame(height: 180)
            .cornerRadius(12)
            .clipped()
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    private var cameraPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 180)
            .overlay(
                Image(systemName: "video.slash")
                    .font(.title)
                    .foregroundColor(.gray)
            )
    }

    private var garageControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Garage Door", icon: "door.garage.closed")

            HomeStatusRow(
                title: "Status",
                value: service.garageDoorState.capitalized,
                icon: "door.garage.closed",
                color: service.garageDoorState == "open" ? .red : .green
            )

            Button(action: { Task { await service.toggleGarageDoor() } }) {
                HStack {
                    Image(systemName: service.garageDoorState == "open" ? "arrow.down.to.line" : "arrow.up.to.line")
                        .foregroundColor(.white)
                    Text(service.garageDoorState == "open" ? "Close Door" : "Open Door")
                    Spacer()
                }
                .padding(12)
                .background(service.garageDoorState == "open" ? Color.orange : Color.blue.opacity(0.5))
                .cornerRadius(8)
            }
            .buttonStyle(TVButtonStyle())
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    private var temperatureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Temperature", icon: "thermometer")

            HomeStatusRow(
                title: "Family Room",
                value: service.familyRoomTemp.map { "\(Int($0))°" } ?? "--°",
                icon: "sofa.fill",
                color: .orange
            )

            HomeStatusRow(
                title: "Master Bedroom",
                value: service.masterBedroomTemp.map { "\(Int($0))°" } ?? "--°",
                icon: "bed.double.fill",
                color: .orange
            )
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Column 2: Lights

    private var mainHouseLightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HomeSectionHeader(title: "Main House", icon: "house.fill")
                Spacer()
                if service.mainHouseLights.contains(where: { $0.isOn }) {
                    Text("\(service.mainHouseLights.filter { $0.isOn }.count) on")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            ForEach(service.mainHouseLights) { group in
                HomeLightRow(group: group) {
                    Task { await service.toggleLightGroup(group) }
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    private var allLightsOffCard: some View {
        Button(action: { Task { await service.turnOffAllLights() } }) {
            HStack {
                Image(systemName: "lightbulb.slash.fill")
                    .foregroundColor(anyLightsOn ? .red : .gray)
                Text("All Lights Off")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(12)
            .background(anyLightsOn ? Color.red.opacity(0.3) : Color(white: 0.15))
            .cornerRadius(8)
        }
        .buttonStyle(TVButtonStyle())
        .disabled(!anyLightsOn)
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Column 3: Weather

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Weather", icon: "cloud.sun.fill")

            if let heber = service.heberWeather {
                HomeWeatherRow(weather: heber)
            }

            if let bigfork = service.bigforkWeather {
                HomeWeatherRow(weather: bigfork)
            }

            if let greenhouse = service.greenhouseWeather {
                HomeWeatherRow(weather: greenhouse)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct HomeSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct HomeStatusRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(10)
        .background(Color(white: 0.15))
        .cornerRadius(8)
    }
}

struct HomeLightRow: View {
    let group: LightGroup
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: group.icon)
                    .foregroundColor(group.isOn ? .yellow : .gray)
                    .frame(width: 24)
                Text(group.name)
                    .foregroundColor(.primary)
                Spacer()
                Text(group.statusText)
                    .font(.caption)
                    .foregroundColor(group.isOn ? .yellow : .secondary)
            }
            .padding(10)
            .background(group.isOn ? Color.yellow.opacity(0.15) : Color(white: 0.15))
            .cornerRadius(8)
        }
        .buttonStyle(TVButtonStyle())
    }
}

struct HomeWeatherRow: View {
    let weather: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(weather.location)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Image(systemName: weather.icon)
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(weather.temperature.map { "\(Int($0))°" } ?? "--°")
                        .font(.title.bold())
                    Text(weather.condition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let humidity = weather.humidity {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(humidity)%")
                            .font(.headline)
                        Text("Humidity")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(8)
    }
}

struct StatusPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .cornerRadius(20)
    }
}
