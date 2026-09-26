import SwiftUI

private enum TaskFilter: Hashable { case all, active, closed, project(UUID) }

struct TasksView: View {
    @EnvironmentObject private var store:AppStore
    @State private var add=false
    @State private var filter: TaskFilter = .all
    @State private var editingTask: ExecutiveTask?

    private var visible: [ExecutiveTask] {
        switch filter {
        case .all: return store.tasks
        case .active: return store.tasks.filter { !$0.isCompleted }
        case .closed: return store.tasks.filter { $0.isCompleted }
        case .project(let id): return store.tasks.filter { $0.projectID == id }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing:0) {
                ScrollView(.horizontal, showsIndicators:false) {
                    HStack(spacing:8) {
                        chip("All", .all); chip("Active", .active); chip("Closed", .closed)
                        Menu {
                            ForEach(store.projects) { p in Button(p.name) { filter = .project(p.id) } }
                        } label: {
                            Label(projectFilterTitle, systemImage:"folder").padding(.horizontal,12).padding(.vertical,7)
                                .background(isProjectFilter ? Color.accentColor.opacity(0.16) : Color(.secondarySystemBackground), in:Capsule())
                        }
                    }.padding(.horizontal).padding(.vertical,8)
                }
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
    private func chip(_ title:String,_ value:TaskFilter)->some View {
        Button(title){filter=value}.buttonStyle(.plain).font(.subheadline.weight(.semibold))
            .padding(.horizontal,12).padding(.vertical,7)
            .background(filter == value ? Color.accentColor.opacity(0.16) : Color(.secondarySystemBackground),in:Capsule())
    }
    private var isProjectFilter:Bool { if case .project = filter{return true}; return false }
    private var projectFilterTitle:String {
        if case .project(let id)=filter { return store.projects.first(where:{$0.id==id})?.name ?? "Project" }
        return "Project"
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

    init(task: ExecutiveTask?) {
        self.task=task
        _title=State(initialValue:task?.title ?? "")
        _duration=State(initialValue:task?.duration ?? 15)
        _projectID=State(initialValue:task?.projectID)
        _priority=State(initialValue:task?.priority ?? .normal)
        _isCompleted=State(initialValue:task?.isCompleted ?? false)
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
    }.navigationTitle(task == nil ? "New Task" : "Edit Task").toolbar {
        ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}}
        ToolbarItem(placement:.confirmationAction){Button(task == nil ? "Add" : "Save"){
            let clean=title.trimmingCharacters(in:.whitespacesAndNewlines)
            if var existing=task {
                existing.title=clean; existing.duration=duration; existing.projectID=projectID
                existing.priority=priority; existing.isCompleted=isCompleted
                store.updateTask(existing)
            } else {
                store.addTask(title:clean,duration:duration,projectID:projectID,priority:priority)
            }
            dismiss()
        }.disabled(title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}
    } } }
}
