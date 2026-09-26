import SwiftUI
import UniformTypeIdentifiers

struct MoreView:View {
    @EnvironmentObject private var store:AppStore
    @EnvironmentObject private var calendar:CalendarManager
    @EnvironmentObject private var notifications:NotificationManager
    @State private var draft=AppSettings()
    @State private var confirmClearHistory=false
    @State private var confirmReset=false
    @State private var exporting=false
    @State private var importing=false
    @State private var backupDocument:AlsagierBackupDocument?
    @State private var backupMessage:String?

    var body:some View {
        NavigationStack {
            Form {
                Section("Day boundaries") {
                    Picker("Work ends",selection:$draft.workEndHour){ForEach(12...22,id:\.self){Text(time($0)).tag($0)}}
                    Picker("Personal planning until",selection:$draft.personalEndHour){ForEach(17...23,id:\.self){Text(time($0)).tag($0)}}
                }
                Section("Communication") {
                    Picker("Calls",selection:$draft.callsMinutes){ForEach([0,15,30,45,60],id:\.self){Text($0==0 ? "Off":"\($0) min").tag($0)}}
                    Picker("Email",selection:$draft.emailMinutes){ForEach([0,15,30,45,60],id:\.self){Text($0==0 ? "Off":"\($0) min").tag($0)}}
                }
                Section("Notifications") {
                    Picker("Before each block",selection:$draft.reminderMinutes){
                        Text("Off").tag(0); ForEach([2,5,10,15],id:\.self){Text("\($0) min").tag($0)}
                    }
                }
                Section("Permissions") {
                    Label(calendar.authorized ? "Calendar connected":"Calendar permission needed",systemImage:"calendar")
                    Label(notifications.authorized ? "Notifications enabled":"Notifications permission needed",systemImage:"bell")
                }
                Section("Backup") {
                    Button { backupDocument=AlsagierBackupDocument(backup:store.makeBackup()); exporting=true } label: {
                        Label("Export CapJour Backup",systemImage:"square.and.arrow.up")
                    }
                    Button { importing=true } label: {
                        Label("Restore CapJour Backup",systemImage:"square.and.arrow.down")
                    }
                    Text("Backup includes CapJour projects, tasks, habits, schedules and settings. It does not copy your iPhone Calendar or Apple Health data.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Data") {
                    Button("Clear Schedule History", role:.destructive) { confirmClearHistory=true }
                    Button("Reset CapJour", role:.destructive) { confirmReset=true }
                    Text("These actions never delete or change events in your iPhone Calendar.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Insights") {
                    NavigationLink { InsightsView() } label: { Label("Work & Emotions", systemImage:"chart.line.uptrend.xyaxis") }
                    Text("See actual work time and optional happiness patterns. Your data stays in CapJour.").font(.caption).foregroundStyle(.secondary)
                }
                Section("About") {
                    NavigationLink("About CapJour") { CapJourAboutView() }
                    Text("Version 5.1 • Build 13").foregroundStyle(.secondary)
                }
            }.navigationTitle("More")
            .onAppear{draft=store.settings}
            .onChange(of:draft){_,new in store.updateSettings(new)}
            .fileExporter(isPresented:$exporting,document:backupDocument,contentType:.json,defaultFilename:"CapJour-Backup") { result in
                if case .failure = result { backupMessage="Backup could not be exported." }
            }
            .fileImporter(isPresented:$importing,allowedContentTypes:[.json]) { result in
                do {
                    let url=try result.get()
                    guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
                    defer { url.stopAccessingSecurityScopedResource() }
                    let data=try Data(contentsOf:url)
                    let decoder=JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
                    let backup=try decoder.decode(AlsagierBackup.self,from:data)
                    store.restoreBackup(backup)
                    draft=store.settings
                    backupMessage="Backup restored successfully."
                } catch { backupMessage="This file could not be restored as a CapJour backup." }
            }
            .alert("CapJour Backup",isPresented:Binding(get:{backupMessage != nil},set:{if !$0{backupMessage=nil}})) {
                Button("OK",role:.cancel){backupMessage=nil}
            } message: { Text(backupMessage ?? "") }
            .confirmationDialog("Clear schedule history?",isPresented:$confirmClearHistory,titleVisibility:.visible) {
                Button("Clear Schedule History",role:.destructive){store.clearScheduleHistory()}
                Button("Cancel",role:.cancel){}
            } message: {
                Text("Past day plans will be deleted. Projects, Tasks, Habits and Settings stay.")
            }
            .confirmationDialog("Reset CapJour?",isPresented:$confirmReset,titleVisibility:.visible) {
                Button("Reset All CapJour Data",role:.destructive){
                    store.resetAllData(); draft=store.settings
                    Task { await notifications.refresh(for:[],minutesBefore:0); await LiveActivityManager.shared.end() }
                }
                Button("Cancel",role:.cancel){}
            } message: {
                Text("Deletes CapJour Projects, Tasks, Habits, schedules and settings. Your iPhone Calendar is not changed.")
            }
        }
    }
    private func time(_ hour:Int)->String {
        let h=hour>12 ? hour-12:hour
        return "\(h):00 \(hour>=12 ? "PM":"AM")"
    }
}


private struct CapJourAboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CapJour").font(.largeTitle.bold())
                    Text("Your day. Your direction.").font(.title3).foregroundStyle(.secondary)
                }

                Text("CapJour is a personal daily companion that helps you organize your time around what matters.")
                Text("It brings together your calendar, projects, tasks, habits, prayer times, and available time to build a realistic day — then adjusts as your day changes.")

                VStack(alignment: .leading, spacing: 10) {
                    Label("Calendar tells CapJour where you need to be.", systemImage: "calendar")
                    Label("Prayer protects your time.", systemImage: "moon.stars.fill")
                    Label("Projects define what matters.", systemImage: "folder.fill")
                    Label("Tasks define what needs to be done.", systemImage: "checkmark.circle")
                    Label("CapJour helps you decide what to do now.", systemImage: "arrow.right.circle.fill")
                }

                Text("Designed to reduce planning and help you focus on doing.")

                Divider()
                Text("Why CapJour?").font(.headline)
                Text("Inspired by the French words Cap — direction — and Jour — day. The direction of your day.")

                Divider()
                Text("CapJour by Softfm").font(.headline)
                Text("Version 5.1 • Build 13").foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("About CapJour")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InsightsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var range = 7
    private var cutoff: Date? { range == 0 ? nil : Calendar.current.date(byAdding:.day,value:-range,to:Date()) }
    private var rows: [WorkInsight] { store.insights.filter { cutoff == nil || $0.date >= cutoff! } }
    private var rated: [WorkInsight] { rows.filter { $0.happiness != nil } }
    private var totalMinutes: Int { rows.reduce(0) { $0 + $1.actualMinutes } }
    private var avg: Double? { rated.isEmpty ? nil : Double(rated.compactMap(\.happiness).reduce(0,+))/Double(rated.count) }
    private var grouped: [(String,Int,Double?)] {
        Dictionary(grouping: rows, by: \.projectName).map { name, items in
            let rs=items.compactMap(\.happiness)
            return (name, items.reduce(0){$0+$1.actualMinutes}, rs.isEmpty ? nil : Double(rs.reduce(0,+))/Double(rs.count))
        }.sorted{$0.1>$1.1}
    }
    var body: some View {
        List {
            Section { Picker("Range",selection:$range){ Text("7 Days").tag(7); Text("30 Days").tag(30); Text("All Time").tag(0) }.pickerStyle(.segmented) }
            Section("Overview") {
                LabeledContent("Actual work time",value:format(totalMinutes))
                LabeledContent("Average happiness",value:avg.map{String(format:"%.1f / 5",$0)} ?? "—")
                LabeledContent("Completed work blocks",value:"\(rows.count)")
            }
            Section("Projects") {
                if grouped.isEmpty { Text("Complete project work to start building Insights.").foregroundStyle(.secondary) }
                ForEach(grouped,id:\.0) { item in
                    VStack(alignment:.leading,spacing:5) {
                        Text(item.0).font(.headline)
                        Text("\(format(item.1)) • Happiness \(item.2.map{String(format:"%.1f/5",$0)} ?? "—")").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Recent") {
                ForEach(rows.sorted{$0.date>$1.date}.prefix(30)) { item in
                    VStack(alignment:.leading,spacing:4) {
                        Text(item.taskName ?? item.projectName)
                        Text("\(item.actualMinutes)m actual • \(item.plannedMinutes)m planned • \(item.happiness.map{String($0)+"/5"} ?? "not rated")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("Insights")
    }
    private func format(_ m:Int)->String { m < 60 ? "\(m) min" : String(format:"%dh %02dm",m/60,m%60) }
}
