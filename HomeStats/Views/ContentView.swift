import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

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
                .tag(index + 1)
            }

            TestDashboardView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Test")
                }
                .tag(AppConfig.printers.count + 1)
        }
    }
}

#Preview {
    ContentView()
}
