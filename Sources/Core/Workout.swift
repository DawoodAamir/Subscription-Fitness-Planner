import Foundation

public struct Exercise: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let prescription: String
}

public struct Workout: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let focus: String
    public let minutes: Int
    public let isPremium: Bool
    public let exercises: [Exercise]

    public static let library: [Workout] = [
        Workout(id: "foundation", name: "Full body foundation", focus: "Strength · No equipment", minutes: 25, isPremium: false, exercises: [
            Exercise(id: "squat", name: "Bodyweight squat", prescription: "3 sets × 12 reps"),
            Exercise(id: "push", name: "Incline push-up", prescription: "3 sets × 8 reps"),
            Exercise(id: "bridge", name: "Glute bridge", prescription: "3 sets × 12 reps"),
            Exercise(id: "plank", name: "Plank", prescription: "3 sets × 30 seconds")]),
        Workout(id: "mobility", name: "Room to move", focus: "Mobility · Recovery", minutes: 15, isPremium: false, exercises: [
            Exercise(id: "cat", name: "Cat-cow", prescription: "2 sets × 8 reps"),
            Exercise(id: "lunge", name: "Low lunge stretch", prescription: "45 seconds each side"),
            Exercise(id: "rotate", name: "Thoracic rotation", prescription: "8 reps each side")]),
        Workout(id: "upper", name: "Upper body strength", focus: "Strength · Dumbbells", minutes: 35, isPremium: true, exercises: [
            Exercise(id: "row", name: "Dumbbell row", prescription: "3 sets × 10 reps"),
            Exercise(id: "press", name: "Floor press", prescription: "3 sets × 10 reps"),
            Exercise(id: "raise", name: "Lateral raise", prescription: "3 sets × 12 reps")])
    ]
}

public struct WorkoutSession: Codable, Identifiable, Equatable {
    public let id: UUID
    public let workoutID: String
    public let date: Date
    public let minutes: Int

    public init(id: UUID = UUID(), workoutID: String, date: Date = Date(), minutes: Int) {
        self.id = id; self.workoutID = workoutID; self.date = date; self.minutes = max(0, minutes)
    }
}

public enum TrainingSummary {
    public static func minutes(in sessions: [WorkoutSession], during interval: DateInterval) -> Int {
        sessions.filter { $0.date >= interval.start && $0.date < interval.end }.reduce(0) { $0 + $1.minutes }
    }
}
