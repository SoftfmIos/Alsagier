import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editing: Project?
    @State private var pendingClosure: Project?
    @State private var statusFilter: ProjectFilter = .active

    private enum ProjectFilter: String, CaseIterable, Identifiable {
        case all = "Total", active = "Active", closed = "Closed", frozen = "Frozen"
        var id: String { rawValue }
        var tint: Color {
            switch self {
            case .all: return .primary
            case .active: return Color(red: 13/255, green: 148/255, blue: 136/255)
            case .closed: return Color(red: 100/255, green: 116/255, blue: 139/255)
            case .frozen: return Color(red: 37/255, green: 99/255, blue: 166/255)
            }
        }
        func matches(_ project: Project) -> Bool {
            switch self {
            case .all: return true
            case .active: return project.status == .active
            case .closed: return project.status == .closed
            case .frozen: return project.status == .frozen
            }
        }
    }

    private var visibleProjects: [Project] { store.projects.filter { statusFilter.matches($0) } }
    private func count(_ filter: ProjectFilter) -> Int { store.projects.filter { filter.matches($0) }.count }
    private func taskCounts(for project: Project) -> (done: Int, total: Int) {
        let tasks = store.tasks.filter { $0.projectID == project.id }
        return (tasks.filter(\.isCompleted).count, tasks.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 7) {
                        ForEach(ProjectFilter.allCases) { filter in
                            Button { statusFilter = filter } label: {
                                VStack(spacing: 6) {
                                    Text("\(count(filter))")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(filter.tint)
                                    Text(LocalizedStringKey(filter.rawValue))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Picker("Filter", selection: $statusFilter) {
                        ForEach(ProjectFilter.allCases) { filter in
                            Text(LocalizedStringKey(filter == .all ? "All" : filter.rawValue)).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)

                    if visibleProjects.isEmpty {
                        ContentUnavailableView("No projects", systemImage: "square.stack.3d.up", description: Text("No projects in this category."))
                            .padding(.top, 30)
                    }
                    ForEach(visibleProjects) { project in
                        projectCard(project)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Projects")
            .toolbar { Button { editing = Project(name: "") } label: { Image(systemName: "plus") } }
            .sheet(item: $editing) { ProjectEditor(project: $0) }
            .alert("Close project?", isPresented: Binding(get: { pendingClosure != nil }, set: { if !$0 { pendingClosure = nil } })) {
                Button("Cancel", role: .cancel) { pendingClosure = nil }
                Button("Close project", role: .destructive) {
                    if let project = pendingClosure { store.closeProjectAdministratively(project.id) }
                    pendingClosure = nil
                }
            } message: {
                if let project = pendingClosure {
                    let unfinished = store.tasks.filter { $0.projectID == project.id && !$0.isCompleted }.count
                    Text("\(unfinished) unfinished tasks will be marked Done administratively. No work sessions or emotion ratings will be created.")
                }
            }
        }
    }

    private func projectCard(_ project: Project) -> some View {
        let progress = taskCounts(for: project)
        let fraction = progress.total == 0 ? 0 : Double(progress.done) / Double(progress.total)
        let statusColor: Color = project.status == .active ? Color(red: 13/255, green: 148/255, blue: 136/255) :
            (project.status == .frozen ? Color(red: 37/255, green: 99/255, blue: 166/255) : Color(red: 100/255, green: 116/255, blue: 139/255))
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                RoundedRectangle(cornerRadius: 3).fill(project.color.color).frame(width: 5, height: 34)
                Text(project.name).font(.headline).foregroundStyle(.primary).lineLimit(2)
                Spacer(minLength: 4)
                Text(LocalizedStringKey(project.status.rawValue))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(statusColor).frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 7)
            HStack {
                Text("\(progress.done) of \(progress.total) tasks")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Button("Edit") { editing = project }
                if project.status != .closed {
                    Button("Close") { pendingClosure = project }
                }
            }
            .font(.caption.weight(.medium))
            .buttonStyle(.borderless)
        }
        .padding(15)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
        .accessibilityElement(children: .contain)
    }
}

private struct ProjectEditor: View {
    @EnvironmentObject private var store:AppStore
    @Environment(\.dismiss) private var dismiss
    @State var project:Project
    var body: some View {
        NavigationStack {
            Form {
                TextField("Project name",text:$project.name).foregroundStyle(project.color.color)
                if project.status == .closed {
                    LabeledContent("Status", value: String(localized: "Closed"))
                    Text("Reopen by changing status to Active or Frozen below.").font(.caption).foregroundStyle(.secondary)
                    Picker("Reopen as", selection: $project.status) {
                        ForEach(ProjectStatus.allCases) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
                    }
                } else {
                    Picker("Status", selection: $project.status) {
                        Text("Active").tag(ProjectStatus.active)
                        Text("Frozen").tag(ProjectStatus.frozen)
                    }
                    Text("To close and complete remaining tasks, use Close from the Projects list.").font(.caption).foregroundStyle(.secondary)
                }
                Picker("Priority",selection:$project.priority){ForEach(WorkPriority.allCases){Text($0.rawValue).tag($0)}}
                Picker("Mode",selection:$project.mode){ForEach(ProjectMode.allCases){Text($0.rawValue).tag($0)}}
                Picker("Daily allocation",selection:$project.dailyMinutes){ForEach([15,30,45,60,90,120],id:\.self){Text("\($0) min").tag($0)}}
                if project.mode == .continuous {
                    Picker("Focus block",selection:$project.preferredBlockMinutes){ForEach([15,30,45,60,90],id:\.self){Text("\($0) min").tag($0)}}
                }
                Section("Color") {
                    LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:5),spacing:16) {
                        ForEach(ProjectColor.projectChoices) { choice in
                            Button { project.color = choice } label: {
                                ZStack {
                                    Circle().fill(choice.color).frame(width:38,height:38)
                                    if project.color == choice {
                                        Circle().stroke(.primary,lineWidth:3).frame(width:46,height:46)
                                        Image(systemName:"checkmark").font(.caption.bold()).foregroundStyle(.white)
                                    }
                                }.frame(width:50,height:50)
                            }.buttonStyle(.plain).accessibilityLabel(choice.rawValue.capitalized)
                        }
                    }.padding(.vertical,6)
                }
            }.navigationTitle(project.name.isEmpty ? "New Project":"Edit Project")
            .toolbar {
                ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}}
                ToolbarItem(placement:.confirmationAction){Button("Save"){
                    if store.projects.contains(where:{$0.id==project.id}){store.updateProject(project)}else{store.addProject(project)}
                    dismiss()
                }.disabled(project.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}
            }
        }
    }
}
