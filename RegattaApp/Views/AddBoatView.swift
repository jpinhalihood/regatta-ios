
import SwiftUI
import SwiftData

struct AddBoatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var regatta: Regatta

    @State private var sailNumber: String = ""
    @State private var boatName: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Boat Details") {
                    TextField("Sail Number", text: $sailNumber)
                        .keyboardType(.numberPad)
                    TextField("Boat Name", text: $boatName)
                }
            }
            .navigationTitle("Add New Boat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addBoat()
                        dismiss()
                    }
                    .disabled(sailNumber.isEmpty || boatName.isEmpty)
                }
            }
        }
    }

    private func addBoat() {
        let newBoat = Boat(sailNumber: sailNumber, name: boatName)
        regatta.boats.append(newBoat)
        newBoat.regatta = regatta // Establish inverse relationship
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new boat: \(error.localizedDescription)")
        }
    }
}
