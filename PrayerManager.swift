import Foundation
import CoreLocation
import Combine

@MainActor
final class PrayerManager: NSObject, ObservableObject {
    @Published var blocks: [ScheduleBlock] = []
    @Published var status = "Prayer times not loaded"

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh() async {
        status = "Loading prayer times…"
        guard let location = await requestLocation() else {
            status = "Location permission needed"
            blocks = []
            return
        }

        do {
            var components = URLComponents(string: "https://api.aladhan.com/v1/timings")!
            components.queryItems = [
                URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
                URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
                URLQueryItem(name: "method", value: "4")
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let response = try JSONDecoder().decode(AladhanResponse.self, from: data)
            blocks = makeBlocks(response.data.timings)
            status = blocks.isEmpty ? "Prayer times unavailable" : "Prayer times loaded"
        } catch {
            blocks = []
            status = "Could not load prayer times"
        }
    }

    private func requestLocation() async -> CLLocation? {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            return nil
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    private func makeBlocks(_ timings: AladhanTimings) -> [ScheduleBlock] {
        let pairs = [
            ("Fajr", timings.Fajr), ("Dhuhr", timings.Dhuhr),
            ("Asr", timings.Asr), ("Maghrib", timings.Maghrib),
            ("Isha", timings.Isha)
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: Date())

        return pairs.compactMap { name, raw in
            let time = raw.prefix(5)
            guard let parsed = formatter.date(from: String(time)) else { return nil }
            let hm = cal.dateComponents([.hour, .minute], from: parsed)
            guard let prayer = cal.date(bySettingHour: hm.hour ?? 0, minute: hm.minute ?? 0, second: 0, of: dayStart) else { return nil }
            return ScheduleBlock(
                title: name,
                start: prayer.addingTimeInterval(-10 * 60),
                end: prayer.addingTimeInterval(20 * 60),
                kind: .prayer,
                isLocked: true
            )
        }.sorted { $0.start < $1.start }
    }
}

extension PrayerManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(returning: nil)
            continuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            Task { @MainActor in
                continuation?.resume(returning: nil)
                continuation = nil
            }
        }
    }
}

private struct AladhanResponse: Decodable { let data: AladhanData }
private struct AladhanData: Decodable { let timings: AladhanTimings }
private struct AladhanTimings: Decodable {
    let Fajr: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}
