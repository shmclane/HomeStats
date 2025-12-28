import SwiftUI

struct PrinterDashboardView: View {
    let printerName: String
    let printerId: String
    let amsId: String?

    @StateObject private var service = HAService(applyFilters: false)
    @State private var selectedSection = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if service.isLoading && service.entities.isEmpty {
                ProgressView("Loading printer data...")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView

                        // Main content in horizontal sections
                        HStack(alignment: .top, spacing: 24) {
                            // Left column - Status & Temps
                            VStack(spacing: 16) {
                                printerStatusSection
                                temperatureSection
                                fansSection
                            }
                            .frame(maxWidth: .infinity)

                            // Center column - Current Print & Camera
                            VStack(spacing: 16) {
                                currentPrintSection
                                cameraSection
                            }
                            .frame(maxWidth: .infinity)

                            // Right column - Materials & Controls
                            VStack(spacing: 16) {
                                materialSection
                                controlsSection
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 48)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .onAppear {
            service.startAutoRefresh()
        }
        .onDisappear {
            service.stopAutoRefresh()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "printer.fill")
                .font(.title)
                .foregroundColor(.blue)

            Text(printerName)
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            // Online status
            HStack(spacing: 8) {
                Circle()
                    .fill(isOnline ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(isOnline ? "Online" : "Offline")
                    .foregroundColor(.secondary)
            }

            if let lastUpdated = service.lastUpdated {
                Text("Updated: \(lastUpdated, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Printer Status Section

    private var printerStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Printer Status", icon: "printer.fill")

            VStack(spacing: 8) {
                StatusCard(
                    title: "Print Status",
                    value: printStatus.capitalized,
                    icon: "printer.fill",
                    color: printStatusColor
                )

                StatusCard(
                    title: "Progress",
                    value: "\(printProgress)%",
                    icon: "chart.pie.fill",
                    color: progressColor
                )

                StatusCard(
                    title: "Remaining",
                    value: remainingTimeFormatted,
                    icon: "timer",
                    color: .blue
                )

                StatusCard(
                    title: "Layer",
                    value: "\(currentLayer) / \(totalLayers)",
                    icon: "square.3.layers.3d",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Temperature Section

    private var temperatureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Temperature", icon: "thermometer")

            VStack(spacing: 8) {
                TemperatureCard(
                    title: "Nozzle",
                    current: nozzleTemp,
                    target: nozzleTargetTemp,
                    max: 300,
                    icon: "flame.fill"
                )

                TemperatureCard(
                    title: "Bed",
                    current: bedTemp,
                    target: bedTargetTemp,
                    max: 100,
                    icon: "square.fill"
                )
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Fans Section

    private var fansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Fans", icon: "fan.fill")

            HStack(spacing: 12) {
                FanCard(title: "Cooling", speed: coolingFanSpeed)
                FanCard(title: "Chamber", speed: chamberFanSpeed)
                FanCard(title: "Aux", speed: auxFanSpeed)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Current Print Section

    private var currentPrintSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Current Print", icon: "doc.fill")

            VStack(spacing: 12) {
                // Task name
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                    Text(taskName.isEmpty ? "No active print" : taskName)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer()
                }
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(8)

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(printProgress)%")
                            .fontWeight(.semibold)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(white: 0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(width: geo.size.width * CGFloat(printProgress) / 100)
                        }
                    }
                    .frame(height: 8)
                }
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(8)

                // Stats grid
                HStack(spacing: 12) {
                    StatBox(title: "Material", value: "\(Int(materialUsed))g", icon: "scalemass.fill")
                    StatBox(title: "Time Left", value: remainingTimeFormatted, icon: "clock.fill")
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Camera Section

    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Camera", icon: "video.fill")

            CameraCard(entity: cameraEntity ?? HAEntity.placeholder)
                .frame(height: 225)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Material Section

    private var materialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "AMS Materials", icon: "circle.grid.2x2.fill")

            VStack(spacing: 8) {
                // Active tray
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.green)
                    Text("Active: \(activeTray)")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(8)
                .background(Color(white: 0.15))
                .cornerRadius(8)

                // Humidity
                HStack {
                    Image(systemName: "humidity.fill")
                        .foregroundColor(humidityColor)
                    Text("Humidity: \(amsHumidity)")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(8)
                .background(Color(white: 0.15))
                .cornerRadius(8)

                // Tray cards
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { tray in
                        TrayCard(
                            trayNumber: tray,
                            material: getTrayMaterial(tray),
                            color: getTrayColor(tray)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Controls", icon: "slider.horizontal.3")

            VStack(spacing: 8) {
                ControlButton(
                    title: "Pause",
                    icon: "pause.circle.fill",
                    color: .orange
                ) {
                    Task { await pressButton("pause_printing") }
                }

                ControlButton(
                    title: "Resume",
                    icon: "play.circle.fill",
                    color: .green
                ) {
                    Task { await pressButton("resume_printing") }
                }

                ControlButton(
                    title: "Stop",
                    icon: "stop.circle.fill",
                    color: .red
                ) {
                    Task { await pressButton("stop_printing") }
                }

                ControlButton(
                    title: "Refresh",
                    icon: "arrow.clockwise.circle.fill",
                    color: .blue
                ) {
                    Task { await pressButton("force_refresh_data") }
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }

    // MARK: - Helper Functions

    private func pressButton(_ buttonName: String) async {
        await service.callButton(entityId: "button.\(printerId)_\(buttonName)")
    }

    private func getEntity(_ suffix: String) -> HAEntity? {
        service.entities.first { $0.entityId.contains(printerId) && $0.entityId.hasSuffix(suffix) }
    }

    private func getState(_ suffix: String) -> String {
        getEntity(suffix)?.state ?? "unknown"
    }

    private func getStateFloat(_ suffix: String) -> Double {
        Double(getState(suffix)) ?? 0
    }

    // MARK: - Computed Properties

    private var isOnline: Bool {
        getState("online") == "on"
    }

    private var printStatus: String {
        getState("print_status")
    }

    private var printStatusColor: Color {
        switch printStatus.lowercased() {
        case "running": return .green
        case "pause", "paused": return .orange
        case "failed", "error": return .red
        default: return .blue
        }
    }

    private var printProgress: Int {
        Int(getStateFloat("print_progress"))
    }

    private var progressColor: Color {
        if printProgress > 75 { return .green }
        if printProgress > 25 { return .yellow }
        return .blue
    }

    private var remainingTimeFormatted: String {
        let mins = Int(getStateFloat("remaining_time"))
        if mins == 0 { return "--" }
        let hours = mins / 60
        let minutes = mins % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var currentLayer: Int {
        Int(getStateFloat("current_layer"))
    }

    private var totalLayers: Int {
        Int(getStateFloat("total_layer_count"))
    }

    private var nozzleTemp: Double {
        getStateFloat("nozzle_temperature")
    }

    private var nozzleTargetTemp: Double {
        getStateFloat("nozzle_target_temperature")
    }

    private var bedTemp: Double {
        getStateFloat("bed_temperature")
    }

    private var bedTargetTemp: Double {
        getStateFloat("bed_target_temperature")
    }

    private var coolingFanSpeed: Int {
        Int(getStateFloat("cooling_fan_speed"))
    }

    private var chamberFanSpeed: Int {
        Int(getStateFloat("chamber_fan_speed"))
    }

    private var auxFanSpeed: Int {
        Int(getStateFloat("aux_fan_speed"))
    }

    private var taskName: String {
        getState("task_name")
    }

    private var materialUsed: Double {
        getStateFloat("total_usage")
    }

    private var activeTray: String {
        getState("active_tray")
    }

    private var amsHumidity: String {
        getAmsState("ams_1_humidity_index")
    }

    private var humidityColor: Color {
        let humidity = getAmsStateFloat("ams_1_humidity_index")
        if humidity > 30 { return .red }
        if humidity > 20 { return .yellow }
        return .green
    }

    private var cameraEntity: HAEntity? {
        service.entities.first { $0.entityId == "camera.\(printerId)_camera" }
    }

    private func getTrayMaterial(_ tray: Int) -> String {
        getAmsState("ams_1_tray_\(tray)")
    }

    private func getTrayColor(_ tray: Int) -> Color {
        // Default colors for trays - would need to parse attributes for actual colors
        let colors: [Color] = [.red, .blue, .white, .green]
        return colors[tray - 1]
    }

    // AMS helper functions (may use different ID than printer)
    private func getAmsEntity(_ suffix: String) -> HAEntity? {
        let amsPrefix = amsId ?? printerId
        return service.entities.first { $0.entityId.contains(amsPrefix) && $0.entityId.hasSuffix(suffix) }
    }

    private func getAmsState(_ suffix: String) -> String {
        getAmsEntity(suffix)?.state ?? "unknown"
    }

    private func getAmsStateFloat(_ suffix: String) -> Double {
        Double(getAmsState(suffix)) ?? 0
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
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

struct StatusCard: View {
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

struct TemperatureCard: View {
    let title: String
    let current: Double
    let target: Double
    let max: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tempColor)
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(current))°C / \(Int(target))°C")
                    .fontWeight(.semibold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tempColor)
                        .frame(width: geo.size.width * CGFloat(current / max))
                }
            }
            .frame(height: 6)
        }
        .padding(10)
        .background(Color(white: 0.15))
        .cornerRadius(8)
    }

    var tempColor: Color {
        let ratio = current / max
        if ratio > 0.8 { return .red }
        if ratio > 0.6 { return .orange }
        return .blue
    }
}

struct FanCard: View {
    let title: String
    let speed: Int

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "fan.fill")
                .font(.title2)
                .foregroundColor(speed > 0 ? .cyan : .gray)
                .rotationEffect(.degrees(speed > 0 ? 360 : 0))
                .animation(speed > 0 ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: speed)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(speed)%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(white: 0.15))
        .cornerRadius(8)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(8)
    }
}

struct TrayCard: View {
    let trayNumber: Int
    let material: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            Text("\(trayNumber)")
                .font(.caption)
                .fontWeight(.semibold)
            Text(material.prefix(8).description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(white: 0.15))
        .cornerRadius(8)
    }
}

struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                Spacer()
            }
            .padding(10)
            .background(Color(white: 0.15))
            .cornerRadius(8)
        }
        .buttonStyle(CardButtonStyle())
    }
}

// Placeholder for when camera entity is not available
extension HAEntity {
    static var placeholder: HAEntity {
        HAEntity(
            entityId: "camera.placeholder",
            state: "unavailable",
            attributes: HAAttributes(friendlyName: "Camera", icon: nil, unitOfMeasurement: nil, brightness: nil, colorTemp: nil, rgbColor: nil, deviceClass: nil),
            lastChanged: Date(),
            lastUpdated: Date()
        )
    }
}
