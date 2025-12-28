import SwiftUI

struct PiholeDashboardView: View {
    @StateObject private var service = PiholeService()

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            // Left side: Stats (500px)
            VStack(alignment: .leading, spacing: 20) {
                if let summary = service.summary {
                    PiholeStatsView(summary: summary)
                }

                // Query History Graph
                if !service.history.isEmpty {
                    Text("Query History (24h)")
                        .font(.headline)
                        .padding(.top, 10)

                    PiholeHistoryCharts(history: service.history)
                }
            }
            .frame(width: 500)

            // Right side: Detailed breakdown
            if let summary = service.summary {
                PiholeDetailView(summary: summary)
            }

            if service.isLoading && service.summary == nil {
                ProgressView("Loading Pi-hole data...")
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

struct PiholeStatsView: View {
    let summary: PiholeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Pi-hole")
                    .font(.title3.bold())
                Spacer()
                Text("\(summary.gravity.domainsBeingBlocked.formatted()) blocked domains")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Main stats row
            HStack(spacing: 30) {
                PiholeStatBox(
                    title: "Total Queries",
                    value: formatNumber(summary.queries.total),
                    color: .blue
                )
                PiholeStatBox(
                    title: "Blocked",
                    value: formatNumber(summary.queries.blocked),
                    subtitle: String(format: "%.1f%%", summary.queries.percentBlocked),
                    color: .red
                )
                PiholeStatBox(
                    title: "Clients",
                    value: "\(summary.clients.active)",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }

    func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
}

struct PiholeStatBox: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(color.opacity(0.7))
            }
        }
    }
}

struct PiholeHistoryCharts: View {
    let history: [PiholeHistoryPoint]

    var body: some View {
        VStack(spacing: 12) {
            PiholeChart(
                title: "Total",
                color: .blue,
                data: history.map { Double($0.total) }
            )
            PiholeChart(
                title: "Blocked",
                color: .red,
                data: history.map { Double($0.blocked) }
            )
            PiholeChart(
                title: "Cached",
                color: .green,
                data: history.map { Double($0.cached) }
            )
            PiholeChart(
                title: "Forwarded",
                color: .orange,
                data: history.map { Double($0.forwarded) }
            )
        }
    }
}

struct PiholeChart: View {
    let title: String
    let color: Color
    let data: [Double]

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(color)
                Text(formatNumber(Int(data.last ?? 0)))
                    .font(.body)
            }
            .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                Path { path in
                    guard data.count > 1 else { return }
                    let maxVal = data.max() ?? 1
                    guard maxVal > 0 else { return }
                    let step = geo.size.width / CGFloat(data.count - 1)

                    path.move(to: CGPoint(
                        x: 0,
                        y: geo.size.height - CGFloat(data[0] / maxVal) * geo.size.height
                    ))

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * step
                        let y = geo.size.height - CGFloat(value / maxVal) * geo.size.height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(color, lineWidth: 2)
            }
            .frame(height: 40)
            .background(Color.white.opacity(0.03))
            .cornerRadius(5)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }

    func formatNumber(_ num: Int) -> String {
        if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
}

struct PiholeDetailView: View {
    let summary: PiholeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Query breakdown
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "chart.pie")
                        .font(.title2)
                    Text("Query Breakdown")
                        .font(.title3)
                }

                QueryRow(label: "Cached", value: summary.queries.cached, total: summary.queries.total, color: .green)
                QueryRow(label: "Forwarded", value: summary.queries.forwarded, total: summary.queries.total, color: .orange)
                QueryRow(label: "Blocked", value: summary.queries.blocked, total: summary.queries.total, color: .red)
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)

            // Additional stats
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "globe")
                        .font(.title2)
                    Text("DNS Stats")
                        .font(.title3)
                }

                HStack {
                    DetailStat(label: "Unique Domains", value: "\(summary.queries.uniqueDomains.formatted())")
                    DetailStat(label: "Active Clients", value: "\(summary.clients.active)")
                    DetailStat(label: "Blocklist Size", value: "\(summary.gravity.domainsBeingBlocked.formatted())")
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QueryRow: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color

    var percent: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .foregroundColor(color)
                Spacer()
                Text("\(value.formatted())")
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f%%", percent * 100))
                    .foregroundColor(color)
                    .frame(width: 60, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * percent)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
    }
}

struct DetailStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PiholeDashboardView()
}
