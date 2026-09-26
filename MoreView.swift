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
                Section("Start My Day") {
                    Toggle("Dad Jokes", isOn:$draft.dadJokesEnabled)
                    Text("One offline joke per day. No repeats until all 500 have been shown.").font(.caption).foregroundStyle(.secondary)
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
                    NavigationLink { InsightsView() } label: { Label("Insights", systemImage:"chart.line.uptrend.xyaxis") }
                    Text("See actual work time and optional happiness patterns. Your data stays in CapJour.").font(.caption).foregroundStyle(.secondary)
                }
                Section("About") {
                    NavigationLink("About CapJour") { CapJourAboutView() }
                    Text("Version 5.1 • Build 15").foregroundStyle(.secondary)
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
                Text("Version 5.1 • Build 15").foregroundStyle(.secondary)
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
    private var avgEmotion: Double? { rated.isEmpty ? nil : Double(rated.compactMap(\.happiness).reduce(0,+))/Double(rated.count) }
    private var accuracy: Double {
        guard !rows.isEmpty else { return 0 }
        let planned=max(1,rows.reduce(0){$0+$1.plannedMinutes})
        let error=rows.reduce(0){$0+abs($1.actualMinutes-$1.plannedMinutes)}
        return max(0,min(1,1-Double(error)/Double(planned)))
    }
    private var relevantBlocks:[ScheduleBlock] {
        store.dayPlans.filter { cutoff == nil || $0.date >= cutoff! }.flatMap(\.blocks)
            .filter { $0.kind == .task || $0.kind == .project }
    }
    private var completion: Double {
        guard !relevantBlocks.isEmpty else { return 0 }
        return Double(relevantBlocks.filter(\.isCompleted).count)/Double(relevantBlocks.count)
    }
    private var grouped: [(String,Int,Int,Double?)] {
        Dictionary(grouping: rows, by: \.projectName).map { name, items in
            let rs=items.compactMap(\.happiness)
            return (name,items.reduce(0){$0+$1.actualMinutes},items.count,rs.isEmpty ? nil : Double(rs.reduce(0,+))/Double(rs.count))
        }.sorted{$0.1>$1.1}
    }
    private var hourly:[(Int,Double,Int)] {
        // Weight each rating by the actual minutes worked inside each clock hour.
        // A 9:45–11:15 session contributes 15m to 9, 60m to 10 and 15m to 11.
        var weighted: [Int:(scoreMinutes:Double, minutes:Int, sessions:Set<UUID>)] = [:]
        let cal = Calendar.current
        for item in rated {
            guard let happiness = item.happiness else { continue }
            let start = item.startedAt ?? item.date
            let duration = max(1, item.actualMinutes)
            let end = start.addingTimeInterval(Double(duration * 60))
            var cursor = start
            while cursor < end {
                guard let hourInterval = cal.dateInterval(of: .hour, for: cursor) else { break }
                let segmentEnd = min(end, hourInterval.end)
                let minutes = max(1, Int(segmentEnd.timeIntervalSince(cursor) / 60.0))
                let hour = cal.component(.hour, from: cursor)
                var bucket = weighted[hour] ?? (0, 0, Set<UUID>())
                bucket.scoreMinutes += Double(happiness * minutes)
                bucket.minutes += minutes
                bucket.sessions.insert(item.id)
                weighted[hour] = bucket
                cursor = segmentEnd
            }
        }
        return weighted.map { hour, bucket in
            (hour, bucket.minutes > 0 ? bucket.scoreMinutes / Double(bucket.minutes) : 0, bucket.sessions.count)
        }.sorted { $0.0 < $1.0 }
    }
    private var qualifiedHourly:[(Int,Double,Int)] { hourly.filter { $0.2 >= 3 } }
    private var bestHour:(Int,Double,Int)? { qualifiedHourly.max { $0.1 < $1.1 } }
    private var lowHour:(Int,Double,Int)? { qualifiedHourly.min { $0.1 < $1.1 } }

    var body: some View {
        ScrollView {
            VStack(spacing:18) {
                Picker("Range",selection:$range){ Text("7 Days").tag(7); Text("30 Days").tag(30); Text("All Time").tag(0) }.pickerStyle(.segmented)

                VStack(spacing:14) {
                    ConcentricGauge(completion:completion,accuracy:accuracy,emotion:(avgEmotion ?? 0)/5)
                        .frame(height:220)
                    HStack {
                        gaugeNumber("Completion", String(format:"%.0f%%",completion*100), color:.green)
                        Spacer(); gaugeNumber("Time Accuracy",String(format:"%.0f%%",accuracy*100), color:.blue)
                        Spacer(); gaugeNumber("Emotion",avgEmotion.map{String(format:"%.1f/5",$0)} ?? "—", color:.orange)
                    }
                    Divider()
                    HStack { metric("Actual Work",format(totalMinutes)); Spacer(); metric("Completed", "\(rows.count)"); Spacer(); metric("Rated","\(rated.count)") }
                }.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:18))

                VStack(alignment:.leading,spacing:12) {
                    Text("When Do I Feel Best?").font(.title3.bold())
                    if hourly.isEmpty { Text("Rate completed work to reveal your time-of-day pattern.").foregroundStyle(.secondary) }
                    else {
                        if qualifiedHourly.isEmpty {
                            Text("Best and Lowest appear after at least 3 rated sessions overlap the same hour.")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            HStack(spacing:12) {
                                timeCard("Best",bestHour,system:"sun.max.fill")
                                timeCard("Lowest",lowHour,system:"moon.fill")
                            }
                        }
                        ForEach(hourly,id:\.0) { h,a,n in
                            HStack { Text(hourLabel(h)).frame(width:72,alignment:.leading); ProgressView(value:a,total:5); Text(String(format:"%.1f",a)).monospacedDigit(); Text("(\(n))").font(.caption).foregroundStyle(.secondary) }
                        }
                        Text("Ratings are weighted by actual minutes worked in each hour. Numbers in parentheses are rated sessions overlapping that hour. Patterns describe association, not cause.").font(.caption).foregroundStyle(.secondary)
                    }
                }.sectionCard()

                VStack(alignment:.leading,spacing:12) {
                    Text("Projects").font(.title3.bold())
                    if grouped.isEmpty { Text("Complete work to start building project insights.").foregroundStyle(.secondary) }
                    ForEach(grouped,id:\.0) { g in
                        VStack(alignment:.leading,spacing:5) {
                            HStack { Text(g.0).font(.headline); Spacer(); Text(format(g.1)).bold() }
                            Text("\(g.2) completed • Emotion \(g.3.map{String(format:"%.1f/5",$0)} ?? "—")").font(.caption).foregroundStyle(.secondary)
                        }
                        if g.0 != grouped.last?.0 { Divider() }
                    }
                }.sectionCard()

                VStack(alignment:.leading,spacing:12) {
                    Text("Work History").font(.title3.bold())
                    ForEach(rows.sorted{$0.date>$1.date}.prefix(60)) { item in
                        VStack(alignment:.leading,spacing:4) {
                            HStack { Text(item.taskName ?? item.projectName).font(.headline); Spacer(); Text(emotion(item.happiness)) }
                            Text(item.projectName).font(.caption).foregroundStyle(.secondary)
                            HStack { Text(item.date.formatted(date:.abbreviated,time:.shortened)); Spacer(); Text("Planned \(item.plannedMinutes)m → Actual \(item.actualMinutes)m") }
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Divider()
                    }
                }.sectionCard()
            }.padding()
        }.navigationTitle("Insights").background(Color(.systemGroupedBackground))
    }
    @ViewBuilder private func timeCard(_ title:String,_ value:(Int,Double,Int)?,system:String)->some View {
        VStack(alignment:.leading,spacing:5) { Label(title,systemImage:system).font(.caption.bold()); if let v=value { Text(hourLabel(v.0)).font(.headline); Text(String(format:"%.1f/5 • %d ratings",v.1,v.2)).font(.caption).foregroundStyle(.secondary) } else { Text("—") } }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(Color(.secondarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:12))
    }
    private func gaugeNumber(_ title:String,_ value:String,color:Color)->some View { VStack(spacing:3){Text(value).font(.headline).monospacedDigit().foregroundStyle(color);Text(title).font(.caption2).foregroundStyle(.secondary)} }
    private func metric(_ title:String,_ value:String)->some View { VStack(alignment:.leading){Text(value).font(.headline);Text(title).font(.caption).foregroundStyle(.secondary)} }
    private func emotion(_ v:Int?)->String { guard let v else{return "—"}; return ["","😞","🙁","😐","🙂","😄"][max(1,min(5,v))] + " \(v)/5" }
    private func hourLabel(_ h:Int)->String { let d=Calendar.current.date(bySettingHour:h,minute:0,second:0,of:Date())!; return d.formatted(date:.omitted,time:.shortened) }
    private func format(_ m:Int)->String { m < 60 ? "\(m) min" : String(format:"%dh %02dm",m/60,m%60) }
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
