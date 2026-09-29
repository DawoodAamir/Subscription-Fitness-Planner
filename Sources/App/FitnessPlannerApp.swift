import SwiftUI

@main
struct FitnessPlannerApp: App {
    @StateObject private var training = TrainingStore()
    @StateObject private var subscriptions = SubscriptionStore()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            PlannerView()
                .environmentObject(training)
                .environmentObject(subscriptions)
                .tint(Color(red: 0.12, green: 0.39, blue: 0.32))
                .task { await subscriptions.load() }
                .onChange(of: phase) { value in
                    if value == .active { Task { await subscriptions.refreshEntitlements() } }
                }
        }
    }
}
