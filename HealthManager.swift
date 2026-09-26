import Foundation
import HealthKit

@MainActor
final class HealthManager: ObservableObject {
    static let shared = HealthManager()
    private let store = HKHealthStore()
    @Published var authorized = false
    @Published var stepsToday: Int = 0
    @Published var walkingMinutesToday: Int = 0

    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable(),
              let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let workout = HKObjectType.workoutType()
        do {
            try await store.requestAuthorization(toShare: [], read: [steps, workout])
            authorized = true
            await refreshToday()
        } catch { authorized = false }
    }

    func refreshToday() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        if let type = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            stepsToday = await withCheckedContinuation { continuation in
                let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                    continuation.resume(returning: Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0))
                }
                store.execute(q)
            }
        }

        // Walking minutes are the duration of walking workouts recorded in Apple Health.
        // Steps still work automatically from iPhone/Apple Watch even when no workout is started.
        walkingMinutesToday = await withCheckedContinuation { continuation in
            let walking = HKQuery.predicateForWorkouts(with: .walking)
            let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, walking])
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: combined, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let seconds = (samples as? [HKWorkout] ?? []).reduce(0) { $0 + $1.duration }
                continuation.resume(returning: Int(seconds / 60))
            }
            store.execute(q)
        }
    }
}
