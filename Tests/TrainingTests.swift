import XCTest
@testable import FitnessPlannerCore

final class TrainingTests: XCTestCase {
    func testSummaryUsesHalfOpenInterval() {
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 200)
        let sessions = [WorkoutSession(workoutID: "a", date: start, minutes: 10), WorkoutSession(workoutID: "b", date: end, minutes: 20)]
        XCTAssertEqual(TrainingSummary.minutes(in: sessions, during: DateInterval(start: start, end: end)), 10)
    }
    func testHistoryRoundTripsWithoutLosingIdentity() throws {
        let session = WorkoutSession(workoutID: "foundation", minutes: 25)
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(session, decoded)
    }
    func testFreeWorkoutsRemainAvailable() {
        XCTAssertGreaterThanOrEqual(Workout.library.filter { !$0.isPremium }.count, 2)
        XCTAssertEqual(Set(Workout.library.map(\.id)).count, Workout.library.count)
    }
}
