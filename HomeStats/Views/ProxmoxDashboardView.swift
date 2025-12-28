import SwiftUI
import Charts

struct ProxmoxDashboardView: View {
    @StateObject private var service = ProxmoxService()

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            // Left side: Graphs (fixed 500px like PM3 box)
            VStack(alignment: .leading, spacing: 15) {
                // Node Overview
                if let node = service.nodeStatus {
                    CompactNodeOverview(node: node)
                }

                // Graphs
                if !service.rrdData.isEmpty {
                    Text("24 Hour History")
                        .font(.headline)
                        .padding(.top, 10)

                    CompactChartsSection(rrdData: service.rrdData)
                }
            }
            .frame(width: 500)

            // Right side: VMs & Containers (expanded)
            if !service.resources.isEmpty {
                ResourcesSection(service: service)
            }

            if service.isLoading && service.resources.isEmpty {
                ProgressView("Loading...")
            }
        }
        .padding(40)
        .onAppear {
            service.startAutoRefresh(interval: 30)
        }
        .onDisappear {
            service.stopAutoRefresh()
        }
    }
}

struct CompactNodeOverview: View {
    let node: ProxmoxNodeStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "server.rack")
                Text("PM3")
                    .font(.title3.bold())
                Spacer()
                Text(formatUptime(node.uptime))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 25) {
                MiniStat(label: "CPU", value: String(format: "%.1f%%", node.cpu * 100), color: .blue)
                MiniStat(label: "RAM", value: formatGB(node.memory.used) + "/" + formatGB(node.memory.total), color: .green)
                MiniStat(label: "Load", value: node.loadavg.first ?? "0", color: .orange)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }

    func formatUptime(_ seconds: Int) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        return "\(days)d \(hours)h"
    }

    func formatGB(_ bytes: Int) -> String {
        String(format: "%.0fG", Double(bytes) / 1_073_741_824)
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.body)
        }
    }
}

struct CompactChartsSection: View {
    let rrdData: [ProxmoxRRDData]

    var body: some View {
        VStack(spacing: 15) {
            MiniChart(title: "CPU", color: .blue, data: rrdData.map { $0.cpuPercent }, maxY: 100, unit: "%")
            MiniChart(title: "Memory", color: .green, data: rrdData.map { $0.memoryPercent }, maxY: 100, unit: "%")
            MiniChart(title: "Net In", color: .cyan, data: rrdData.map { $0.netinMbps }, maxY: nil, unit: " Mbps")
            MiniChart(title: "Net Out", color: .orange, data: rrdData.map { $0.netoutMbps }, maxY: nil, unit: " Mbps")
        }
    }
}

struct MiniChart: View {
    let title: String
    let color: Color
    let data: [Double]
    let maxY: Double?
    let unit: String

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(color)
                Text(String(format: "%.1f", data.last ?? 0) + unit)
                    .font(.body)
            }
            .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                Path { path in
                    guard data.count > 1 else { return }
                    let maxVal = maxY ?? (data.max() ?? 1)
                    let step = geo.size.width / CGFloat(data.count - 1)

                    path.move(to: CGPoint(x: 0, y: geo.size.height - CGFloat(data[0] / maxVal) * geo.size.height))

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * step
                        let y = geo.size.height - CGFloat(value / max(maxVal, 0.001)) * geo.size.height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(color, lineWidth: 2)
            }
            .frame(height: 50)
            .background(Color.white.opacity(0.03))
            .cornerRadius(5)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Node Overview

struct NodeOverviewSection: View {
    let node: ProxmoxNodeStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.title)
                Text("PM3 - \(node.cpuinfo.model)")
                    .font(.title3)
                Spacer()
                Text("Uptime: \(formatUptime(node.uptime))")
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 40) {
                StatCard(
                    title: "CPU",
                    value: String(format: "%.1f%%", node.cpu * 100),
                    icon: "cpu",
                    progress: node.cpu,
                    color: .blue
                )

                StatCard(
                    title: "Memory",
                    value: formatBytes(node.memory.used) + " / " + formatBytes(node.memory.total),
                    icon: "memorychip",
                    progress: Double(node.memory.used) / Double(node.memory.total),
                    color: .green
                )

                StatCard(
                    title: "Load",
                    value: node.loadavg.first ?? "0",
                    icon: "chart.bar",
                    progress: min(1.0, (Double(node.loadavg.first ?? "0") ?? 0) / Double(node.cpuinfo.cpus)),
                    color: .orange
                )
            }
        }
        .padding(30)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }

    func formatUptime(_ seconds: Int) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        return "\(days)d \(hours)h"
    }

    func formatBytes(_ bytes: Int) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.headline)

            Text(value)
                .font(.title3)

            ProgressView(value: min(1.0, max(0, progress)))
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Resources Section

struct ResourcesSection: View {
    @ObservedObject var service: ProxmoxService

    var body: some View {
        HStack(alignment: .top, spacing: 25) {
            // VMs Widget
            ResourceTypeWidget(
                title: "Virtual Machines",
                icon: "desktopcomputer",
                running: service.runningVMs,
                stopped: service.stoppedVMs
            )
            .frame(maxWidth: .infinity)

            // Containers Widget
            ResourceTypeWidget(
                title: "Containers",
                icon: "shippingbox",
                running: service.runningContainers,
                stopped: service.stoppedContainers
            )
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ResourceTypeWidget: View {
    let title: String
    let icon: String
    let running: [ProxmoxResource]
    let stopped: [ProxmoxResource]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.title3)
                Spacer()
                Text("\(running.count) running")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }

            // Running resources
            ForEach(running) { resource in
                ResourceRow(resource: resource)
            }

            // Stopped resources
            if !stopped.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 5)

                Text("\(stopped.count) stopped")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(stopped.prefix(5)) { resource in
                    ResourceRow(resource: resource)
                }

                if stopped.count > 5 {
                    Text("+ \(stopped.count - 5) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

struct ResourceRow: View {
    let resource: ProxmoxResource

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(resource.isRunning ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 10, height: 10)

            Text(resource.displayName)
                .font(.body)

            Spacer()

            if resource.isRunning {
                HStack(spacing: 15) {
                    Label(String(format: "%.0f%%", resource.cpuUsagePercent), systemImage: "cpu")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(String(format: "%.0f%%", resource.memoryUsagePercent), systemImage: "memorychip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("\(resource.vmid ?? 0)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Charts Section

struct ChartsSection: View {
    let rrdData: [ProxmoxRRDData]

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("24 Hour History")
                .font(.title2)

            HStack(alignment: .top, spacing: 30) {
                ChartCard(title: "CPU Usage", color: .blue) {
                    Chart(rrdData) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("CPU", point.cpuPercent)
                        )
                        .foregroundStyle(.blue)

                        AreaMark(
                            x: .value("Time", point.date),
                            y: .value("CPU", point.cpuPercent)
                        )
                        .foregroundStyle(.blue.opacity(0.2))
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 50, 100]) { value in
                            AxisValueLabel {
                                if let v = value.as(Int.self) {
                                    Text("\(v)%")
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                            AxisValueLabel(format: .dateTime.hour())
                            AxisGridLine()
                        }
                    }
                }

                ChartCard(title: "Memory Usage", color: .green) {
                    Chart(rrdData) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Memory", point.memoryPercent)
                        )
                        .foregroundStyle(.green)

                        AreaMark(
                            x: .value("Time", point.date),
                            y: .value("Memory", point.memoryPercent)
                        )
                        .foregroundStyle(.green.opacity(0.2))
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 50, 100]) { value in
                            AxisValueLabel {
                                if let v = value.as(Int.self) {
                                    Text("\(v)%")
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                            AxisValueLabel(format: .dateTime.hour())
                            AxisGridLine()
                        }
                    }
                }
            }

            ChartCard(title: "Network I/O", color: .purple) {
                Chart {
                    ForEach(rrdData) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Mbps", point.netinMbps),
                            series: .value("Direction", "In")
                        )
                        .foregroundStyle(.cyan)

                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Mbps", point.netoutMbps),
                            series: .value("Direction", "Out")
                        )
                        .foregroundStyle(.orange)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(String(format: "%.1f", v))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                        AxisValueLabel(format: .dateTime.hour())
                        AxisGridLine()
                    }
                }
                .chartForegroundStyleScale([
                    "In": Color.cyan,
                    "Out": Color.orange
                ])
            }
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)

            content
                .frame(height: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

#Preview {
    ProxmoxDashboardView()
}
