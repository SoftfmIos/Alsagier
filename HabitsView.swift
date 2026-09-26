import SwiftUI

struct HabitsView:View {
    @EnvironmentObject private var store:AppStore
    @State private var editing:Habit?
    var body:some View {
        NavigationStack {
            List {
                ForEach(store.habits) { h in
                    Button{editing=h}label:{
                        HStack {
                            Image(systemName:h.tracksWalking ? "figure.walk" : "figure.run").foregroundStyle(.orange)
                            VStack(alignment:.leading,spacing:3) {
                                Text(h.name)
                                Text(detail(h)).font(.caption).foregroundStyle(.secondary)
                                let progress=store.weeklyHabitProgress(h)
                                Text("\(progress.completed)/\(progress.target) completed this week").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(); if !h.isEnabled {Image(systemName:"pause.circle")}
                        }
                    }.buttonStyle(.plain)
                    .swipeActions { Button("Delete",role:.destructive){store.deleteHabit(h)}; Button(h.isEnabled ? "Pause":"Enable"){store.toggleHabit(h)}.tint(.orange) }
                }
            }.navigationTitle("Habits").toolbar{Button{editing=Habit(name:"")}label:{Image(systemName:"plus")}}
            .sheet(item:$editing){HabitEditor(habit:$0)}
        }
    }
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
            TextField("Habit name (e.g. Gym)",text:$habit.name)
            Toggle("Track walking with Apple Health",isOn:$habit.tracksWalking)
            if habit.tracksWalking {
                Section("Walking target — either target completes the day") {
                    Stepper("\(habit.stepTarget.formatted()) steps",value:$habit.stepTarget,in:1000...30000,step:1000)
                    Stepper("\(habit.walkingMinutesTarget) walking minutes",value:$habit.walkingMinutesTarget,in:10...180,step:5)
                    Text("Walking minutes use walking workouts recorded in Apple Health. Steps are consolidated from iPhone and Apple Watch.").font(.caption).foregroundStyle(.secondary)
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
