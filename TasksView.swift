import SwiftUI

private enum TaskFilter: Hashable { case all, active, closed }

struct TasksView: View {
    @EnvironmentObject private var store:AppStore
    @State private var add=false
    @State private var filter: TaskFilter = .active
    @State private var selectedProjectID: UUID?
    @State private var editingTask: ExecutiveTask?

    private var projectTasks: [ExecutiveTask] {
        guard let selectedProjectID else { return store.tasks }
        return store.tasks.filter { $0.projectID == selectedProjectID }
    }

    private var visible: [ExecutiveTask] {
        switch filter {
        case .all: return projectTasks
        case .active: return projectTasks.filter { !$0.isCompleted }
        case .closed: return projectTasks.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        taskMetric("Total", projectTasks.count, "tray.full") { filter = .all }
                        taskMetric("Active", projectTasks.filter { !$0.isCompleted }.count, "clock") { filter = .active }
                        taskMetric("Closed", projectTasks.filter { $0.isCompleted }.count, "checkmark.circle") { filter = .closed }
                    }
                    Picker("Task status", selection: Binding(
                        get: { statusSelection },
                        set: { filter = $0 }
                    )) {
                        Text("All").tag(TaskFilter.all)
                        Text("Active").tag(TaskFilter.active)
                        Text("Closed").tag(TaskFilter.closed)
                    }
                    .pickerStyle(.segmented)

                    Menu {
                        Button { selectedProjectID = nil } label: { Label("All Projects", systemImage:"tray.full") }
                        Divider()
                        ForEach(store.projects) { p in
                            Button { selectedProjectID = p.id } label: {
                                Label(p.name, systemImage:"folder")
                            }
                        }
                    } label: {
                        HStack(spacing:8) {
                            Image(systemName:"folder")
                            Text(isProjectFilter ? projectFilterTitle : "Filter by Project")
                                .lineLimit(1)
                            Spacer()
                            Image(systemName:"chevron.up.chevron.down").font(.caption)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isProjectFilter ? Color.accentColor : Color.primary)
                        .padding(.horizontal,12).frame(height:40)
                        .background(Color(.secondarySystemBackground), in:RoundedRectangle(cornerRadius:12))
                    }
                    if isProjectFilter {
                        Button { selectedProjectID = nil } label: {
                            Label("Clear project filter", systemImage:"xmark.circle.fill").font(.caption.weight(.semibold))
                        }.buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal).padding(.top,8).padding(.bottom,6)

                List {
                    ForEach(visible) { t in
                        HStack {
                            Button{store.toggleTask(t)}label:{Image(systemName:t.isCompleted ? "checkmark.circle.fill":"circle")}.buttonStyle(.borderless)
                            VStack(alignment:.leading,spacing:3) {
                                Text(t.title).strikethrough(t.isCompleted)
                                HStack {
                                    Text("\(t.duration)m • \(t.priority.rawValue)")
                                    if let id=t.projectID,let p=store.projects.first(where:{$0.id==id}){Text("• \(p.name)").foregroundStyle(p.color.color)}
                                }.font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName:"chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editingTask=t }
                        .swipeActions(edge:.trailing, allowsFullSwipe:false) {
                            Button("Delete",role:.destructive){store.deleteTask(t)}
                            Button("Duplicate") { store.duplicateTask(t) }.tint(.blue)
                        }
                    }
                }.listStyle(.plain)
            }.navigationTitle("Tasks").toolbar{Button{add=true}label:{Image(systemName:"plus")}}
            .sheet(isPresented:$add){TaskEditorView(task:nil)}
            .sheet(item:$editingTask){ task in TaskEditorView(task:task) }
        }
    }
    private func taskMetric(_ label: String, _ value: Int, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
                Text("\(value)").font(.title2.bold()).foregroundStyle(.primary)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }
    private var statusSelection: TaskFilter {
        switch filter {
        case .active: return .active
        case .closed: return .closed
        default: return .all
        }
    }
    private var isProjectFilter: Bool { selectedProjectID != nil }
    private var projectFilterTitle: String {
        guard let selectedProjectID else { return "All Projects" }
        return store.projects.first(where: { $0.id == selectedProjectID })?.name ?? "Project"
    }
}

private struct TaskEditorView:View {
    @EnvironmentObject private var store:AppStore
    @Environment(\.dismiss) private var dismiss
    let task: ExecutiveTask?
    @State private var title:String
    @State private var duration:Int
    @State private var projectID:UUID?
    @State private var priority:WorkPriority
    @State private var isCompleted:Bool
    @State private var actualMinutes:Int
    @State private var happiness:Int?

    init(task: ExecutiveTask?) {
        self.task=task
        _title=State(initialValue:task?.title ?? "")
        _duration=State(initialValue:task?.duration ?? 15)
        _projectID=State(initialValue:task?.projectID)
        _priority=State(initialValue:task?.priority ?? .normal)
        _isCompleted=State(initialValue:task?.isCompleted ?? false)
        _actualMinutes=State(initialValue:task?.duration ?? 15)
        _happiness=State(initialValue:nil)
    }

    var body:some View { NavigationStack { Form {
        TextField("Task",text:$title)
        Picker("Duration",selection:$duration){ForEach([15,30,45,60,90],id:\.self){Text("\($0) min").tag($0)}}
        Picker("Project",selection:$projectID){ Text("None").tag(Optional<UUID>.none); ForEach(store.projects.filter{$0.status != .closed}){p in Text(p.name).foregroundStyle(p.color.color).tag(Optional(p.id))} }
        Picker("Priority",selection:$priority){ForEach(WorkPriority.allCases){Text($0.rawValue).tag($0)}}
        if task != nil {
            Picker("Status",selection:$isCompleted) {
                Text("Active").tag(false)
                Text("Closed").tag(true)
            }
        }
        if task != nil && isCompleted {
            Section("Completed Work") {
                Stepper("Actual time: \(actualMinutes) min", value:$actualMinutes, in:1...480, step:5)
                VStack(alignment:.leading, spacing:10) {
                    Text("How did this work feel?").font(.subheadline.weight(.semibold))
                    HStack {
                        ForEach(1...5, id:\.self) { value in
                            Button { happiness = value } label: {
                                Text(["😞","🙁","😐","🙂","😄"][value-1]).font(.title2).padding(7)
                                    .background(happiness == value ? Color.accentColor.opacity(0.18) : Color.clear, in:Circle())
                            }.buttonStyle(.plain)
                        }
                        if happiness != nil { Button("Clear") { happiness=nil }.font(.caption) }
                    }
                    Text("Optional. You can add or change this later. It only updates your local Insights history.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }.navigationTitle(task == nil ? "New Task" : "Edit Task")
    .onAppear {
        guard let task, task.isCompleted else { return }
        if let insight=store.latestInsight(for: task.id) {
            actualMinutes=insight.actualMinutes
            happiness=insight.happiness
        } else {
            actualMinutes=task.duration
        }
    }
    .toolbar {
        ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}}
        ToolbarItem(placement:.confirmationAction){Button(task == nil ? "Add" : "Save"){
            let clean=title.trimmingCharacters(in:.whitespacesAndNewlines)
            if var existing=task {
                existing.title=clean; existing.duration=duration; existing.projectID=projectID
                existing.priority=priority; existing.isCompleted=isCompleted
                store.updateTask(existing)
                if existing.isCompleted {
                    store.updateClosedTaskInsight(task: existing, actualMinutes: actualMinutes, happiness: happiness)
                }
            } else {
                store.addTask(title:clean,duration:duration,projectID:projectID,priority:priority)
            }
            dismiss()
        }.disabled(title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}
    } } }
}
