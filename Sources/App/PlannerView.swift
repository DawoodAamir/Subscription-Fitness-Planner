import StoreKit
import SwiftUI

struct PlannerView: View {
    @EnvironmentObject private var training: TrainingStore
    @EnvironmentObject private var subscriptions: SubscriptionStore
    @State private var showMembership = false

    var body: some View {
        TabView {
            NavigationView {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("A little stronger,\none session at a time.")
                                .font(.system(.largeTitle, design: .serif)).fontWeight(.semibold)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(
                                "Simple plans. Room for recovery. A record of the work you put in."
                            )
                            .foregroundColor(.secondary)
                        }.padding(.vertical, 14)
                    }
                    Section("Your training") {
                        HStack {
                            Label("Completed sessions", systemImage: "checkmark.circle")
                            Spacer()
                            Text("\(training.sessions.count)").monospacedDigit().bold()
                        }
                        HStack {
                            Label("Total minutes", systemImage: "clock")
                            Spacer()
                            Text("\(training.sessions.reduce(0) { $0 + $1.minutes })")
                                .monospacedDigit().bold()
                        }
                    }
                    if !training.plan.isEmpty {
                        Section("On your calendar") {
                            ForEach(training.plan) { item in
                                if let workout = Workout.library.first(where: {
                                    $0.id == item.workoutID
                                }) {
                                    NavigationLink(destination: WorkoutView(workout: workout)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workout.name).font(.headline)
                                            Text(item.scheduledFor, style: .date).foregroundColor(
                                                .secondary)
                                        }
                                    }.swipeActions {
                                        Button("Remove", role: .destructive) {
                                            training.removePlan(item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Section("Choose a session") {
                        ForEach(Workout.library) { workout in
                            NavigationLink(destination: WorkoutView(workout: workout)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(workout.name).font(.headline)
                                        if workout.isPremium {
                                            Image(systemName: "lock.circle").accessibilityLabel(
                                                "Membership workout")
                                        }
                                    }
                                    Text("\(workout.focus) · \(workout.minutes) min").font(
                                        .subheadline
                                    ).foregroundColor(.secondary)
                                }.padding(.vertical, 6)
                            }
                        }
                    }
                    Section {
                        Button {
                            showMembership = true
                        } label: {
                            Label(
                                subscriptions.hasPremium ? "Your membership" : "Explore membership",
                                systemImage: "sparkle")
                        }
                    } footer: {
                        Text(
                            "Example routines for a portfolio demonstration. Adjust activity to your own ability."
                        )
                    }
                }
                .navigationTitle("Training")
            }.navigationViewStyle(.stack)
                .tabItem { Label("Training", systemImage: "figure.walk") }
            NavigationView {
                List {
                    if training.sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your first session starts a habit.").font(.headline)
                            Text(
                                "Completed workouts appear here. Choose a session in Training to get started."
                            ).foregroundColor(.secondary)
                        }.padding(.vertical)
                    }
                    ForEach(training.sessions) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                Workout.library.first { $0.id == session.workoutID }?.name
                                    ?? "Workout"
                            ).font(.headline)
                            Text(
                                "\(session.date.formatted(date: .abbreviated, time: .shortened)) · \(session.minutes) min"
                            ).font(.subheadline).foregroundColor(.secondary)
                        }
                    }.onDelete(perform: training.delete)
                }.navigationTitle("History")
            }.navigationViewStyle(.stack)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
        }
        .sheet(isPresented: $showMembership) { MembershipView() }
        .alert(
            "Could not save",
            isPresented: Binding(
                get: { training.error != nil }, set: { if !$0 { training.error = nil } })
        ) {
            Button("OK") { training.error = nil }
        } message: {
            Text(training.error ?? "")
        }
    }
}

struct WorkoutView: View {
    let workout: Workout
    @EnvironmentObject private var training: TrainingStore
    @EnvironmentObject private var subscriptions: SubscriptionStore
    @State private var completed: Set<String> = []
    @State private var showMembership = false
    @State private var logged = false
    @State private var showSchedule = false
    @State private var scheduledFor = Date()

    private var locked: Bool { workout.isPremium && !subscriptions.hasPremium }
    var body: some View {
        List {
            Section {
                Text(workout.focus).foregroundColor(.secondary)
                Label("\(workout.minutes) minutes", systemImage: "clock")
            }
            if locked {
                Section {
                    Text("Part of the strength collection").font(.headline)
                    Text(
                        "Membership unlocks additional routines. Your free workouts and history remain available."
                    )
                    Button("View membership") { showMembership = true }
                }
            } else {
                Section("Exercises") {
                    ForEach(workout.exercises) { exercise in
                        Button {
                            if completed.contains(exercise.id) {
                                completed.remove(exercise.id)
                            } else {
                                completed.insert(exercise.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(
                                    systemName: completed.contains(exercise.id)
                                        ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name).foregroundColor(.primary)
                                    Text(exercise.prescription).font(.subheadline).foregroundColor(
                                        .secondary)
                                }
                            }.padding(.vertical, 6)
                        }.accessibilityLabel(
                            "\(exercise.name), \(completed.contains(exercise.id) ? "completed" : "not completed")"
                        )
                    }
                }
                Section {
                    Button("Schedule this workout") { showSchedule = true }
                    Button(logged ? "Session saved" : "Complete session") {
                        training.log(workout)
                        logged = training.error == nil
                    }.disabled(logged || completed.count != workout.exercises.count)
                } footer: {
                    Text("Check each exercise when finished, then save your session.")
                }
            }
        }.navigationTitle(workout.name)
            .sheet(isPresented: $showSchedule) {
                NavigationView {
                    Form {
                        DatePicker(
                            "Training date", selection: $scheduledFor, in: Date()...,
                            displayedComponents: .date)
                        Button("Add to plan") {
                            if training.schedule(workout, on: scheduledFor) { showSchedule = false }
                        }
                    }.navigationTitle("Schedule workout")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showSchedule = false }
                            }
                        }
                }.navigationViewStyle(.stack)
            }
            .sheet(isPresented: $showMembership) { MembershipView() }
    }
}

struct MembershipView: View {
    @EnvironmentObject private var subscriptions: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Make room for progress.").font(.system(.largeTitle, design: .serif))
                        .fontWeight(.semibold).fixedSize(horizontal: false, vertical: true)
                    Text(
                        "Unlock the complete strength collection. Keep your workout history, with or without a membership."
                    ).foregroundColor(.secondary)
                }.padding(.vertical, 8)
                Section {
                    if subscriptions.hasPremium {
                        Label("Membership active", systemImage: "checkmark.seal.fill")
                    }
                    ForEach(subscriptions.products) { product in
                        Button {
                            Task { await subscriptions.purchase(product) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName).font(.headline)
                                    Text(product.description).font(.caption).foregroundColor(
                                        .secondary)
                                }
                                Spacer()
                                Text(
                                    product.displayPrice
                                        + (product.id.hasSuffix("monthly") ? " / month" : " / year")
                                ).bold()
                            }.padding(.vertical, 8)
                        }.disabled(subscriptions.isBusy || subscriptions.hasPremium)
                    }
                    if subscriptions.products.isEmpty {
                        Button("Reload plans") { Task { await subscriptions.load() } }
                    }
                    Button("Restore purchases") { Task { await subscriptions.restore() } }.disabled(
                        subscriptions.isBusy)
                    if subscriptions.isBusy { ProgressView("Contacting the App Store…") }
                } header: {
                    Text("Membership")
                } footer: {
                    Text(
                        "Subscriptions renew automatically unless canceled. Manage or cancel in your App Store account settings. The shared development scheme uses local StoreKit testing; no payment is collected in that environment."
                    )
                }
                Section("About this example") {
                    Text(
                        "Workout history is stored on this device. The app contains no advertising or analytics. StoreKit handles purchases; no payment details are stored by this app."
                    )
                    Link(
                        "Manage subscriptions",
                        destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                }
            }.navigationTitle("Membership")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                }
        }.navigationViewStyle(.stack)
            .alert(
                "Membership",
                isPresented: Binding(
                    get: { subscriptions.message != nil },
                    set: { if !$0 { subscriptions.message = nil } })
            ) {
                Button("OK") { subscriptions.message = nil }
            } message: {
                Text(subscriptions.message ?? "")
            }
    }
}
