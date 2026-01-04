import SwiftUI

struct PrinterFormView: View {
    let printerId: String

    @ObservedObject private var syncManager = ConfigSyncManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var deviceId = ""
    @State private var accessCode = ""
    @State private var amsId = ""

    private var printerIndex: Int? {
        syncManager.config.printers.firstIndex { $0.id == printerId }
    }

    var body: some View {
        Form {
            Section {
                TextField("Display Name", text: $name)
            } header: {
                Text("Name")
            } footer: {
                Text("A friendly name for this printer (e.g., \"Office Printer\")")
            }

            Section {
                TextField("Device ID", text: $deviceId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Access Code", text: $accessCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("AMS ID (optional)", text: $amsId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Bambu Lab Credentials")
            } footer: {
                Text("Find these in the Bambu Handy app or printer settings")
            }

            Section {
                Button("Save") {
                    save()
                }
                .disabled(name.isEmpty || deviceId.isEmpty || accessCode.isEmpty)

                Button("Remove Printer", role: .destructive) {
                    remove()
                }
            }
        }
        .navigationTitle(name.isEmpty ? "New Printer" : name)
        .onAppear {
            if let index = printerIndex {
                let printer = syncManager.config.printers[index]
                name = printer.name
                deviceId = printer.printerId
                accessCode = printer.accessCode
                amsId = printer.amsId ?? ""
            }
        }
    }

    private func save() {
        let printer = PrinterConfig(
            id: printerId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            printerId: deviceId.trimmingCharacters(in: .whitespacesAndNewlines),
            accessCode: accessCode.trimmingCharacters(in: .whitespacesAndNewlines),
            amsId: amsId.isEmpty ? nil : amsId.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if let index = printerIndex {
            syncManager.config.printers[index] = printer
        }

        syncManager.save()
        dismiss()
    }

    private func remove() {
        if let index = printerIndex {
            syncManager.config.printers.remove(at: index)
            syncManager.save()
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PrinterFormView(printerId: UUID().uuidString)
    }
}
