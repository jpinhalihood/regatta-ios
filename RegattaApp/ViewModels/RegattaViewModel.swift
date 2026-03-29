import Combine
import Foundation
import SwiftUI

class RegattaViewModel: ObservableObject {
    @Published var regattas: [Regatta] = [] {
        didSet {
            saveRegattas()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String? // For error handling

    private let userDefaultsKey = "regattasData"

    init() {
        loadRegattas()
    }

    // MARK: - Persistence

    private func saveRegattas() {
        if let encoded = try? JSONEncoder().encode(regattas) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadRegattas() {
        if let savedRegattas = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedRegattas = try? JSONDecoder().decode([Regatta].self, from: savedRegattas) {
                self.regattas = decodedRegattas
                return
            }
        }
        self.regattas = [] // Default empty state if no saved data
    }

    // MARK: - Regatta Management

    func addRegatta(name: String, location: String, throwouts: Int) {
        let newRegatta = Regatta(name: name, location: location, throwouts: throwouts)
        regattas.append(newRegatta)
    }

    func addBoat(to regatta: Regatta, sailNumber: String, name: String) {
        guard let index = regattas.firstIndex(where: { $0.id == regatta.id }) else { return }
        let newBoat = Boat(sailNumber: sailNumber, name: name)
        regattas[index].boats.append(newBoat)
    }

    func addRace(to regatta: Regatta) {
        guard let index = regattas.firstIndex(where: { $0.id == regatta.id }) else { return }
        let newRaceNumber = (regattas[index].races.max(by: { $0.raceNumber < $1.raceNumber })?.raceNumber ?? 0) + 1
        let newRace = Race(raceNumber: newRaceNumber)
        regattas[index].races.append(newRace)
    }

    func addRaceFinish(to regatta: Regatta, race: Race, boatId: UUID, position: Int) {
        guard let regattaIndex = regattas.firstIndex(where: { $0.id == regatta.id }) else { return }
        guard let raceIndex = regattas[regattaIndex].races.firstIndex(where: { $0.id == race.id }) else { return }
        
        let newFinish = RaceFinish(boatId: boatId, position: position)
        regattas[regattaIndex].races[raceIndex].finishes.append(newFinish)
        
        // Trigger scoring after a race finish is added
        sendRegattaScore(for: regattas[regattaIndex])
    }

    // MARK: - Networking

    func sendRegattaScore(for regatta: Regatta) {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.sendScoreRequest(regattaId: regatta.id, boats: regatta.boats, races: regatta.races, throwouts: regatta.throwouts) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let scoreResults):
                    self?.updateScoredResults(for: regatta, with: scoreResults)
                    print("Score results received: \(scoreResults)")
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Error submitting score: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateScoredResults(for regatta: Regatta, with newScores: [ScoreResult]) {
        guard let index = regattas.firstIndex(where: { $0.id == regatta.id }) else { return }
        regattas[index].scoredResults = newScores
    }
}
