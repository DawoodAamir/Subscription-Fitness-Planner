import Foundation
import Combine

@MainActor
final class TrainingStore: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []
    @Published var error: String?
    private let file: URL

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FitnessPlanner", isDirectory: true)
        file = folder.appendingPathComponent("sessions.json")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: file.path) {
                sessions = try JSONDecoder().decode([WorkoutSession].self, from: Data(contentsOf: file))
            }
        } catch { self.error = "Your workout history could not be loaded. \(error.localizedDescription)" }
    }

    func log(_ workout: Workout) {
        let updated = [WorkoutSession(workoutID: workout.id, minutes: workout.minutes)] + sessions
        do {
            try JSONEncoder().encode(updated).write(to: file, options: .atomic)
            sessions = updated
        } catch { self.error = "The session could not be saved. \(error.localizedDescription)" }
    }

    func delete(at offsets: IndexSet) {
        var updated = sessions
        for index in offsets.sorted(by: >) { updated.remove(at: index) }
        do {
            try JSONEncoder().encode(updated).write(to: file, options: .atomic)
            sessions = updated
        } catch { self.error = error.localizedDescription }
    }
}
