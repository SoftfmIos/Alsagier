import Foundation
import HealthKit

struct EnergySession: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let averageBPM: Double?
    let samples: Int
    let workoutOverlap: Bool
    let emotion: Int?
    let priorNightSleepHours: Double?
}

struct EnergyHealthReport {
    var sessions: [EnergySession] = []
    var sleepHours: Double?
    var sleepComparison: String?
    var message: String?
}

@MainActor
final class EnergyHealthAnalyzer: ObservableObject {
    @Published private(set) var report = EnergyHealthReport()
    @Published private(set) var loading = false
    private let health = HKHealthStore()

    func analyze(_ insights: [WorkInsight]) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            report = EnergyHealthReport(message: "Apple Health is not available on this device.")
            return
        }
        loading = true
        defer { loading = false }
        guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate),
              let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            report = EnergyHealthReport(message: "Heart-rate or sleep data types are unavailable.")
            return
        }
        do {
            try await health.requestAuthorization(toShare: [], read: [heart, sleep, .workoutType()])
        } catch {
            report = EnergyHealthReport(message: "Apple Health permission request failed: \(error.localizedDescription)")
            return
        }
        let now = Date()
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let rows = insights.filter { $0.startedAt != nil && $0.actualMinutes > 0 && ($0.startedAt ?? $0.date) >= cutoff }
            .sorted { ($0.startedAt ?? $0.date) > ($1.startedAt ?? $1.date) }.prefix(40)
        // Retrieve sleep once for the full reporting period. Overlapping stages from different
        // sources must not be double counted; merge the actual asleep intervals per night.
        let sleepRows = await samples(type: sleep, from: cutoff.addingTimeInterval(-86400), to: now) as? [HKCategorySample] ?? []
        let asleepValues: Set<Int> = [HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                                     HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                                     HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                                     HKCategoryValueSleepAnalysis.asleepREM.rawValue]
        let sleepIntervals = sleepRows.filter { asleepValues.contains($0.value) }
            .map { DateInterval(start: $0.startDate, end: $0.endDate) }
        func unionHours(from: Date, to: Date) -> Double? {
            let spans = sleepIntervals.compactMap { span -> DateInterval? in
                let a = max(span.start, from), b = min(span.end, to)
                return b > a ? DateInterval(start: a, end: b) : nil
            }.sorted { $0.start < $1.start }
            guard !spans.isEmpty else { return nil }
            var seconds = 0.0
            var a = spans[0].start, b = spans[0].end
            for span in spans.dropFirst() {
                if span.start <= b { b = max(b, span.end) }
                else { seconds += b.timeIntervalSince(a); a = span.start; b = span.end }
            }
            seconds += b.timeIntervalSince(a)
            return seconds / 3600
        }
        var sessions: [EnergySession] = []
        for row in rows {
            guard let start = row.startedAt else { continue }
            let end = min(now, start.addingTimeInterval(TimeInterval(row.actualMinutes * 60)))
            guard end > start else { continue }
            let hr = await samples(type: heart, from: start, to: end) as? [HKQuantitySample] ?? []
            let values = hr.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                .filter { $0 >= 30 && $0 <= 240 }
            let workouts = await samples(type: .workoutType(), from: start, to: end) as? [HKWorkout] ?? []
            sessions.append(EnergySession(id: row.id, title: row.taskName ?? row.projectName, date: start,
                averageBPM: values.isEmpty ? nil : values.reduce(0, +) / Double(values.count),
                samples: values.count, workoutOverlap: workouts.contains { $0.startDate < end && $0.endDate > start },
                emotion: row.happiness,
                priorNightSleepHours: unionHours(from: Calendar.current.date(byAdding: .hour, value: -18, to: Calendar.current.startOfDay(for: start)) ?? start.addingTimeInterval(-86400), to: start)))
        }
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let recentSleep = unionHours(from: lastDay, to: now)
        let paired = sessions.filter { $0.priorNightSleepHours != nil && $0.emotion != nil }
        var comparison: String? = nil
        if paired.count >= 8 {
            let rested = paired.filter { ($0.priorNightSleepHours ?? 0) >= 7 }
            let shorter = paired.filter { ($0.priorNightSleepHours ?? 0) < 7 }
            if rested.count >= 3 && shorter.count >= 3 {
                let a = Double(rested.compactMap(\.emotion).reduce(0, +)) / Double(rested.count)
                let b = Double(shorter.compactMap(\.emotion).reduce(0, +)) / Double(shorter.count)
                comparison = String(format: "Observed emotion after 7+ hours of recorded sleep: %.1f/5 (%d sessions); after shorter recorded sleep: %.1f/5 (%d sessions). This is an association, not proof of causation.", a, rested.count, b, shorter.count)
            }
        }
        if comparison == nil { comparison = "Sleep and emotion comparison requires at least eight sessions, including three in each sleep group, with both sleep and emotion recorded." }
        report = EnergyHealthReport(sessions: sessions, sleepHours: recentSleep, sleepComparison: comparison,
            message: sessions.allSatisfy { $0.averageBPM == nil } ? "No heart-rate samples were returned for recent work sessions. Check Apple Health permissions and WHOOP data sharing." : nil)
    }

    private func samples(type: HKSampleType, from start: Date, to end: Date) async -> [HKSample] {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 2000,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            health.execute(query)
        }
    }
}
