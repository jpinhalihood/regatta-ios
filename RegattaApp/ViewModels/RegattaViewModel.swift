
import Foundation
import SwiftUI

class RegattaViewModel: ObservableObject {
    @Published var regattas: [String] = ["Spring Regatta 2026", "Summer Series Race 1", "Fall Classic"]
    @Published var isLoading = false
    @Published var errorMessage: String? // For error handling

    init() {
        // Load initial data or perform setup
    }

    func fetchRegattas() {
        isLoading = true
        // Simulate a network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.regattas = ["Spring Regatta 2026", "Summer Series Race 1", "Fall Classic", "Winter Warmup"]
            self.isLoading = false
        }
    }
    
    // Example of sending a score (integrate with NetworkManager)
    func submitScore(boat: Boat, finishTime: Date) {
        isLoading = true
        let raceFinish = RaceFinish(boat: boat, finishTime: finishTime, correctedTime: nil)
        NetworkManager.shared.sendScore(raceFinish: raceFinish) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let scoreResult):
                    print("Score submitted: \(scoreResult)")
                    // Handle success, e.g., update UI
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error submitting score: \(error.localizedDescription)")
                }
            }
        }
    }
}
