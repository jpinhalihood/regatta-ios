import SwiftUI
import SwiftData

@main
struct RegattaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Regatta.self)
    }
}
