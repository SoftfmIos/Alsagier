import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store:AppStore
    @State private var add=false
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.tasks) { t in
                    HStack {
                        Button{store.toggleTask(t)}label:{Image(systemName:t.isCompleted ? "checkmark.circle.fill":"circle")}.buttonStyle(.borderless)
                        VStack(alignment:.leading,spacing:3) {
                            Text(t.title).strikethrough(t.isCompleted)
                            HStack {
                                Text("\(t.duration)m • \(t.priority.rawValue)")
                                if let id=t.projectID,let p=store.projects.first(where:{$0.id==id}){Text("• \(p.name)").foregroundStyle(p.color.color)}
                            }.font(.caption).foregroundStyle(.secondary)
                        }
                    }.swipeActions{Button("Delete",role:.destructive){store.deleteTask(t)}}
                }
            }.navigationTitle("Tasks").toolbar{Button{add=true}label:{Image(systemName:"plus")}}
            .sheet(isPresented:$add){AddTaskView()}
        }
    }
}
private struct AddTaskView:View {
    @EnvironmentObject private var store:AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var title=""
    @State private var duration=15
    @State private var projectID:UUID?
    @State private var priority=WorkPriority.normal
    var body:some View {
        NavigationStack {
            Form {
                TextField("Task",text:$title)
                Picker("Duration",selection:$duration){ForEach([15,30,45,60,90],id:\.self){Text("\($0) min").tag($0)}}
                Picker("Project",selection:$projectID){
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(store.projects.filter{$0.status != .closed}){ p in
                        Text(p.name).foregroundStyle(p.color.color).tag(Optional(p.id))
                    }
                }
                Picker("Priority",selection:$priority){ForEach(WorkPriority.allCases){Text($0.rawValue).tag($0)}}
            }.navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}}
                ToolbarItem(placement:.confirmationAction){Button("Add"){store.addTask(title:title,duration:duration,projectID:projectID,priority:priority);dismiss()}.disabled(title.isEmpty)}
            }
        }
    }
}
