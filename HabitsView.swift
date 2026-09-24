import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.habits) { habit in
                    HStack {
                        Button { store.toggleHabit(habit) } label: {
                            Image(systemName: habit.isEnabled ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.borderless)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(habit.name)
                            Text("\(habit.duration) min • \(weekdayText(habit.weekdays))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { store.deleteHabit(habit) }
                    }
                }
            }
            .overlay {
                if store.habits.isEmpty {
                    ContentUnavailableView("No Habits", systemImage: "repeat", description: Text("Add recurring habits for selected weekdays."))
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) { AddHabitView() }
        }
    }

    private func weekdayText(_ days: Set<Int>) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return days.sorted().compactMap { i in
            guard i >= 1, i <= symbols.count else { return nil }
            return symbols[i - 1]
        }.joined(separator: ", ")
    }
}

private struct AddHabitView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var duration = 30
    @State private var weekdays: Set<Int> = []

    var body: some View {
        NavigationStack {
            Form {
                TextField("Habit name", text: $name)
                Picker("Duration", selection: $duration) {
                    ForEach([15, 30, 45, 60, 90], id: \.self) { value in
                        Text("\(value) minutes").tag(value)
                    }
                }
                Section("Repeat") {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(Calendar.current.weekdaySymbols[day - 1], isOn: binding(for: day))
                    }
                }
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addHabit(name: name, duration: duration, weekdays: weekdays)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || weekdays.isEmpty)
                }
            }
        }
    }

    private func binding(for day: Int) -> Binding<Bool> {
        Binding(
            get: { weekdays.contains(day) },
            set: { enabled in
                if enabled { weekdays.insert(day) } else { weekdays.remove(day) }
            }
        )
    }
}
