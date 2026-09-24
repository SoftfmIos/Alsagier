import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var store: AppStore
    @State private var name = ""
    @State private var duration = 30
    @State private var days: Set<Int> = [1,2,3,4,5,6,7]

    private let labels = [(1,"Sun"),(2,"Mon"),(3,"Tue"),(4,"Wed"),(5,"Thu"),(6,"Fri"),(7,"Sat")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Add Habit") {
                    TextField("Habit name", text: $name)
                    Picker("Duration", selection: $duration) {
                        ForEach([15,30,45,60,90], id: \.self) { Text("\($0) min").tag($0) }
                    }
                    ForEach(labels, id: \.0) { day, label in
                        Toggle(label, isOn: Binding(
                            get: { days.contains(day) },
                            set: { enabled in
                                if enabled {
                                    days.insert(day)
                                } else {
                                    days.remove(day)
                                }
                            }
                        ))
                    }
                    Button("Add Habit") {
                        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else { return }
                        store.addHabit(Habit(name: clean, duration: duration, weekdays: days))
                        name = ""
                    }
                }

                Section("Habits") {
                    if store.habits.isEmpty {
                        Text("No habits yet.").foregroundStyle(.secondary)
                    }
                    ForEach(store.habits) { habit in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(habit.name)
                                Text("\(habit.duration) min").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { store.deleteHabit(habit) } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Habits")
        }
    }
}
