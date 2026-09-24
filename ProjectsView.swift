import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editing: Project?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.projects) { p in
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
                    .swipeActions { Button("Delete",role:.destructive){store.deleteProject(p)} }
                }
            }
            .navigationTitle("Projects")
            .toolbar { Button{editing=Project(name:"")}label:{Image(systemName:"plus")} }
            .sheet(item:$editing){ProjectEditor(project:$0)}
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
                Picker("Status",selection:$project.status){ForEach(ProjectStatus.allCases){Text($0.rawValue).tag($0)}}
                Picker("Priority",selection:$project.priority){ForEach(WorkPriority.allCases){Text($0.rawValue).tag($0)}}
                Picker("Mode",selection:$project.mode){ForEach(ProjectMode.allCases){Text($0.rawValue).tag($0)}}
                Picker("Daily allocation",selection:$project.dailyMinutes){ForEach([15,30,45,60,90,120],id:\.self){Text("\($0) min").tag($0)}}
                if project.mode == .continuous {
                    Picker("Focus block",selection:$project.preferredBlockMinutes){ForEach([15,30,45,60,90],id:\.self){Text("\($0) min").tag($0)}}
                }
                Picker("Color",selection:$project.color){ForEach(ProjectColor.projectChoices){Text($0.rawValue.capitalized).foregroundStyle($0.color).tag($0)}}
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
