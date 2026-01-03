import SwiftUI

/// Option B: Compact Glanceable Layout
/// - Everything visible on one screen (no scrolling)
/// - Smaller, denser information display
/// - Camera smaller but still visible
/// - Best for: Quick glance to check everything, frequent interaction
struct HomeDashboardOptionB: View {
    @ObservedObject var service: HomeDashboardService

    private var anyLightsOn: Bool {
        service.mainHouseLights.contains { $0.isOn } ||
        service.barnLights.contains { $0.isOn }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with status
            topBar
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 10)

            // Main content - 3 column layout
            HStack(alignment: .top, spacing: 24) {
                // Left column: Garage + Weather
                leftColumn
                    .frame(width: 340)

                // Middle column: Temps + Main House Lights
                middleColumn
                    .frame(maxWidth: .infinity)

                // Right column: Barn Lights + Actions
                rightColumn
                    .frame(width: 280)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .background(Color.black)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("Home")
                .font(.title.bold())

            Spacer()

            // Quick status badges
            HStack(spacing: 12) {
                if service.garageDoorState == "open" {
                    alertBadge(icon: "door.garage.open", text: "Garage Open", color: .red)
                }

                if anyLightsOn {
                    let count = service.mainHouseLights.filter { $0.isOn }.count +
                                service.barnLights.filter { $0.isOn }.count
                    alertBadge(icon: "lightbulb.fill", text: "\(count) lights on", color: .yellow)
                }
            }

            Spacer()

            if service.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }

            if let lastUpdated = service.lastUpdated {
                Text(lastUpdated, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func alertBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .font(.caption.bold())
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .cornerRadius(16)
    }

    // MARK: - Left Column

    private var leftColumn: some View {
        VStack(spacing: 16) {
            // Garage with camera
            GarageSectionView(
                doorState: service.garageDoorState,
                cameraURL: service.garageCameraURL,
                onToggle: { Task { await service.toggleGarageDoor() } },
                compact: true
            )

            // Weather
            WeatherSectionView(
                heberWeather: service.heberWeather,
                bigforkWeather: service.bigforkWeather,
                compact: true
            )
        }
    }

    // MARK: - Middle Column

    private var middleColumn: some View {
        VStack(spacing: 16) {
            // Temperatures
            TemperatureSectionView(
                familyRoomTemp: service.familyRoomTemp,
                masterBedroomTemp: service.masterBedroomTemp,
                compact: true
            )

            // Main House Lights
            LightsSectionView(
                title: "Main House",
                icon: "house.fill",
                groups: service.mainHouseLights,
                onToggle: { group in Task { await service.toggleLightGroup(group) } },
                compact: true
            )
        }
    }

    // MARK: - Right Column

    private var rightColumn: some View {
        VStack(spacing: 16) {
            // Barn Lights
            LightsSectionView(
                title: "Barn",
                icon: "building.fill",
                groups: service.barnLights,
                onToggle: { group in Task { await service.toggleLightGroup(group) } },
                compact: true
            )

            Spacer()

            // All Lights Off button
            AllLightsOffButton(
                anyLightsOn: anyLightsOn,
                action: { Task { await service.turnOffAllLights() } }
            )
        }
    }
}
