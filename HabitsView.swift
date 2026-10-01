import SwiftUI

struct HabitsView:View {
    @EnvironmentObject private var store:AppStore
    @EnvironmentObject private var calendar:CalendarManager
    @EnvironmentObject private var prayers:PrayerManager
    @StateObject private var health = HealthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var editing:Habit?
    @State private var healthMessage:String?
    @State private var isRefreshingHealth = false

    var body:some View {
        NavigationStack {
            List {
                if store.habits.contains(where: { $0.tracksWalking || isGym($0) }) {
                    Section {
                        HStack(spacing:12) {
                            Image(systemName:"heart.text.square.fill").foregroundStyle(.red)
                            VStack(alignment:.leading,spacing:2) {
                                Text("Apple Health").font(.subheadline.weight(.semibold))
                                Text(health.authorized ? "Today's activity is synced from Health" : "Health access is needed to show today's activity")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { Task { await refreshHealth(showConfirmation: true) } } label: {
                                if isRefreshingHealth { ProgressView().controlSize(.small) }
                                else { Text("Refresh") }
                            }.font(.caption).disabled(isRefreshingHealth)
                        }
                    }
                }

                Section {
                    ForEach(store.habits) { h in
                        Button{editing=h}label:{
                            HStack(alignment:.top) {
                                Image(systemName:HabitIntelligence.profile(for:h.name).icon).foregroundStyle(.orange).padding(.top,3)
                                VStack(alignment:.leading,spacing:5) {
                                    Text(h.name)
                                    Text(detail(h)).font(.caption).foregroundStyle(.secondary)

                                    if h.tracksWalking {
                                        walkingHealthRow(h)
                                    } else if isGym(h) {
                                        gymHealthRow()
                                    }

                                    let progress=store.weeklyHabitProgress(h)
                                    HStack(spacing:4) {
                                        ForEach(0..<progress.target,id:\.self) { i in
                                            Image(systemName: i < progress.completed ? "circle.fill" : "circle")
                                                .font(.system(size:8)).foregroundStyle(i < progress.completed ? .orange : .secondary)
                                        }
                                        Text("\(progress.completed)/\(progress.target) this week").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(); if !h.isEnabled {Image(systemName:"pause.circle")}
                            }
                        }.buttonStyle(.plain)
                        .swipeActions { Button("Delete",role:.destructive){store.deleteHabit(h)}; Button(h.isEnabled ? "Pause":"Enable"){store.toggleHabit(h)}.tint(.orange) }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar{Button{editing=Habit(name:"")}label:{Image(systemName:"plus")}}
            .sheet(item:$editing){HabitEditor(habit:$0)}
            .task { await health.requestAccess(); await refreshHealth() }
            .alert("Apple Health", isPresented: Binding(get: { healthMessage != nil }, set: { if !$0 { healthMessage = nil } })) {
                Button("OK", role: .cancel) { healthMessage = nil }
            } message: { Text(healthMessage ?? "") }
            .onChange(of:scenePhase) { _, phase in if phase == .active { Task { await refreshHealth() } } }
            .refreshable { await refreshHealth() }
        }
    }

    @ViewBuilder private func walkingHealthRow(_ h:Habit) -> some View {
        let stepProgress = h.stepTarget > 0 ? min(1.0, Double(health.stepsToday)/Double(h.stepTarget)) : 0
        let minuteProgress = h.walkingMinutesTarget > 0 ? min(1.0, Double(health.walkingMinutesToday)/Double(h.walkingMinutesTarget)) : 0
        let progress = max(stepProgress, minuteProgress)
        VStack(alignment:.leading,spacing:4) {
            Text("\(health.stepsToday.formatted()) / \(h.stepTarget.formatted()) steps  •  \(health.walkingMinutesToday) / \(h.walkingMinutesTarget)m")
                .font(.caption2).foregroundStyle(.secondary)
            ProgressView(value:progress)
                .tint(progress >= 0.75 ? .green : .orange)
            if progress >= 1 { Text("Completed • 100%+").font(.caption2).foregroundStyle(.green) }
            else if progress >= 0.75 { Text("Achieved • \(Int(progress*100))%").font(.caption2).foregroundStyle(.green) }
            else if progress >= 0.50 { Text("Partial • \(Int(progress*100))%").font(.caption2).foregroundStyle(.orange) }
        }
    }

    @ViewBuilder private func gymHealthRow() -> some View {
        if health.gymWorkoutCountToday > 0 {
            Text("Apple Health today: \(health.gymMinutesToday)m gym • \(health.gymWorkoutCountToday) workout\(health.gymWorkoutCountToday == 1 ? "" : "s")")
                .font(.caption2).foregroundStyle(.secondary)
        } else {
            Text("Apple Health today: no gym workout recorded yet")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func refreshHealth(showConfirmation: Bool = false) async {
        if showConfirmation { isRefreshingHealth = true }
        await health.refreshToday()
        if showConfirmation {
            isRefreshingHealth = false
            if health.authorized {
                let workout = health.gymWorkoutCountToday > 0 ? " • \(health.gymMinutesToday)m workout" : " • No workout today"
                healthMessage = "Health Data Updated\n\(health.stepsToday.formatted()) steps • \(health.walkingMinutesToday)m walking\(workout)"
            } else {
                healthMessage = "No Health Data Available. Check Apple Health permissions."
            }
        }
        guard store.isDayActive else { return }
        calendar.loadToday()
        await prayers.refresh()
        store.applyWalkingHealth(steps:health.stepsToday, walkingMinutes:health.walkingMinutesToday,
                                 calendar:calendar.todayBlocks, prayers:prayers.blocks)
    }

    private func isGym(_ h:Habit)->Bool { HabitIntelligence.profile(for:h.name).key == "workout" }

    private func detail(_ h:Habit)->String {
        if h.tracksWalking { return "\(h.stepTarget.formatted()) steps OR \(h.walkingMinutesTarget)m walking • \(h.timesPerWeek)x/week" }
        return h.mode == .fixed ? "\(h.duration)m • fixed days" : "\(h.duration)m • \(h.timesPerWeek)x/week • Random"
    }
}

private struct HabitEditor:View {
    @EnvironmentObject private var store:AppStore
    @Environment(\.dismiss) private var dismiss
    @State var habit:Habit
    var body:some View {
        NavigationStack { Form {
            HStack(spacing:12) {
                Image(systemName: HabitIntelligence.profile(for:habit.name).icon).font(.title2).foregroundStyle(.orange).frame(width:32)
                TextField("Habit name (e.g. Gym / النادي)",text:$habit.name)
            }
            .onChange(of: habit.name) { oldValue, newValue in
                let oldProfile = HabitIntelligence.profile(for:oldValue)
                let profile = HabitIntelligence.profile(for:newValue)
                habit.tracksWalking = profile.tracksWalking
                // Auto-suggest only while the duration still looks like the previous automatic/default value.
                if let explicit = HabitIntelligence.explicitMinutes(in:newValue) { habit.duration = min(180,max(5,explicit)) }
                else if oldValue.isEmpty || habit.duration == oldProfile.defaultMinutes || habit.duration == 30 { habit.duration = profile.defaultMinutes }
            }
            if habit.tracksWalking {
                Section("Walking target — either target completes the day") {
                    Stepper("\(habit.stepTarget.formatted()) steps",value:$habit.stepTarget,in:1000...30000,step:1000)
                    Stepper("\(habit.walkingMinutesTarget) walking minutes",value:$habit.walkingMinutesTarget,in:10...180,step:5)
                    Text("75% or more of either target counts as Achieved. 100%+ is Completed. The real percentage is kept for Insights.").font(.caption).foregroundStyle(.secondary)
                }
            }
            Picker("Duration",selection:$habit.duration){ForEach([15,30,45,60,90],id:\.self){Text("\($0) min").tag($0)}}
            Picker("Road / travel time",selection:$habit.travelMinutes){Text("None").tag(0);Text("15 min").tag(15);Text("30 min").tag(30)}
            Picker("Scheduling",selection:$habit.mode){ForEach(HabitScheduleMode.allCases){Text($0.rawValue).tag($0)}}
            if habit.mode == .fixed {
                Section("Days") { ForEach(1...7,id:\.self){d in Toggle(Calendar.current.weekdaySymbols[d-1],isOn:Binding(get:{habit.weekdays.contains(d)},set:{v in if v{habit.weekdays.insert(d)}else{habit.weekdays.remove(d)}}))} }
            } else {
                Stepper("\(habit.timesPerWeek) times per week",value:$habit.timesPerWeek,in:1...7)
                Picker("Preferred period",selection:$habit.preferredPeriod){ForEach(PreferredPeriod.allCases){Text($0.rawValue).tag($0)}}
                Stepper("Earliest \(habit.earliestHour):00",value:$habit.earliestHour,in:0...22)
                Stepper("Latest \(habit.latestHour):00",value:$habit.latestHour,in:(habit.earliestHour+1)...23)
                Picker("Importance",selection:$habit.priority){ForEach(WorkPriority.allCases){Text($0.rawValue).tag($0)}}
            }
        }.navigationTitle(habit.name.isEmpty ? "New Habit":"Edit Habit").toolbar {
            ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}}
            ToolbarItem(placement:.confirmationAction){Button("Save"){
                if store.habits.contains(where:{$0.id==habit.id}){store.updateHabit(habit)}else{store.addHabit(habit)}; dismiss()
            }.disabled(habit.name.isEmpty || (habit.mode == .fixed && habit.weekdays.isEmpty))}
        } }
    }
}
