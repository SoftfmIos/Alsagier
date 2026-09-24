import SwiftUI

struct TodayView:View {
    @EnvironmentObject private var store:AppStore
    @EnvironmentObject private var calendar:CalendarManager
    @EnvironmentObject private var notifications:NotificationManager
    @EnvironmentObject private var prayers:PrayerManager
    @State private var starting=false
    @State private var history=false

    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:14) {
                    whatNow
                    dayControls
                    summary
                    timeline
                }.padding()
            }.background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar{Button{history=true}label:{Image(systemName:"clock.arrow.circlepath")}}
            .sheet(isPresented:$history){HistoryView()}
        }
    }

    private var blocks:[ScheduleBlock]{store.todayPlan?.blocks ?? []}

    private var whatNow:some View {
        let now=Date()
        let current=blocks.first{$0.start <= now && $0.end > now && !$0.isCompleted && !$0.isSkipped}
        let next=blocks.first{$0.start > now && !$0.isCompleted && !$0.isSkipped}
        return VStack(alignment:.leading,spacing:8) {
            Text("WHAT NOW?").font(.caption.bold()).foregroundStyle(.secondary)
            if let b=current {
                Text(b.title).font(.title2.bold()).foregroundStyle(b.color)
                if let sub=b.subtitle{Text(sub).font(.headline)}
                Text("Until \(b.end.formatted(date:.omitted,time:.shortened))").foregroundStyle(.secondary)
            } else if let n=next {
                Text("Free right now").font(.title2.bold())
                Text("Next: \(n.title) • \(n.start.formatted(date:.omitted,time:.shortened))").foregroundStyle(.secondary)
            } else {
                Text(store.todayPlan == nil ? "Start your day when you're ready":"Today's planned blocks are complete").font(.headline)
            }
        }.frame(maxWidth:.infinity,alignment:.leading).padding().background(.background,in:RoundedRectangle(cornerRadius:18))
    }

    private var dayControls:some View {
        Group {
            if store.todayPlan == nil {
                Button{Task{await startDay()}}label:{Label(starting ? "Planning…":"Start My Day",systemImage:"play.fill").frame(maxWidth:.infinity)}
                    .buttonStyle(.borderedProminent).disabled(starting)
            } else if store.isDayActive {
                Button(role:.destructive){store.endDay();Task{await notifications.refresh(for:[],minutesBefore:0)}}label:{
                    Label("End My Day",systemImage:"stop.fill").frame(maxWidth:.infinity)
                }.buttonStyle(.borderedProminent)
            } else {
                Label("Day Ended",systemImage:"checkmark.seal.fill").frame(maxWidth:.infinity).padding()
            }
        }
    }

    private var summary:some View {
        let calendarM=blocks.filter{$0.kind == .calendar}.reduce(0){$0+$1.durationMinutes}
        let focusM=blocks.filter{[BlockKind.task,.project].contains($0.kind)}.reduce(0){$0+$1.durationMinutes}
        let habitM=blocks.filter{$0.kind == .habit}.reduce(0){$0+$1.durationMinutes}
        return HStack {
            metric("Calendar",calendarM); Spacer(); metric("Focus",focusM); Spacer(); metric("Habits",habitM)
        }.padding().background(.background,in:RoundedRectangle(cornerRadius:16))
    }

    private func metric(_ label:String,_ minutes:Int)->some View {
        VStack(alignment:.leading){Text("\(minutes/60)h \(minutes%60)m").font(.headline);Text(label).font(.caption).foregroundStyle(.secondary)}
    }

    @ViewBuilder private var timeline:some View {
        if blocks.isEmpty {
            ContentUnavailableView("No schedule yet",systemImage:"calendar.day.timeline.left",
                                   description:Text("Alsagier plans around Calendar, prayer, projects, tasks and habits."))
        } else {
            LazyVStack(spacing:9) {
                ForEach(blocks) { b in
                    TimelineCard(block:b)
                        .swipeActions(edge:.leading,allowsFullSwipe:true) {
                            if !b.isLocked && !b.isCompleted {
                                Button("Complete"){complete(b)}.tint(.green)
                            }
                        }
                        .swipeActions {
                            if !b.isLocked && !b.isCompleted {
                                Button("+15"){extend(b)}.tint(.blue)
                                Button("Skip"){skip(b)}.tint(.orange)
                            }
                        }
                }
            }
        }
    }

    private func startDay() async {
        starting=true
        calendar.loadToday()
        await prayers.refresh()
        store.startDay(calendar:calendar.todayBlocks,prayers:prayers.blocks)
        await notifications.refresh(for:blocks,minutesBefore:store.settings.reminderMinutes)
        if let cutoff=Calendar.current.date(bySettingHour:store.settings.workEndHour,minute:0,second:0,of:Date()){
            await notifications.scheduleWorkdayEnd(at:cutoff)
        }
        starting=false
    }
    private func complete(_ b:ScheduleBlock){store.complete(b,calendar:calendar.todayBlocks,prayers:prayers.blocks);refreshNotifications()}
    private func skip(_ b:ScheduleBlock){store.skip(b,calendar:calendar.todayBlocks,prayers:prayers.blocks);refreshNotifications()}
    private func extend(_ b:ScheduleBlock){store.extend15(b,calendar:calendar.todayBlocks,prayers:prayers.blocks);refreshNotifications()}
    private func refreshNotifications(){Task{await notifications.refresh(for:blocks,minutesBefore:store.settings.reminderMinutes)}}
}

private struct TimelineCard:View {
    let block:ScheduleBlock
    var body:some View {
        HStack(spacing:12) {
            RoundedRectangle(cornerRadius:4).fill(block.color).frame(width:6)
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Image(systemName:block.kind.icon).foregroundStyle(block.color)
                    Text(block.title).font(.headline)
                    if block.isLocked{Image(systemName:"lock.fill").font(.caption).foregroundStyle(.secondary)}
                    if block.isCompleted{Image(systemName:"checkmark.circle.fill").foregroundStyle(.green)}
                }
                if let sub=block.subtitle{Text(sub).font(.subheadline)}
                Text("\(block.start.formatted(date:.omitted,time:.shortened)) – \(block.end.formatted(date:.omitted,time:.shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }.padding()
        .background(block.kind == .prayer ? Color.green.opacity(0.13) : block.color.opacity(0.08),
                    in:RoundedRectangle(cornerRadius:15))
        .opacity(block.isSkipped ? 0.45:1)
    }
}

private struct HistoryView:View {
    @EnvironmentObject private var store:AppStore
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        NavigationStack {
            List(store.dayPlans.filter{!Calendar.current.isDateInToday($0.date)}.sorted{$0.date>$1.date}) { day in
                Section(day.date.formatted(date:.complete,time:.omitted)) {
                    ForEach(day.blocks) { b in
                        VStack(alignment:.leading,spacing:3) {
                            Text(b.title).font(.headline)
                            if let s=b.subtitle{Text(s)}
                            Text("\(b.start.formatted(date:.omitted,time:.shortened)) – \(b.end.formatted(date:.omitted,time:.shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }.navigationTitle("Past Days").toolbar{Button("Done"){dismiss()}}
        }
    }
}
