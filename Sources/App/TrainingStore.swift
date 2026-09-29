import Combine
import Foundation

@MainActor
final class TrainingStore: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []
    @Published var error: String?
    @Published private(set) var plan: [PlannedWorkout] = []
    private let planFile: URL
    private let file: URL

    private var loadFailed = false
    init() {
        let folder = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FitnessPlanner", isDirectory: true)
        file = folder.appendingPathComponent("sessions.json")
        planFile = folder.appendingPathComponent("plan.json")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: planFile.path) {
                plan = try JSONDecoder().decode(
                    [PlannedWorkout].self, from: Data(contentsOf: planFile))
            }
            if FileManager.default.fileExists(atPath: file.path) {
                sessions = try JSONDecoder().decode(
                    [WorkoutSession].self, from: Data(contentsOf: file))
            }
        } catch {
            loadFailed = true
            self.error = "Your workout history could not be loaded. \(error.localizedDescription)"
        }
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--demo"), !loadFailed, sessions.isEmpty {
                log(Workout.library[0])
                log(Workout.library[1])
            }
        #endif

    }

    @discardableResult
    func schedule(_ workout: Workout, on date: Date) -> Bool {
        savePlan(
            (plan + [PlannedWorkout(workoutID: workout.id, scheduledFor: date)])
                .sorted { $0.scheduledFor < $1.scheduledFor })
    }

    func removePlan(_ item: PlannedWorkout) {
        savePlan(plan.filter { $0.id != item.id })
    }

    @discardableResult
    private func savePlan(_ updated: [PlannedWorkout]) -> Bool {
        guard !loadFailed else {
            error =
                "Existing files have been preserved. Resolve the read error before saving changes."
            return false
        }
        do {
            try JSONEncoder().encode(updated).write(to: planFile, options: .atomic)
            plan = updated
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func log(_ workout: Workout) {
        guard !loadFailed else {
            error =
                "The saved data could not be opened. Existing files have been preserved; resolve the read error before saving changes."
            return
        }
        let updated = [WorkoutSession(workoutID: workout.id, minutes: workout.minutes)] + sessions
        do {
            try JSONEncoder().encode(updated).write(to: file, options: .atomic)
            sessions = updated
        } catch { self.error = "The session could not be saved. \(error.localizedDescription)" }
    }

    func delete(at offsets: IndexSet) {
        guard !loadFailed else {
            error =
                "The saved data could not be opened. Existing files have been preserved; resolve the read error before saving changes."
            return
        }
        var updated = sessions
        for index in offsets.sorted(by: >) { updated.remove(at: index) }
        do {
            try JSONEncoder().encode(updated).write(to: file, options: .atomic)
            sessions = updated
        } catch { self.error = error.localizedDescription }
    }
}
