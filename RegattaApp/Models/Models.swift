import Foundation
import SwiftData

@Model
final class Regatta {
    var id: UUID
    var name: String
    var location: String
    var throwouts: Int
    
    @Relationship(deleteRule: .cascade)
    var boats: [Boat] = []
    
    @Relationship(deleteRule: .cascade)
    var races: [Race] = []
    
    init(id: UUID = UUID(), name: String, location: String, throwouts: Int = 1) {
        self.id = id
        self.name = name
        self.location = location
        self.throwouts = throwouts
    }
}

@Model
final class Boat {
    var id: UUID
    var sailNumber: String
    var name: String
    var regatta: Regatta?
    
    @Relationship(deleteRule: .cascade)
    var finishes: [RaceFinish] = []
    
    init(id: UUID = UUID(), sailNumber: String, name: String) {
        self.id = id
        self.sailNumber = sailNumber
        self.name = name
    }
}

@Model
final class Race {
    var id: UUID
    var raceNumber: Int
    var regatta: Regatta?
    
    @Relationship(deleteRule: .cascade)
    var finishes: [RaceFinish] = []
    
    init(id: UUID = UUID(), raceNumber: Int) {
        self.id = id
        self.raceNumber = raceNumber
    }
}

@Model
final class RaceFinish {
    var id: UUID
    var position: Int
    var isDNC: Bool
    var isDNF: Bool
    var isDNS: Bool
    
    var boat: Boat?
    var race: Race?
    
    init(id: UUID = UUID(), position: Int, isDNC: Bool = false, isDNF: Bool = false, isDNS: Bool = false) {
        self.id = id
        self.position = position
        self.isDNC = isDNC
        self.isDNF = isDNF
        self.isDNS = isDNS
    }
}
