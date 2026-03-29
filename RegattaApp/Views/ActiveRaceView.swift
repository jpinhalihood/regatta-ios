import SwiftUI
import SwiftData

struct ActiveRaceView: View {
    @Bindable var race: Race
    @State var regatta: Regatta // Assuming regatta is passed from parent

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil

    var body: some View {
        VStack {
            Text("Race \(race.raceNumber)")
                .font(.largeTitle)
                .padding()

            if race.startTime == nil {
                Button("Start Race") {
                    race.startTime = Date()
                    startTimer()
                }
                .font(.title)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text(String(format: "Elapsed: %.1f s", elapsedTime))
                    .font(.headline)
                    .onAppear(perform: startTimer)
                    .onDisappear(perform: stopTimer)
            }

            List {
                ForEach(regatta.boats.sorted(using: KeyPathComparator(\\Boat.name))) { boat in
                    HStack {
                        Text(boat.name)

                        Spacer()

                        if let finish = race.finishes.first(where: { $0.boat?.id == boat.id }) {
                            // Boat has finished
                            if finish.isDNF {
                                Text("DNF")
                            } else if finish.isDNS {
                                Text("DNS")
                            } else if finish.isDNC {
                                Text("DNC")
                            } else if let time = finish.elapsedTime {
                                Text(String(format: "Finished: %.1f s", time))
                            }
                        } else {
                            // Boat not finished
                            Button("Finish") {
                                finishBoat(boat: boat)
                            }
                            .buttonStyle(.borderedProminent)

                            Toggle(isOn: Binding(
                                get: { race.finishes.first(where: { $0.boat?.id == boat.id && $0.isDNF }) != nil },
                                set: { newValue in setPenalty(boat: boat, isDNF: newValue, isDNS: false, isDNC: false) }
                            )) {
                                Text("DNF")
                            }
                            .toggleStyle(.button)

                            Toggle(isOn: Binding(
                                get: { race.finishes.first(where: { $0.boat?.id == boat.id && $0.isDNS }) != nil },
                                set: { newValue in setPenalty(boat: boat, isDNF: false, isDNS: newValue, isDNC: false) }
                            )) {
                                Text("DNS")
                            }
                            .toggleStyle(.button)

                            Toggle(isOn: Binding(
                                get: { race.finishes.first(where: { $0.boat?.id == boat.id && $0.isDNC }) != nil },
                                set: { newValue in setPenalty(boat: boat, isDNF: false, isDNS: false, isDNC: newValue) }
                            )) {
                                Text("DNC")
                            }
                            .toggleStyle(.button)
                        }
                    }
                }
            }
        }
        .navigationTitle("Active Race")
        .onAppear {
            if race.startTime != nil {
                startTimer()
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = race.startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func finishBoat(boat: Boat) {
        guard let startTime = race.startTime else { return }
        let timeTaken = Date().timeIntervalSince(startTime)

        let newFinish = RaceFinish(position: 0, elapsedTime: timeTaken) // Position will be calculated later
        newFinish.boat = boat
        race.finishes.append(newFinish)
    }

    private func setPenalty(boat: Boat, isDNF: Bool, isDNS: Bool, isDNC: Bool) {
        if let existingFinishIndex = race.finishes.firstIndex(where: { $0.boat?.id == boat.id }) {
            // Update existing finish
            race.finishes[existingFinishIndex].isDNF = isDNF
            race.finishes[existingFinishIndex].isDNS = isDNS
            race.finishes[existingFinishIndex].isDNC = isDNC
            race.finishes[existingFinishIndex].elapsedTime = nil // Remove elapsed time if a penalty is applied
        } else {
            // Create new finish with penalty
            let newFinish = RaceFinish(position: 0, isDNC: isDNC, isDNF: isDNF, isDNS: isDNS, elapsedTime: nil)
            newFinish.boat = boat
            race.finishes.append(newFinish)
        }
    }
}
