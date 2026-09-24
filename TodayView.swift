import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendar: CalendarManager
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var prayers: PrayerManager

    @State private var lateAlert = false
    @State private var generating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    actionButtons
                    summaryCard
                    prayerStatus
                    timeline
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .alert("Schedule moved", isPresented: $lateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Remaining flexible blocks were moved by 15 minutes around protected events.")
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Alsagier")
                    .font(.largeTitle.bold())
                Text("By Softfm")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.title2)
        }
    }

    private var actionButtons: some View {
        HStack {
            Button {
                Task { await startMyDay() }
            } label: {
                Label(generating ? "Building…" : "Start My Day", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(generating)

            Button {
                store.late15()
                lateAlert = true
                Task { await notifications.schedule(store.schedule) }
            } label: {
                Label("15 Min Late", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(.bordered)
            .disabled(store.schedule.isEmpty)
        }
    }

    private var summaryCard: some View {
        let summary = store.todaySummary
        return VStack(alignment: .leading, spacing: 10) {
            Text("Today Summary").font(.headline)
            HStack {
                SummaryMetric(value: "\(store.schedule.count)", label: "Blocks")
                Spacer()
                SummaryMetric(value: "\(summary.total)", label: "Flexible")
                Spacer()
                SummaryMetric(value: "\(summary.minutes)m", label: "Planned")
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var prayerStatus: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
            Text(prayers.status)
                .font(.footnote)
            Spacer()
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder private var timeline: some View {
        if store.schedule.isEmpty {
            ContentUnavailableView(
                "Your day is ready to be planned",
                systemImage: "calendar.day.timeline.left",
                description: Text("Tap Start My Day to build today's schedule around Calendar and prayer times.")
            )
            .padding(.top, 24)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(store.schedule) { block in
                    ScheduleRow(block: block)
                }
            }
        }
    }

    private func startMyDay() async {
        generating = true
        calendar.loadToday()
        await prayers.refresh()
        store.generateDay(
            calendarBlocks: calendar.todayBlocks,
            prayerBlocks: prayers.blocks,
            start: Date().addingTimeInterval(10 * 60)
        )
        await notifications.schedule(store.schedule)
        generating = false
    }
}

private struct SummaryMetric: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct ScheduleRow: View {
    let block: ScheduleBlock
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(block.color)
                .frame(width: 5)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: block.kind.icon)
                        .foregroundStyle(block.color)
                    Text(block.title).font(.headline)
                    if block.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("\(Self.formatter.string(from: block.start)) – \(Self.formatter.string(from: block.end))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}
