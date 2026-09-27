import Foundation
import HealthKit

@MainActor
final class HealthManager: ObservableObject {
    static let shared = HealthManager()
    private let store = HKHealthStore()

    @Published var authorized = false
    @Published var stepsToday: Int = 0
    @Published var walkingMinutesToday: Int = 0
    @Published var gymMinutesToday: Int = 0
    @Published var gymWorkoutCountToday: Int = 0

    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable(),
              let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let workout = HKObjectType.workoutType()
        do {
            try await store.requestAuthorization(toShare: [], read: [steps, workout])
            authorized = true
            await refreshToday()
        } catch {
            authorized = false
        }
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

        let workouts: [HKWorkout] = await withCheckedContinuation { continuation in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }
            store.execute(q)
        }

        let walking = workouts.filter { $0.workoutActivityType == .walking }
        walkingMinutesToday = Int(walking.reduce(0) { $0 + $1.duration } / 60)

        // Gym is informational only. CapJour does NOT silently mark the Gym habit Done
        // from Health data; the user still decides Done/Skip. These common workout types
        // are shown so Apple Watch/iPhone-recorded gym activity is visible in Habits.
        let gymTypes: Set<HKWorkoutActivityType> = [
            .traditionalStrengthTraining, .functionalStrengthTraining,
            .crossTraining, .highIntensityIntervalTraining, .coreTraining,
            .mixedCardio
        ]
        let gym = workouts.filter { gymTypes.contains($0.workoutActivityType) }
        gymMinutesToday = Int(gym.reduce(0) { $0 + $1.duration } / 60)
        gymWorkoutCountToday = gym.count
    }
}
