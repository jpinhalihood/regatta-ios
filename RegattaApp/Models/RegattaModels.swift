
import Foundation

// MARK: - Request Models

struct Boat: Codable {
    let id: String
    let name: String
    let sailNumber: String
}

struct RaceFinish: Codable {
    let boat: Boat
    let finishTime: Date
    let correctedTime: Double? // For calculated corrected time after finish
}

// MARK: - Response Models

struct ScoreResult: Codable {
    let boatId: String
    let raceId: String
    let score: Double
    let message: String?
}
