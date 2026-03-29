import SwiftUI
import SwiftData

struct CreateRegattaView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var throwouts: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Regatta Details")) {
                    TextField("Regatta Name", text: $name)
                    TextField("Location", text: $location)
                    Stepper(value: $throwouts, in: 0...10) {
                        Text("Throwouts: \(throwouts)")
                    }
                }
            }
            .navigationTitle("Create New Regatta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newRegatta = Regatta(name: name, location: location, throwouts: throwouts)
                        modelContext.insert(newRegatta)
                        dismiss()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
}
