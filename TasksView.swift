import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.tasks) { task in
                    HStack {
                        Button { store.toggleTask(task) } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.borderless)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title).strikethrough(task.isCompleted)
                            HStack {
                                Text("\(task.duration) min")
                                Text("• \(task.priority.rawValue)")
                                if let pid = task.projectID, let project = store.projects.first(where: { $0.id == pid }) {
                                    Text("• \(project.name)")
                                        .foregroundStyle(project.color.color)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { store.deleteTask(task) }
                    }
                }
            }
            .overlay {
                if store.tasks.isEmpty {
                    ContentUnavailableView("No Tasks", systemImage: "checklist", description: Text("Tasks remain here until you mark them complete."))
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
    }
}

private struct AddTaskView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var duration = 30
    @State private var projectID: UUID?
    @State private var priority = TaskPriority.medium

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task", text: $title)
                Picker("Duration", selection: $duration) {
                    ForEach([15, 30, 45, 60, 90], id: \.self) { value in
                        Text("\(value) minutes").tag(value)
                    }
                }
                Picker("Project", selection: $projectID) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(store.projects.filter { !$0.isClosed }) { project in
                        Text(project.name).tag(Optional(project.id))
                    }
                }
                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addTask(title: title, duration: duration, projectID: projectID, priority: priority)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
