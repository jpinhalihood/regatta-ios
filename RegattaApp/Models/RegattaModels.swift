
import Foundation

// MARK: - Core Data Models

struct Regatta: Identifiable, Codable {
    let id: UUID
    var name: String
    var location: String
    var throwouts: Int
    var boats: [Boat]
    var races: [Race]
    var scoredResults: [ScoreResult]

    init(id: UUID = UUID(), name: String, location: String, throwouts: Int, boats: [Boat] = [], races: [Race] = [], scoredResults: [ScoreResult] = []) {
        self.id = id
        self.name = name
        self.location = location
        self.throwouts = throwouts
        self.boats = boats
        self.races = races
        self.scoredResults = scoredResults
    }
}

struct Boat: Identifiable, Codable {
    let id: UUID
    var sailNumber: String
    var name: String

    init(id: UUID = UUID(), sailNumber: String, name: String) {
        self.id = id
        self.sailNumber = sailNumber
        self.name = name
    }
}

struct Race: Identifiable, Codable {
    let id: UUID
    var raceNumber: Int
    var finishes: [RaceFinish]

    init(id: UUID = UUID(), raceNumber: Int, finishes: [RaceFinish] = []) {
        self.id = id
        self.raceNumber = raceNumber
        self.finishes = finishes
    }
}

struct RaceFinish: Identifiable, Codable {
    let id: UUID
    var boatId: UUID
    var position: Int

    init(id: UUID = UUID(), boatId: UUID, position: Int) {
        self.id = id
        self.boatId = boatId
        self.position = position
    }
}

// MARK: - API Request/Response Models

struct ScoringRequest: Codable {
    let regattaId: UUID
    let boats: [Boat]
    let races: [Race]
    let throwouts: Int
}

struct ScoreResult: Identifiable, Codable {
    let id: UUID
    let boatId: UUID
    let raceId: UUID
    let score: Double
    let message: String?
    
    init(id: UUID = UUID(), boatId: UUID, raceId: UUID, score: Double, message: String? = nil) {
        self.id = id
        self.boatId = boatId
        self.raceId = raceId
        self.score = score
        self.message = message
    }
}
