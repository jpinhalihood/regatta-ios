
import SwiftUI

struct CreateRegattaView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegattaViewModel

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var throwouts: Int = 0

    var body: some View {
        NavigationView {
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
                        viewModel.addRegatta(name: name, location: location, throwouts: throwouts)
                        dismiss()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
}

struct CreateRegattaView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRegattaView()
            .environmentObject(RegattaViewModel())
    }
}
