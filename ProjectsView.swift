import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editing: Project?
    @State private var pendingClosure: Project?
    @State private var statusFilter: ProjectFilter = .active

    private enum ProjectFilter: String, CaseIterable, Identifiable {
        case all = "Total", active = "Active", closed = "Closed", frozen = "Frozen"
        var id: String { rawValue }
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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 5) {
                        ForEach(ProjectFilter.allCases) { filter in
                            Button { statusFilter = filter } label: {
                                VStack(spacing: 5) {
                                    Text("\(count(filter))").font(.title3.bold())
                                    Text(LocalizedStringKey(filter.rawValue)).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(statusFilter == filter ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                ForEach(visibleProjects) { p in
                    Button { editing=p } label: {
                        HStack(spacing:12) {
                            RoundedRectangle(cornerRadius:4).fill(p.color.color).frame(width:7,height:48)
                            VStack(alignment:.leading,spacing:4) {
                                Text(p.name).font(.headline).foregroundStyle(p.color.color)
                                Text("\(p.priority.rawValue) • \(p.dailyMinutes)m/day • \(p.mode.rawValue)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if p.status == .frozen { Image(systemName:"snowflake").foregroundStyle(.blue) }
                            if p.status == .closed { Image(systemName:"checkmark.seal.fill").foregroundStyle(.secondary) }
                        }.padding(.vertical,4)
                    }.buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) { store.deleteProject(p) }
                        if p.status != .closed {
                            Button("Close") { pendingClosure = p }.tint(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar { Button{editing=Project(name:"")}label:{Image(systemName:"plus")} }
            .sheet(item:$editing){ProjectEditor(project:$0)}
            .alert("Close project?", isPresented: Binding(get: { pendingClosure != nil }, set: { if !$0 { pendingClosure = nil } })) {
                Button("Cancel", role: .cancel) { pendingClosure = nil }
                Button("Close project", role: .destructive) {
                    if let p = pendingClosure { store.closeProjectAdministratively(p.id) }
                    pendingClosure = nil
                }
            } message: {
                if let p = pendingClosure {
                    let count = store.tasks.filter { $0.projectID == p.id && !$0.isCompleted }.count
                    Text("\(count) unfinished tasks will be marked Done administratively. No work sessions or emotion ratings will be created.")
                }
            }
        }
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
