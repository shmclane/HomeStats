import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            MediaDashboardView()
                .tabItem {
                    Image(systemName: "play.tv.fill")
                    Text("Media")
                }
                .tag(1)

            ForEach(Array(AppConfig.printers.enumerated()), id: \.offset) { index, printer in
                PrinterDashboardView(
                    printerName: printer.name,
                    printerId: printer.id,
                    amsId: printer.amsId
                )
                .tabItem {
                    Image(systemName: "printer.fill")
                    Text(printer.name)
                }
                .tag(index + 2)
            }

            ProxmoxDashboardView()
                .tabItem {
                    Image(systemName: "server.rack")
                    Text("Proxmox")
                }
                .tag(AppConfig.printers.count + 2)

            PiholeDashboardView()
                .tabItem {
                    Image(systemName: "shield.checkered")
                    Text("Pi-hole")
                }
                .tag(AppConfig.printers.count + 3)

            TestDashboardView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Test")
                }
                .tag(AppConfig.printers.count + 4)
        }
    }
}

#Preview {
    ContentView()
}
