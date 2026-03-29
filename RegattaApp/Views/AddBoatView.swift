import SwiftUI
import SwiftData

struct AddBoatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var regatta: Regatta

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
            Form {
                Section("Search Global Boats") {
                    TextField("Search by Sail Number or Name", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if filteredGlobalBoats.isEmpty && !searchText.isEmpty {
                        Text("No matching global boats found.")
                        Button("Add \"\\(searchText)\" as New Global Boat") {
                            showingAddGlobalBoatSheet.toggle()
                        }
                    } else {
                        ForEach(filteredGlobalBoats) { globalBoat in
                            Button {
                                addBoatFromGlobalBoat(globalBoat)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(globalBoat.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Sail: \\(globalBoat.sailNumber), Make/Model: \\(globalBoat.makeModel)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Boat to Regatta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add New Global Boat") {
                        showingAddGlobalBoatSheet.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingAddGlobalBoatSheet) {
                AddGlobalBoatView(initialSailNumber: searchText)
            }
        }
    }

    private func addBoatFromGlobalBoat(_ globalBoat: GlobalBoat) {
        let newBoat = Boat(sailNumber: globalBoat.sailNumber, name: globalBoat.name)
        regatta.boats.append(newBoat)
        newBoat.regatta = regatta
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new boat: \\(error.localizedDescription)")
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
