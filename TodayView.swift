import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendar: CalendarManager
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var prayers: PrayerManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var starting = false
    @State private var history = false
    @State private var confirmEnd = false
    @State private var refreshing = false
    @State private var actionBlock: ScheduleBlock?
    @State private var switchBlock: ScheduleBlock?
    @State private var emotionInsight: WorkInsight?
    @StateObject private var health = HealthManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:14) {
                    whatNow
                    dayControls
                    summary
                    timeline
                }.padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar { Button { history=true } label: { Image(systemName:"clock.arrow.circlepath") } }
            .sheet(isPresented:$history) { HistoryView() }
            .confirmationDialog("End your workday?", isPresented:$confirmEnd, titleVisibility:.visible) {
                Button("End My Day", role:.destructive) { endDay() }
                Button("Cancel", role:.cancel) {}
            } message: {
                Text("Your progress will be saved. You can reopen today if you need to continue.")
            }
            .confirmationDialog(actionBlock?.title ?? "Schedule action", isPresented: Binding(
                get:{ actionBlock != nil }, set:{ if !$0 { actionBlock=nil } }), titleVisibility:.visible) {
                if let b=actionBlock, canClose(b) { Button("Done") { close(b); actionBlock=nil } }
                if let b=actionBlock, canSwitch(b) { Button("Switch Work") { switchBlock=b; actionBlock=nil } }
                if let b=actionBlock, !b.isLocked { Button("+15 min") { extend(b); actionBlock=nil } }
                if let b=actionBlock, !b.isLocked { Button("Skip Today") { skip(b); actionBlock=nil } }
                Button("Cancel",role:.cancel) { actionBlock=nil }
            }
            .sheet(item:$switchBlock) { block in
                SwitchWorkView(block:block) { refreshEverything() }
            }
            .sheet(item:$emotionInsight) { insight in
                EmotionRatingView(insight: insight) { rating in
                    store.setHappiness(for: insight.id, rating: rating)
                    emotionInsight=nil
                } onSkip: { emotionInsight=nil }
            }
            .task {
                await health.requestAccess()
                await refreshHealthAndSchedule()
                await refreshLiveActivity()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refreshHealthAndSchedule(); await refreshLiveActivity() } }
            }
        }
    }

    private var blocks: [ScheduleBlock] { store.todayPlan?.blocks ?? [] }

    private var whatNow: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now=context.date
            let current=blocks.first {$0.start <= now && $0.end > now && !$0.isCompleted && !$0.isSkipped}
            let next=blocks.first {$0.start > now && !$0.isCompleted && !$0.isSkipped}
            VStack(alignment:.leading,spacing:8) {
                Text("WHAT NOW?").font(.caption.bold()).foregroundStyle(.secondary)
                if let b=current {
                    HStack(alignment:.firstTextBaseline) {
                        Text(b.title).font(.title2.bold()).foregroundStyle(b.color)
                        Spacer()
                        Text("\(max(0,Int(b.end.timeIntervalSince(now)/60)))m left")
                            .font(.headline).foregroundStyle(.secondary)
                    }
                    if let sub=b.subtitle { Text(sub).font(.headline) }
                    if let n=next {
                        Divider()
                        Text("Next: \(n.title) • \(n.start.formatted(date:.omitted,time:.shortened))")
                            .font(.subheadline).foregroundStyle(n.projectColor?.color ?? .secondary)
                    }
                } else if let n=next {
                    Text("Free right now").font(.title2.bold())
                    Text("Next: \(n.title) • \(n.start.formatted(date:.omitted,time:.shortened))")
                        .foregroundStyle(n.projectColor?.color ?? .secondary)
                } else {
                    Text(store.todayPlan == nil ? "Start your day when you're ready" : "Today's planned blocks are complete")
                        .font(.headline)
                }
            }
            .frame(maxWidth:.infinity,alignment:.leading)
            .padding()
            .background(.background,in:RoundedRectangle(cornerRadius:18))
        }
    }

    private var dayControls: some View {
        VStack(spacing:8) {
            if store.todayPlan == nil {
                Button { Task { await startDay() } } label: {
                    Label(starting ? "Planning…" : "Start My Day", systemImage:"play.fill").frame(maxWidth:.infinity)
                }.buttonStyle(.borderedProminent).disabled(starting)
            } else if store.isDayActive {
                HStack {
                    Button { Task { await refreshMyDay() } } label: {
                        Label(refreshing ? "Refreshing…" : "Refresh My Day", systemImage:"arrow.clockwise")
                            .frame(maxWidth:.infinity)
                    }.buttonStyle(.bordered).disabled(refreshing)
                    Button { Task { await late15() } } label: {
                        Label("I'm 15m Late", systemImage:"clock.badge.exclamationmark")
                            .frame(maxWidth:.infinity)
                    }.buttonStyle(.bordered)
                }
                Button(role:.destructive) { confirmEnd=true } label: {
                    Label("End My Day",systemImage:"stop.fill").frame(maxWidth:.infinity)
                }.buttonStyle(.borderedProminent)
            } else {
                Button {
                    store.reopenDay() // immediate state/UI change
                    Task { await refreshMyDay() }
                } label: {
                    Label("Re-open My Day",systemImage:"arrow.counterclockwise").frame(maxWidth:.infinity)
                }.buttonStyle(.borderedProminent)
            }
        }
    }

    private var summary: some View {
        let calendarBlocks=blocks.filter {$0.kind == .calendar}
        let focusBlocks=blocks.filter {[BlockKind.task,.project].contains($0.kind)}
        let habitBlocks=blocks.filter {$0.kind == .habit}
        let travelBlocks=blocks.filter {$0.kind == .travel}
        let counted=calendarBlocks.count + focusBlocks.count + habitBlocks.count
        let totalMinutes=(calendarBlocks+focusBlocks+habitBlocks+travelBlocks).reduce(0) {$0+$1.durationMinutes}

        return VStack(spacing:10) {
            HStack {
                metric("Calendar", calendarBlocks.count, calendarBlocks.reduce(0){$0+$1.durationMinutes}, "events")
                Spacer()
                metric("Focus", focusBlocks.count, focusBlocks.reduce(0){$0+$1.durationMinutes}, "blocks")
                Spacer()
                metric("Habits", habitBlocks.count, habitBlocks.reduce(0){$0+$1.durationMinutes}, "habits")
            }
            Divider()
            HStack {
                Text("Total").font(.caption.bold())
                Spacer()
                Text("\(counted) items").font(.subheadline.bold())
                Text("• \(durationText(totalMinutes))").font(.subheadline.bold())
            }
            if !travelBlocks.isEmpty {
                HStack {
                    Image(systemName:"car.fill")
                    Text("Road time")
                    Spacer()
                    Text(durationText(travelBlocks.reduce(0){$0+$1.durationMinutes}))
                }.font(.caption).foregroundStyle(.secondary)
            }
        }.padding().background(.background,in:RoundedRectangle(cornerRadius:16))
    }

    private func metric(_ label:String,_ count:Int,_ minutes:Int,_ noun:String) -> some View {
        VStack(alignment:.leading,spacing:2) {
            Text("\(count) \(noun)").font(.headline)
            Text(durationText(minutes)).font(.subheadline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func durationText(_ minutes:Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        return minutes % 60 == 0 ? "\(minutes/60)h" : "\(minutes/60)h \(minutes%60)m"
    }

    @ViewBuilder private var timeline: some View {
        if blocks.isEmpty {
            ContentUnavailableView("No schedule yet",systemImage:"calendar.day.timeline.left",
                description:Text("CapJour plans around Calendar, prayer, projects, tasks and habits."))
        } else {
            LazyVStack(spacing:9) {
                ForEach(blocks) { b in
                    SwipeableTimelineCard(block:b,
                        onTap:{ if !b.isCompleted && !b.isSkipped && b.kind != .prayer { actionBlock=b } },
                        onDone:{ close(b) }, onExtend:{ extend(b) }, onSkip:{ skip(b) })
                }
            }
        }
    }

    private func canClose(_ block:ScheduleBlock) -> Bool {
        block.kind != .prayer
    }

    private func canSwitch(_ block:ScheduleBlock) -> Bool {
        !block.isLocked && (block.kind == .task || block.kind == .project)
    }

    private func startDay() async {
        starting=true
        calendar.loadToday()
        await prayers.refresh()
        store.startDay(calendar:calendar.todayBlocks,prayers:prayers.blocks)
        await refreshAfterScheduleChange()
        starting=false
    }

    private func refreshMyDay() async {
        guard store.isDayActive else { return }
        refreshing = true
        calendar.loadToday()
        await prayers.refresh()
        store.refreshToday(calendar:calendar.todayBlocks,prayers:prayers.blocks)
        await refreshAfterScheduleChange()
        refreshing = false
    }

    private func late15() async {
        guard store.isDayActive else { return }
        calendar.loadToday()
        await prayers.refresh()
        store.runningLate15(calendar:calendar.todayBlocks,prayers:prayers.blocks)
        await refreshAfterScheduleChange()
    }

    private func endDay() {
        store.endDay()
        Task {
            await notifications.refresh(for:[],minutesBefore:0)
            await LiveActivityManager.shared.end()
        }
    }

    private func close(_ b:ScheduleBlock) {
        // Calendar completion is local to CapJour; it never edits EventKit.
        if b.kind == .calendar || b.kind == .travel {
            if let di=store.todayIndex,
               let bi=store.dayPlans[di].blocks.firstIndex(where:{$0.id==b.id}) {
                store.dayPlans[di].blocks[bi].isCompleted=true
                store.save()
            }
        } else {
            store.complete(b,calendar:calendar.todayBlocks,prayers:prayers.blocks)
            if b.kind == .task || b.kind == .project { emotionInsight = store.latestUnratedInsight }
        }
        refreshEverything()
    }

    private func skip(_ b:ScheduleBlock) {
        store.skip(b,calendar:calendar.todayBlocks,prayers:prayers.blocks)
        refreshEverything()
    }

    private func extend(_ b:ScheduleBlock) {
        store.extend15(b,calendar:calendar.todayBlocks,prayers:prayers.blocks)
        refreshEverything()
    }

    private func refreshHealthAndSchedule() async {
        guard store.isDayActive else { return }
        await health.refreshToday()
        calendar.loadToday()
        await prayers.refresh()
        store.applyWalkingHealth(steps:health.stepsToday, walkingMinutes:health.walkingMinutesToday,
                                 calendar:calendar.todayBlocks, prayers:prayers.blocks)
    }

    private func refreshEverything() {
        Task { await refreshAfterScheduleChange() }
    }

    private func refreshAfterScheduleChange() async {
        await notifications.refresh(for:blocks,minutesBefore:store.settings.reminderMinutes)
        if let cutoff=Calendar.current.date(bySettingHour:store.settings.workEndHour,minute:0,second:0,of:Date()) {
            await notifications.scheduleWorkdayEnd(at:cutoff)
        }
        await refreshLiveActivity()
    }

    private func refreshLiveActivity() async {
        await LiveActivityManager.shared.refresh(blocks:blocks,dayActive:store.isDayActive)
    }
}

private struct SwipeableTimelineCard: View {
    let block: ScheduleBlock
    let onTap: () -> Void
    let onDone: () -> Void
    let onExtend: () -> Void
    let onSkip: () -> Void
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            HStack(spacing:0) {
                if offset > 0 && canDone {
                    Button(action:{ onDone(); withAnimation{offset=0} }) {
                        Label("Done",systemImage:"checkmark").frame(maxHeight:.infinity).padding(.horizontal,18)
                    }.buttonStyle(.plain).foregroundStyle(.white).background(.green)
                    Spacer()
                } else {
                    Spacer()
                    if offset < 0 && canModify {
                        Button(action:{ onExtend(); withAnimation{offset=0} }) { Text("+15m").frame(maxHeight:.infinity).padding(.horizontal,15) }
                            .buttonStyle(.plain).foregroundStyle(.white).background(.blue)
                        Button(action:{ onSkip(); withAnimation{offset=0} }) { Text("Skip").frame(maxHeight:.infinity).padding(.horizontal,15) }
                            .buttonStyle(.plain).foregroundStyle(.white).background(.orange)
                    }
                }
            }.clipShape(RoundedRectangle(cornerRadius:15))

            TimelineCard(block:block)
                .contentShape(Rectangle())
                .onTapGesture { if abs(offset) < 5 { onTap() } else { withAnimation{offset=0} } }
                .offset(x:offset)
                .simultaneousGesture(DragGesture(minimumDistance:16)
                    .onChanged { value in
                        guard !block.isCompleted && !block.isSkipped else { return }
                        let x = value.translation.width
                        let y = value.translation.height
                        // Only react to a clearly horizontal swipe. Vertical drags belong
                        // to the Today ScrollView and must never be captured by the card.
                        guard abs(x) > abs(y) * 1.35 else { return }
                        if x > 0 && canDone { offset=min(92,x) }
                        else if x < 0 && canModify { offset=max(-145,x) }
                    }
                    .onEnded { value in
                        let x = value.translation.width
                        let y = value.translation.height
                        guard abs(x) > abs(y) * 1.35 else { return }
                        withAnimation(.snappy) {
                            if x > 55 && canDone { offset=92 }
                            else if x < -55 && canModify { offset = -145 }
                            else { offset=0 }
                        }
                    })
        }.clipped()
    }
    private var canDone:Bool { block.kind != .prayer }
    private var canModify:Bool { !block.isLocked && block.kind != .prayer }
}

private struct TimelineCard: View {
    let block:ScheduleBlock
    var body:some View {
        if block.kind == .travel {
            HStack(alignment:.top, spacing:8) {
                Image(systemName:"car.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width:18)
                VStack(alignment:.leading,spacing:1) {
                    Text(block.title)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(block.start.formatted(date:.omitted,time:.shortened)) – \(block.end.formatted(date:.omitted,time:.shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if block.isCompleted { Image(systemName:"checkmark.circle.fill").font(.caption).foregroundStyle(.green) }
            }
            .padding(.horizontal,12)
            .padding(.vertical,5)
            .background(Color.clear) // travel is reserved time, not a work brick
            .opacity(block.isSkipped ? 0.45 : (block.isCompleted ? 0.60 : 1))
        } else {
            HStack(spacing:12) {
                RoundedRectangle(cornerRadius:4).fill(block.color).frame(width:6)
                VStack(alignment:.leading,spacing:4) {
                    HStack {
                        Image(systemName:block.kind.icon).foregroundStyle(block.color)
                        Text(block.title)
                            .font(.headline)
                            .foregroundStyle(block.projectColor?.color ?? (block.kind == .prayer ? .green : .primary))
                        if block.isLocked { Image(systemName:"lock.fill").font(.caption).foregroundStyle(.secondary) }
                        if block.isCompleted { Image(systemName:"checkmark.circle.fill").foregroundStyle(.green) }
                    }
                    if let sub=block.subtitle { Text(sub).font(.subheadline) }
                    Text("\(block.start.formatted(date:.omitted,time:.shortened)) – \(block.end.formatted(date:.omitted,time:.shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }.padding()
            .background(block.kind == .prayer ? Color.green.opacity(0.13) : block.color.opacity(0.08),
                        in:RoundedRectangle(cornerRadius:15))
            .opacity(block.isSkipped ? 0.45 : (block.isCompleted ? 0.60 : 1))
        }
    }
}

private struct SwitchWorkView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let block: ScheduleBlock
    let onChanged: () -> Void

    private var activeTasks: [ExecutiveTask] {
        store.tasks.filter { !$0.isCompleted }.sorted { a,b in
            if a.priority.rank != b.priority.rank { return a.priority.rank < b.priority.rank }
            return a.createdAt < b.createdAt
        }
    }
    private var activeProjects: [Project] {
        store.projects.filter { $0.status == .active }.sorted { $0.priority.rank < $1.priority.rank }
    }

    var body: some View {
        NavigationStack {
            List {
                if !activeTasks.isEmpty {
                    Section("Active Tasks") {
                        ForEach(activeTasks) { task in
                            Button {
                                store.switchWork(blockID:block.id,toTask:task)
                                onChanged(); dismiss()
                            } label: {
                                VStack(alignment:.leading,spacing:3) {
                                    Text(task.title).foregroundStyle(.primary)
                                    HStack(spacing:4) {
                                        Text("\(task.duration)m • \(task.priority.rawValue)")
                                        if let id=task.projectID, let p=store.projects.first(where:{$0.id==id}) {
                                            Text("• \(p.name)").foregroundStyle(p.color.color)
                                        }
                                    }.font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                if !activeProjects.isEmpty {
                    Section("Project Work") {
                        ForEach(activeProjects) { project in
                            Button {
                                store.switchWork(blockID:block.id,toProject:project)
                                onChanged(); dismiss()
                            } label: {
                                HStack {
                                    Circle().fill(project.color.color).frame(width:12,height:12)
                                    Text(project.name).foregroundStyle(.primary)
                                    Spacer()
                                    Text("same time block").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Switch Work")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}} }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store:AppStore
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        NavigationStack {
            List(store.dayPlans.filter{!Calendar.current.isDateInToday($0.date)}.sorted{$0.date>$1.date}) { day in
                Section(day.date.formatted(date:.complete,time:.omitted)) {
                    ForEach(day.blocks) { b in
                        VStack(alignment:.leading,spacing:3) {
                            Text(b.title).font(.headline).foregroundStyle(b.projectColor?.color ?? .primary)
                            if let s=b.subtitle { Text(s) }
                            Text("\(b.start.formatted(date:.omitted,time:.shortened)) – \(b.end.formatted(date:.omitted,time:.shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }.navigationTitle("Past Days").toolbar { Button("Done") { dismiss() } }
        }
    }
}


private struct EmotionRatingView: View {
    let insight: WorkInsight
    let onRate: (Int) -> Void
    let onSkip: () -> Void
    private let faces = ["😞","🙁","😐","🙂","😄"]
    var body: some View {
        VStack(spacing:22) {
            Capsule().fill(.secondary.opacity(0.3)).frame(width:42,height:5).padding(.top,10)
            Text("How did this work feel?").font(.title2.bold())
            Text(insight.taskName ?? insight.projectName).font(.headline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            HStack(spacing:10) {
                ForEach(1...5,id:\.self) { rating in
                    Button { onRate(rating) } label: {
                        VStack(spacing:5) { Text(faces[rating-1]).font(.system(size:34)); Text("\(rating)").font(.caption.bold()) }
                            .frame(maxWidth:.infinity).padding(.vertical,10)
                    }.buttonStyle(.plain)
                }
            }
            Text("Optional • used only for your local Insights").font(.caption).foregroundStyle(.secondary)
            Button("Not now", action:onSkip).foregroundStyle(.secondary)
            Spacer()
        }.padding().presentationDetents([.medium])
    }
}
