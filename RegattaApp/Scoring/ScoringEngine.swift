import Foundation

struct ScoreResult: Identifiable {
    let id: UUID
    let boatName: String
    let sailNumber: String
    let netScore: Int
    let totalScore: Int
    let raceScores: [Int]
}

class ScoringEngine {
    static func score(regatta: Regatta) -> [ScoreResult] {
        let fleetSize = regatta.boats.count
        let penaltyScore = fleetSize + 1
        
        var results: [ScoreResult] = []
        
        for boat in regatta.boats {
            var scores: [Int] = []
            
            for race in regatta.races {
                if let finish = boat.finishes.first(where: { $0.race?.id == race.id }) {
                    if finish.isDNC || finish.isDNF || finish.isDNS {
                        scores.append(penaltyScore)
                    } else {
                        scores.append(finish.position)
                    }
                } else {
                    scores.append(penaltyScore)
                }
            }
            
            let totalScore = scores.reduce(0, +)
            
            var netScore = totalScore
            if regatta.throwouts > 0 && scores.count > regatta.throwouts {
                let sortedScores = scores.sorted(by: >)
                let thrownOut = sortedScores.prefix(regatta.throwouts).reduce(0, +)
                netScore -= thrownOut
            }
            
            results.append(ScoreResult(id: boat.id, boatName: boat.name, sailNumber: boat.sailNumber, netScore: netScore, totalScore: totalScore, raceScores: scores))
        }
        
        return results.sorted { $0.netScore < $1.netScore }
    }
}
