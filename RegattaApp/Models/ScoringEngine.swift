
import Foundation
import SwiftData

struct ScoringEngine {
    static func score(regatta: Regatta) -> [BoatScoreResult] {
        var boatScores: [UUID: BoatScoreResult] = [:]

        // Initialize scores for all boats in the regatta
        for boat in regatta.boats {
            boatScores[boat.id] = BoatScoreResult(boatId: boat.id, boatName: boat.name, totalScore: 0, netScore: 0, finishes: [])
        }

        // Process finishes for each race
        for race in regatta.races {
            // Sort finishes by position to handle ties or DNC/DNF/DNS correctly
            let sortedFinishes = race.finishes.sorted { (finish1, finish2) -> Bool in
                // Prioritize penalties
                if finish1.isDNC { return true }
                if finish2.isDNC { return false }
                if finish1.isDNF { return true }
                if finish2.isDNF { return false }
                if finish1.isDNS { return true }
                if finish2.isDNS { return false }
                return finish1.position < finish2.position
            }
            
            // Assign points based on position (simple 1st=1pt, 2nd=2pt, etc.)
            for finish in sortedFinishes {
                guard let boat = finish.boat, var currentScore = boatScores[boat.id] else { continue }
                
                var points = finish.position // Default points
                
                // Assign penalty points
                if finish.isDNC { points = regatta.boats.count + 1 } // DNC gets points for last place + 1
                else if finish.isDNF { points = regatta.boats.count + 1 } // DNF gets points for last place + 1
                else if finish.isDNS { points = regatta.boats.count + 1 } // DNS gets points for last place + 1
                
                currentScore.finishes.append(RaceFinishScore(raceNumber: race.raceNumber, points: points))
                boatScores[boat.id] = currentScore
            }
        }

        // Calculate total and net scores
        for boatId in boatScores.keys {
            guard var currentScore = boatScores[boatId] else { continue }
            
            let sortedRaceFinishes = currentScore.finishes.sorted { $0.points < $1.points }
            
            currentScore.totalScore = sortedRaceFinishes.reduce(0) { $0 + $1.points }
            
            var netScoreFinishes = sortedRaceFinishes
            if regatta.throwouts > 0 {
                netScoreFinishes.removeFirst(min(regatta.throwouts, netScoreFinishes.count))
            }
            currentScore.netScore = netScoreFinishes.reduce(0) { $0 + $1.points }
            
            boatScores[boatId] = currentScore
        }

        return boatScores.values.sorted { $0.netScore < $1.netScore }
    }
}

struct BoatScoreResult: Identifiable {
    let id = UUID()
    let boatId: UUID
    let boatName: String
    var totalScore: Int
    var netScore: Int
    var finishes: [RaceFinishScore]
}

struct RaceFinishScore: Identifiable {
    let id = UUID()
    let raceNumber: Int
    let points: Int
}
