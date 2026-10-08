import Charts
import SwiftUI
import UniformTypeIdentifiers

struct MoreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CapJour").font(.title2.bold())
                        Text("Your day. Your direction.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

                    moreRow("Insights & Intelligence", subtitle: "Performance, emotion and work patterns", icon: "chart.xyaxis.line", color: .blue) {
                        MoreInsightsMenu()
                    }
                    moreRow("Planning Preferences", subtitle: "Work hours, reminders and settings", icon: "slider.horizontal.3", color: .teal) {
                        MoreSettingsView()
                    }
                    moreRow("Health & Connections", subtitle: "Apple Health and connected permissions", icon: "heart.text.square", color: .pink) {
                        MoreHealthMenu()
                    }
                    moreRow("Data & History", subtitle: "Backup, restore and data controls", icon: "externaldrive", color: .purple) {
                        MoreDataHistoryView()
                    }
                    moreRow("About CapJour", subtitle: "Purpose, privacy and app version", icon: "info.circle", color: .gray) {
                        CapJourAboutView()
                    }
                }.padding()
            }
            .navigationTitle("More")
        }
    }

    private func moreRow<Destination: View>(_ title: String, subtitle: String, icon: String, color: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding(13)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }
}

private struct MoreInsightsMenu: View {
    var body: some View {
        List {
            NavigationLink { InsightsView() } label: { Label("Insights Dashboard", systemImage: "chart.bar.xaxis") }
            NavigationLink { UnratedEmotionView() } label: { Label("Emotion Check-in", systemImage: "face.smiling") }
            NavigationLink { WeeklyReviewView() } label: { Label("Weekly Review", systemImage: "calendar.badge.clock") }
            NavigationLink { HistoricalCorrectionsView() } label: { Label("Correct Past Completions", systemImage: "arrow.uturn.backward.circle") }
            NavigationLink { PersonalEnergyView() } label: { Label("Personal Energy", systemImage: "heart.text.square") }
        }
        .navigationTitle("Insights & Intelligence")
    }
}

private struct MoreHealthMenu: View {
    var body: some View {
        List {
            Label("Apple Health", systemImage: "heart.text.square")
            Text("CapJour reads only the health measurements you authorize. Health-based recommendations are not yet enabled in this development checkpoint.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Health & Connections")
    }
}

private struct UnratedEmotionView: View {
    @EnvironmentObject private var store: AppStore
    private var missing: [WorkInsight] {
        store.insights.filter { $0.happiness == nil }.sorted { $0.date > $1.date }
    }
    var body: some View {
        List {
            if missing.isEmpty {
                ContentUnavailableView("All Caught Up", systemImage: "checkmark.circle", description: Text("All recorded work sessions have an emotion rating."))
            }
            ForEach(missing) { insight in
                VStack(alignment: .leading, spacing: 10) {
                    Text(insight.taskName ?? insight.projectName).font(.headline)
                    Text(insight.date, style: .date).font(.caption).foregroundStyle(.secondary)
                    HStack {
                        ForEach(1...5, id: \.self) { rating in
                            Button { store.setHappiness(for: insight.id, rating: rating) } label: {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Rate \(rating) of 5")
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("Emotion Check-in")
    }
}

private struct MoreSettingsView:View {
    @AppStorage("capjour.interfaceLanguage") private var interfaceLanguage = "automatic"
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
        Form {
                Section("Language / اللغة") {
                    Picker("App Language / لغة التطبيق", selection: $interfaceLanguage) {
                        Text("Automatic / تلقائي").tag("automatic")
                        Text("English").tag("english")
                        Text("العربية").tag("arabic")
                    }
                    Text("Language preference is saved separately from projects and tasks.")
                        .font(.caption).foregroundStyle(.secondary)
                }
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
            }.navigationTitle("Planning & Settings")
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
    private func time(_ hour:Int)->String {
        let h=hour>12 ? hour-12:hour
        return "\(h):00 \(hour>=12 ? "PM":"AM")"
    }
}


private struct MoreDataHistoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var exporting = false
    @State private var importing = false
    @State private var document: AlsagierBackupDocument?
    @State private var message: String?
    @State private var confirmClear = false
    var body: some View {
        List {
            Section("History") {
                NavigationLink { HistoryDaysView() } label: { Label("Past Days / Schedule History", systemImage: "calendar") }
            }
            Section("Backup") {
                Button { document = AlsagierBackupDocument(backup: store.makeBackup()); exporting = true } label: { Label("Export CapJour Backup", systemImage: "square.and.arrow.up") }
                Button { importing = true } label: { Label("Restore CapJour Backup", systemImage: "square.and.arrow.down") }
                Text("Apple Health and iPhone Calendar data are not included in backups.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Data controls") {
                Button("Clear Schedule History", role: .destructive) { confirmClear = true }
            }
        }
        .navigationTitle("Data & History")
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "CapJour-Backup") { result in
            if case .failure = result { message = "Backup could not be exported." }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
                store.restoreBackup(try decoder.decode(AlsagierBackup.self, from: data))
                message = "Backup restored successfully."
            } catch { message = "This file could not be restored as a CapJour backup." }
        }
        .alert("CapJour Backup", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) { message = nil }
        } message: { Text(message ?? "") }
        .confirmationDialog("Clear schedule history?", isPresented: $confirmClear) {
            Button("Clear Schedule History", role: .destructive) { store.clearScheduleHistory() }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Past day plans will be deleted. Projects, tasks, habits and settings stay.") }
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
                Text("Version 6.0 • Build 21").foregroundStyle(.secondary)
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

                VStack {
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

// Review is calculated from recorded sessions; missing emotion is not scored as negative.
private struct WeeklyReviewView: View {
    @EnvironmentObject private var store: AppStore
    private var sessions: [WorkInsight] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return store.insights.filter { $0.date >= start }
    }
    var body: some View {
        List {
            Section("Last 7 days") {
                LabeledContent("Completed work sessions", value: "\(sessions.count)")
                LabeledContent("Recorded focus time", value: "\(sessions.reduce(0) { $0 + $1.actualMinutes }) minutes")
                LabeledContent("Unrated sessions", value: "\(sessions.filter { $0.happiness == nil }.count)")
                if let mean = averageEmotion {
                    LabeledContent("Average emotion", value: String(format: "%.1f / 5", mean))
                }
            }
            Section("Habits") {
                let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let completed = store.habitCompletions.filter { $0.date >= start }
                LabeledContent("Habit completions", value: "\(completed.count)")
                LabeledContent("Distinct habits", value: "\(Set(completed.map(\.habitID)).count)")
                Text("Completions are counted from recorded occurrences, not free calendar slots.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Duration suggestions — you decide") {
                ForEach(store.tasks.filter { !$0.isCompleted }) { task in
                    if let minutes = store.suggestedDuration(for: task) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.title)
                                Text("Current \(task.duration) min · Suggested \(minutes) min")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Apply") { store.acceptSuggestedDuration(taskID: task.id, minutes: minutes) }
                        }
                    }
                }
                Text("Based on at least three recorded sessions. No duration changes without tapping Apply.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Time accuracy") {
                let planned = sessions.reduce(0) { $0 + $1.plannedMinutes }
                let actual = sessions.reduce(0) { $0 + $1.actualMinutes }
                Text("Planned: \(planned) min · Actual: \(actual) min")
                if sessions.count >= 3 && planned > 0 {
                    Text(actual > planned ? "Your recorded sessions took longer than planned. Consider reviewing future estimates." : "Your recorded sessions generally fit within planned time.")
                } else {
                    Text("More completed sessions are needed before making a duration suggestion.")
                }
            }
            Section("How to read this") {
                Text("This review uses completed CapJour sessions only. It does not infer stress or health conditions.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Weekly Review")
    }
    private var averageEmotion: Double? {
        let ratings = sessions.compactMap(\.happiness)
        return ratings.isEmpty ? nil : Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
}

private struct PersonalEnergyView: View {
    @State private var searchText = ""
    @State private var selectedRange = 30
    @State private var showAllSessions = false
    private var filteredSessions: [EnergySession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedRange, to: Date()) ?? .distantPast
        return analyzer.report.sessions.filter { $0.date >= cutoff && (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)) }
    }
    @EnvironmentObject private var store: AppStore
    @StateObject private var analyzer = EnergyHealthAnalyzer()
    private var usable: [EnergySession] { analyzer.report.sessions.filter { $0.averageBPM != nil && !$0.workoutOverlap && $0.samples >= 3 } }
    var body: some View {
        List {
            Section("Apple Health") {
                if analyzer.loading { ProgressView("Analyzing recent sessions…") }
                if let message = analyzer.report.message { Text(message).foregroundStyle(.secondary) }
                if let hours = analyzer.report.sleepHours {
                    Text("Recorded sleep in the past 24 hours: \(hours, specifier: "%.1f") hours")
                } else { Text("No recent sleep samples available").foregroundStyle(.secondary) }
                Button("Refresh Health Analysis") { Task { await analyzer.analyze(store.insights) } }
            }
            Section("Sleep & recorded emotion") {
                if let comparison = analyzer.report.sleepComparison {
                    Text(comparison)
                }
                Text("Sleep readings and ratings are observational and may be affected by other factors.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Overview") {
                Picker("Period", selection: $selectedRange) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                }.pickerStyle(.segmented)
                HStack {
                    VStack(alignment: .leading) { Text("Sessions").font(.caption); Text("\(filteredSessions.count)").font(.title2.bold()) }
                    Spacer()
                    VStack(alignment: .leading) { Text("HR matched").font(.caption); Text("\(filteredSessions.filter { $0.averageBPM != nil }.count)").font(.title2.bold()) }
                }
                if !filteredSessions.filter({ $0.averageBPM != nil }).isEmpty {
                    Chart(filteredSessions.filter { $0.averageBPM != nil }.sorted { $0.date < $1.date }) { session in
                        if let bpm = session.averageBPM {
                            PointMark(x: .value("Date", session.date), y: .value("BPM", bpm))
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(height: 190)
                    .accessibilityLabel("Heart rate by work session")
                } else {
                    Text("No heart-rate readings matched the selected sessions. Check Apple Health permissions and recording times.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Work sessions & heart rate") {
                TextField("Search sessions", text: $searchText)
                if filteredSessions.isEmpty { Text("No matching sessions in the selected period.").foregroundStyle(.secondary) }
                ForEach(Array(filteredSessions.prefix(showAllSessions ? filteredSessions.count : 20))) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title).font(.headline)
                        Text(session.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        if let bpm = session.averageBPM {
                            Text("Average sampled heart rate: \(bpm, specifier: "%.0f") bpm · \(session.samples) readings")
                        } else { Text("No matching heart-rate readings").foregroundStyle(.secondary) }
                        if session.workoutOverlap { Label("Workout overlap — excluded from comparisons", systemImage: "figure.run").font(.caption).foregroundStyle(.orange) }
                    }
                }
            }
            if filteredSessions.count > 20 && !showAllSessions {
                Button("Show more sessions (\(filteredSessions.count - 20) remaining)") { showAllSessions = true }
            }
            Section("What we noticed") {
                if usable.count < 5 {
                    Text("Early observation: at least five work sessions with three or more heart-rate readings and no overlapping workout are needed before comparing patterns.")
                } else {
                    let morning = usable.filter { Calendar.current.component(.hour, from: $0.date) < 12 }
                    let later = usable.filter { Calendar.current.component(.hour, from: $0.date) >= 12 }
                    if morning.count >= 3 && later.count >= 3 {
                        let a = morning.compactMap(\.averageBPM).reduce(0,+) / Double(morning.count)
                        let b = later.compactMap(\.averageBPM).reduce(0,+) / Double(later.count)
                        Text("Morning: \(a, specifier: "%.0f") bpm (\(morning.count) sessions); later: \(b, specifier: "%.0f") bpm (\(later.count) sessions).")
                        Text("Emerging observation, not a stress diagnosis. Activity, sleep, caffeine and other factors can affect heart rate. Compare similar tasks before adjusting your schedule.")
                    } else {
                        Text("More comparable morning and later sessions are needed to identify a time-of-day pattern.")
                    }
                }
            }
            Section("Privacy & interpretation") {
                Text("CapJour reads authorized Apple Health data only. Missing data does not mean zero heart rate or poor sleep. WHOOP measurements appear only when shared with Apple Health. No automatic scheduling changes are made.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Personal Energy")
        .task { await analyzer.analyze(store.insights) }
    }
}


private struct HistoricalCorrectionsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var reason = "Accidental completion"
    @State private var confirmation: UUID?
    private var candidates: [(DayPlan, ScheduleBlock)] {
        store.dayPlans.filter { !Calendar.current.isDateInToday($0.date) }.flatMap { plan in
            plan.blocks.filter { $0.isCompleted && ($0.kind == .task || $0.kind == .project || $0.kind == .habit) }
                .map { (plan, $0) }
        }.sorted { $0.0.date > $1.0.date }
    }
    var body: some View {
        List {
            Section("Correction reason") {
                TextField("Reason", text: $reason)
                Text("Past timelines are preserved. Corrections are recorded with their time and reason.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Completed historical sessions") {
                ForEach(candidates.indices, id: \.self) { index in
                    let (plan, block) = candidates[index]
                    HStack {
                        VStack(alignment: .leading) {
                            Text(block.title)
                            Text(plan.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Correct") { confirmation = block.id }
                            .buttonStyle(.bordered)
                            .confirmationDialog("Correct this historical completion?", isPresented: Binding(
                                get: { confirmation == block.id },
                                set: { if !$0 { confirmation = nil } }
                            )) {
                                Button("Mark Not Done", role: .destructive) {
                                    _ = store.correctHistoricalCompletion(planID: plan.id, blockID: block.id, reason: reason)
                                    confirmation = nil
                                }
                            }
                    }
                }
            }
            Section("Correction log") {
                ForEach(store.correctionHistory.reversed()) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.reason)
                        Text(entry.correctedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Past Corrections")
    }
}
