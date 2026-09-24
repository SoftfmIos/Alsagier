import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.projects) { project in
                    HStack(spacing: 12) {
                        Circle().fill(project.color.color).frame(width: 12, height: 12)
                        VStack(alignment: .leading) {
                            Text(project.name)
                                .strikethrough(project.isClosed)
                            Text("\(project.dailyMinutes) min/day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(project.isClosed ? "Reopen" : "Close") {
                            store.toggleProject(project)
                        }
                        .buttonStyle(.borderless)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { store.deleteProject(project) }
                    }
                }
            }
            .overlay {
                if store.projects.isEmpty {
                    ContentUnavailableView("No Projects", systemImage: "folder", description: Text("Create a project and choose its daily allocation and color."))
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) { AddProjectView() }
        }
    }
}

private struct AddProjectView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var minutes = 60
    @State private var color = ProjectColor.blue

    var body: some View {
        NavigationStack {
            Form {
                TextField("Project name", text: $name)
                Picker("Daily allocation", selection: $minutes) {
                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { value in
                        Text("\(value) minutes").tag(value)
                    }
                }
                Picker("Color", selection: $color) {
                    ForEach(ProjectColor.allCases) { option in
                        Label(option.rawValue.capitalized, systemImage: "circle.fill")
                            .foregroundStyle(option.color)
                            .tag(option)
                    }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addProject(name: name, minutes: minutes, color: color)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
