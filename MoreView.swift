import SwiftUI
import UniformTypeIdentifiers

/// Cascading entry points: each destination owns its existing functional controls.
struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { MorePreferencesView() } label: {
                        Label("Preferences & Settings", systemImage: "slider.horizontal.3")
                    }
                    NavigationLink { InsightsView() } label: {
                        Label("Insights & History", systemImage: "chart.xyaxis.line")
                    }
                }
                Section {
                    NavigationLink { CapJourAboutView() } label: {
                        Label("About CapJour", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct MorePreferencesView:View {
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
                Section("Start My Day") {
                    Toggle("Dad Jokes", isOn:$draft.dadJokesEnabled)
                    Text("One offline joke each time you start or re-open a day. No repeats until all 500 have been shown.").font(.caption).foregroundStyle(.secondary)
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
                    Text("Backup includes CapJour projects, tasks, habits, habit completion history, schedules, Insights and settings. It does not copy your iPhone Calendar or Apple Health data.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Data") {
                    Button("Clear Schedule History", role:.destructive) { confirmClearHistory=true }
                    Button("Reset CapJour", role:.destructive) { confirmReset=true }
                    Text("These actions never delete or change events in your iPhone Calendar.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Insights") {
                    NavigationLink { InsightsView() } label: { Label("Insights", systemImage:"chart.line.uptrend.xyaxis") }
                    Text("See actual work time and optional happiness patterns. Your data stays in CapJour.").font(.caption).foregroundStyle(.secondary)
                }
                Section("About") {
                    NavigationLink("About CapJour") { CapJourAboutView() }
                    Text("Version 6.0 • Build 21").foregroundStyle(.secondary)
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
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CapJour").font(.largeTitle.bold())
                        Text("Your day. Your direction.").font(.title3).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Image("AboutIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .accessibilityLabel("CapJour app icon")
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
                Text("Version 5.1 • Build 18").foregroundStyle(.secondary)
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

    private var cutoff: Date? { range == 0 ? nil : Calendar.current.date(byAdding: .day, value: -range, to: Date()) }
    private var rows: [WorkInsight] { store.insights.filter { cutoff == nil || $0.date >= cutoff! } }
    private var rated: [WorkInsight] { rows.filter { $0.happiness != nil } }
    private var totalMinutes: Int { rows.reduce(0) { $0 + $1.actualMinutes } }
    private var avgEmotion: Double? { rated.isEmpty ? nil : Double(rated.compactMap(\.happiness).reduce(0,+)) / Double(rated.count) }
    private var accuracy: Double {
        guard !rows.isEmpty else { return 0 }
        let planned = max(1, rows.reduce(0) { $0 + $1.plannedMinutes })
        let error = rows.reduce(0) { $0 + abs($1.actualMinutes - $1.plannedMinutes) }
        return max(0, min(1, 1 - Double(error) / Double(planned)))
    }
    private var relevantBlocks: [ScheduleBlock] {
        store.dayPlans.filter { cutoff == nil || $0.date >= cutoff! }.flatMap(\.blocks)
            .filter { $0.kind == .task || $0.kind == .project }
    }
    private var completion: Double {
        guard !relevantBlocks.isEmpty else { return 0 }
        return Double(relevantBlocks.filter(\.isCompleted).count) / Double(relevantBlocks.count)
    }
    private var completedCount: Int { relevantBlocks.filter(\.isCompleted).count }
    private var skippedCount: Int { relevantBlocks.filter(\.isSkipped).count }

    private var grouped: [(String, Int, Color)] {
        let projectColors = Dictionary(uniqueKeysWithValues: store.projects.map { ($0.name, $0.color.color) })
        return Dictionary(grouping: rows, by: \.projectName).map { name, items in
            (name, items.reduce(0) { $0 + $1.actualMinutes }, projectColors[name] ?? .blue)
        }.sorted { $0.1 > $1.1 }
    }

    private var week: [(String, Int, Double?)] {
        let cal = Calendar.current
        let formatter = DateFormatter(); formatter.dateFormat = "EEE"
        return (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let dayRows = rows.filter { cal.isDate($0.date, inSameDayAs: day) }
            let minutes = dayRows.reduce(0) { $0 + $1.actualMinutes }
            let scores = dayRows.compactMap(\.happiness)
            let emotion = scores.isEmpty ? nil : Double(scores.reduce(0,+)) / Double(scores.count)
            return (formatter.string(from: day), minutes, emotion)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Picker("Range", selection: $range) {
                    Text("7 Days").tag(7); Text("30 Days").tag(30); Text("All Time").tag(0)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 6) {
                    topMetric(String(format: "%.0f%%", completion * 100), "Completion", .green)
                    topMetric(String(format: "%.0f%%", accuracy * 100), "Time Accuracy", .blue)
                    topMetric(avgEmotion.map { String(format: "%.1f / 5", $0) } ?? "—", "Emotion", .orange)
                }
                .padding(.vertical, 4)

                VStack(spacing: 12) {
                    ConcentricGauge(completion: completion, accuracy: accuracy, emotion: (avgEmotion ?? 0) / 5.0)
                        .frame(width: 230, height: 230)
                        .frame(maxWidth: .infinity)
                    HStack(spacing: 18) {
                        Label("Completion", systemImage: "circle.fill").foregroundStyle(.green)
                        Label("Time Accuracy", systemImage: "circle.fill").foregroundStyle(.blue)
                        Label("Emotion", systemImage: "circle.fill").foregroundStyle(.orange)
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                }
                .padding(14)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                NavigationLink { FocusEmotionDetailView(rows: rows) } label: {
                    dashboardCard(title: "Focus & Emotion") { FocusEmotionChart(days: week) }
                }.buttonStyle(.plain)

                NavigationLink { ProjectTimeDetailView(rows: rows) } label: {
                    dashboardCard(title: "Time Breakdown") {
                        TimeBreakdownChart(items: Array(grouped.prefix(6)), totalMinutes: totalMinutes)
                    }
                }.buttonStyle(.plain)

                NavigationLink { HistoryDaysView() } label: {
                    dashboardCard(title: "Task Completion") {
                        HStack {
                            countMetric("\(completedCount)", "Completed")
                            Spacer()
                            countMetric("\(skippedCount)", "Skipped")
                            Spacer()
                            countMetric(String(format: "%.0f%%", accuracy * 100), "On Time")
                        }.padding(.horizontal, 10).padding(.bottom, 4)
                    }
                }.buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    private func topMetric(_ value: String, _ title: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title2.bold()).foregroundStyle(color).minimumScaleFactor(0.75).lineLimit(1)
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.75)
        }.frame(maxWidth: .infinity)
    }

    private func countMetric(_ value: String, _ title: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title2.bold()).foregroundStyle(.primary)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }

    private func dashboardCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text(title).font(.title3.bold()); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }
            content()
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct FocusEmotionChart: View {
    let days: [(String, Int, Double?)]
    private var maxMinutes: Int { max(60, days.map(\.1).max() ?? 60) }
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width / CGFloat(max(1, days.count))
                ZStack(alignment: .bottomLeading) {
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                            VStack { Spacer(); RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.38)).frame(width: min(26, w * 0.55), height: max(2, geo.size.height * CGFloat(d.1) / CGFloat(maxMinutes))) }
                                .frame(width: w)
                        }
                    }
                    Path { p in
                        var started = false
                        for (i,d) in days.enumerated() {
                            guard let e = d.2 else { continue }
                            let x = w * (CGFloat(i) + 0.5)
                            let y = geo.size.height * (1 - CGFloat(max(1,min(5,e)) - 1) / 4)
                            if !started { p.move(to: CGPoint(x:x,y:y)); started = true } else { p.addLine(to: CGPoint(x:x,y:y)) }
                        }
                    }.stroke(Color.orange, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    ForEach(Array(days.enumerated()), id: \.offset) { i,d in
                        if let e=d.2 {
                            Circle().fill(Color(.systemBackground)).stroke(Color.orange,lineWidth:2).frame(width:9,height:9)
                                .position(x:w*(CGFloat(i)+0.5), y:geo.size.height*(1-CGFloat(max(1,min(5,e))-1)/4))
                        }
                    }
                }
            }.frame(height: 118)
            HStack(spacing: 0) { ForEach(Array(days.enumerated()),id:\.offset) { _,d in Text(d.0).font(.caption2).foregroundStyle(.secondary).frame(maxWidth:.infinity) } }
            HStack(spacing:18) { Label("Focus Time",systemImage:"circle.fill").foregroundStyle(.blue); Label("Emotion Rating",systemImage:"circle.fill").foregroundStyle(.orange) }.font(.caption)
        }
    }
}

private struct TimeBreakdownChart: View {
    let items: [(String, Int, Color)]
    let totalMinutes: Int
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.12), lineWidth: 18)
                ForEach(Array(items.enumerated()), id: \.offset) { i,item in
                    let before = items.prefix(i).reduce(0) { $0 + $1.1 }
                    let denom = max(1,totalMinutes)
                    Circle().trim(from: CGFloat(before)/CGFloat(denom), to: CGFloat(before+item.1)/CGFloat(denom))
                        .stroke(item.2, style: StrokeStyle(lineWidth:18,lineCap:.butt)).rotationEffect(.degrees(-90))
                }
                VStack(spacing:0) { Text(formatMinutes(totalMinutes)).font(.headline.bold()); Text("Total Focus").font(.caption2).foregroundStyle(.secondary) }
            }.frame(width: 126, height: 126)
            VStack(alignment:.leading,spacing:7) {
                if items.isEmpty { Text("Project time will appear after completed work.").font(.caption).foregroundStyle(.secondary) }
                ForEach(Array(items.prefix(6).enumerated()), id:\.offset) { _,item in
                    HStack(spacing:7) { Circle().fill(item.2).frame(width:9,height:9); Text(item.0).font(.caption).lineLimit(1); Spacer(); Text(formatMinutes(item.1)).font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
    }
    private func formatMinutes(_ m:Int)->String { m < 60 ? "\(m)m" : (m % 60 == 0 ? "\(m/60)h" : "\(m/60)h \(m%60)m") }
}

private struct FocusEmotionDetailView: View {
    let rows:[WorkInsight]
    var body: some View { List(rows.sorted{$0.date>$1.date}) { r in VStack(alignment:.leading){Text(r.taskName ?? r.projectName).font(.headline);Text("\(r.actualMinutes) min" + (r.happiness.map{" • \($0)/5"} ?? "")).font(.caption).foregroundStyle(.secondary)} }.navigationTitle("Focus & Emotion") }
}
private struct ProjectTimeDetailView: View {
    let rows:[WorkInsight]
    var body: some View { List { ForEach(Dictionary(grouping:rows,by:\.projectName).map{($0.key,$0.value.reduce(0){$0+$1.actualMinutes})}.sorted{$0.1>$1.1},id:\.0){ item in HStack{Text(item.0);Spacer();Text("\(item.1) min").foregroundStyle(.secondary)} } }.navigationTitle("Time Breakdown") }
}


private struct HistoryDaysView: View {
    @EnvironmentObject private var store: AppStore
    private var plans:[DayPlan] { store.dayPlans.sorted { $0.date > $1.date } }
    private var flexibleBlocks:[ScheduleBlock] { plans.flatMap(\.blocks).filter { $0.kind == .task || $0.kind == .project || $0.kind == .habit } }
    private var totalCompleted:Int { flexibleBlocks.filter(\.isCompleted).count }
    private var totalSkipped:Int { flexibleBlocks.filter(\.isSkipped).count }
    private var totalMinutes:Int { flexibleBlocks.filter(\.isCompleted).reduce(0) { $0 + $1.durationMinutes } }
    var body: some View {
        List {
            Section {
                historyTotals(days: plans.count, completed: totalCompleted, skipped: totalSkipped, minutes: totalMinutes)
                    .listRowInsets(EdgeInsets(top:10,leading:12,bottom:10,trailing:12))
            }
            Section("Days") {
                ForEach(plans) { plan in
                    NavigationLink { HistoryDayDetailView(plan:plan) } label: {
                        VStack(alignment:.leading,spacing:5) {
                            Text(plan.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).font(.headline)
                            let flexible = plan.blocks.filter { $0.kind == .task || $0.kind == .project || $0.kind == .habit }
                            let done = flexible.filter(\.isCompleted).count
                            let skipped = flexible.filter(\.isSkipped).count
                            let mins = flexible.filter(\.isCompleted).reduce(0) { $0 + $1.durationMinutes }
                            Text("\(done) completed • \(skipped) skipped • \(format(mins))")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical,3)
                    }
                }
            }
        }.navigationTitle("Past Days")
    }
    private func historyTotals(days:Int,completed:Int,skipped:Int,minutes:Int)->some View {
        HStack(spacing:6) {
            historyTotal("\(days)", "Days")
            historyTotal("\(completed)", "Completed")
            historyTotal("\(skipped)", "Skipped")
            historyTotal(format(minutes), "Focus")
        }
    }
    private func historyTotal(_ value:String,_ title:String)->some View {
        VStack(spacing:3) { Text(value).font(.headline.bold()).minimumScaleFactor(0.7).lineLimit(1); Text(title).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }.frame(maxWidth:.infinity)
    }
    private func format(_ m:Int)->String { m < 60 ? "\(m)m" : String(format:"%dh %02dm",m/60,m%60) }
}

private struct HistoryDayDetailView: View {
    let plan: DayPlan
    var body: some View {
        List {
            Section("Day Summary") {
                LabeledContent("Started", value: plan.startedAt.formatted(date:.omitted,time:.shortened))
                if let ended = plan.endedAt { LabeledContent("Ended", value: ended.formatted(date:.omitted,time:.shortened)) }
                LabeledContent("Blocks", value:"\(plan.blocks.count)")
            }
            Section("Final Timeline") {
                ForEach(plan.blocks.sorted{$0.start<$1.start}) { block in
                    HStack(alignment:.top,spacing:10) {
                        Image(systemName:block.kind.icon).foregroundStyle(block.color).frame(width:22)
                        VStack(alignment:.leading,spacing:3) {
                            HStack { Text(block.title).font(.headline); Spacer(); status(block) }
                            if let sub=block.subtitle, !sub.isEmpty { Text(sub).font(.caption).foregroundStyle(.secondary) }
                            Text("\(block.start.formatted(date:.omitted,time:.shortened)) – \(block.end.formatted(date:.omitted,time:.shortened))")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical,2)
                }
            }
        }.navigationTitle(plan.date.formatted(date:.abbreviated,time:.omitted))
    }
    @ViewBuilder private func status(_ b:ScheduleBlock)->some View {
        if b.isCompleted { Image(systemName:"checkmark.circle.fill").foregroundStyle(.green) }
        else if b.isSkipped { Image(systemName:"forward.circle.fill").foregroundStyle(.orange) }
    }
}

private struct ConcentricGauge: View {
    let completion:Double, accuracy:Double, emotion:Double
    var body: some View {
        ZStack {
            ring(value:completion,width:15,color:.green).padding(6)
            ring(value:accuracy,width:15,color:.blue).padding(31)
            ring(value:emotion,width:15,color:.orange).padding(56)
            VStack(spacing:2) { Text(emotion > 0 ? String(format:"%.1f",emotion*5) : "—").font(.system(size:34,weight:.bold,design:.rounded)); Text("EMOTION").font(.caption2.bold()).foregroundStyle(.secondary) }
        }.accessibilityElement(children:.ignore).accessibilityLabel("Completion \(Int(completion*100)) percent, time accuracy \(Int(accuracy*100)) percent, emotion \(String(format:"%.1f",emotion*5)) out of 5")
    }
    private func ring(value:Double,width:CGFloat,color:Color)->some View {
        ZStack { Circle().stroke(Color.secondary.opacity(0.14),lineWidth:width); Circle().trim(from:0,to:max(0,min(1,value))).stroke(color,style:StrokeStyle(lineWidth:width,lineCap:.round)).rotationEffect(.degrees(-90)) }
    }
}

private extension View {
    func sectionCard()->some View { self.padding().frame(maxWidth:.infinity,alignment:.leading).background(Color(.systemBackground),in:RoundedRectangle(cornerRadius:18)) }
}
