import SwiftUI
import SwiftData

struct GlobalBoatDirectoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \\GlobalBoat.name) private var globalBoats: [GlobalBoat]
    @State private var searchText = ""
    @State private var showingAddGlobalBoatSheet = false

    var filteredGlobalBoats: [GlobalBoat] {
        if searchText.isEmpty {
            return globalBoats
        } else {
            return globalBoats.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.sailNumber.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredGlobalBoats) { boat in
                    VStack(alignment: .leading) {
                        Text(boat.name)
                            .font(.headline)
                        Text("Sail: \\(boat.sailNumber), Make/Model: \\(boat.makeModel), PHRF: \\(boat.phrf)")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Global Boat Directory")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Global Boat") {
                        showingAddGlobalBoatSheet.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingAddGlobalBoatSheet) {
                AddGlobalBoatView()
            }
        }
    }
}

struct AddGlobalBoatView: View {
    @Environment(\\.modelContext) private var modelContext
    @Environment(\\.dismiss) private var dismiss
    @State private var sailNumber: String = ""
    @State private var name: String = ""
    @State private var makeModel: String = ""
    @State private var phrf: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Sail Number", text: $sailNumber)
                TextField("Boat Name", text: $name)
                TextField("Make/Model", text: $makeModel)
                TextField("PHRF", text: $phrf)

                Button("Save") {
                    if let phrfInt = Int(phrf) {
                        let newGlobalBoat = GlobalBoat(sailNumber: sailNumber, name: name, makeModel: makeModel, phrf: phrfInt)
                        modelContext.insert(newGlobalBoat)
                        dismiss()
                    } else {
                        print("Invalid PHRF input")
                    }
                }
            }
            .navigationTitle("Add New Global Boat")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Extend AddGlobalBoatView to accept an initialSailNumber
extension AddGlobalBoatView {
    init(initialSailNumber: String = "") {
        _sailNumber = State(initialValue: initialSailNumber)
        _name = State(initialValue: "")
        _makeModel = State(initialValue: "")
        _phrf = State(initialValue: "")
    }
}
