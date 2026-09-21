import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var calendarManager = CalendarManager()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        calendarCard
                        eventsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ALSAGIER")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.05, green: 0.12, blue: 0.25))
            Text("By Softfm")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Apple Calendar", systemImage: "calendar")
                .font(.headline)

            Text(calendarManager.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task { await calendarManager.requestAndLoadToday() }
            } label: {
                HStack {
                    if calendarManager.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(calendarManager.isLoading ? "Connecting…" : "Connect Calendar")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.05, green: 0.12, blue: 0.25))
            .disabled(calendarManager.isLoading)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Calendar")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            if calendarManager.events.isEmpty {
                ContentUnavailableView(
                    "No Calendar Events",
                    systemImage: "calendar.badge.clock",
                    description: Text("Connect your calendar to display today's fixed appointments.")
                )
                .frame(minHeight: 220)
            } else {
                ForEach(calendarManager.events, id: \.eventIdentifier) { event in
                    EventRow(event: event)
                }
            }
        }
    }
}

private struct EventRow: View {
    let event: EKEvent

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(event.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline.bold())
                Text(event.endDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 82)

            Rectangle()
                .fill(Color(red: 0.05, green: 0.12, blue: 0.25))
                .frame(width: 4)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled Event")
                    .font(.headline)
                if let calendarTitle = event.calendar?.title {
                    Text(calendarTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
