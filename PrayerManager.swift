import Foundation
import Combine
import CoreLocation

@MainActor
final class PrayerManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var blocks: [ScheduleBlock] = []
    @Published var status = "Not loaded"

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        status = "Loading"
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            status = "Location not allowed"
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { await fetch(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = "Location error"
    }

    private func fetch(latitude: Double, longitude: Double) async {
        var components = URLComponents(string: "https://api.aladhan.com/v1/timings")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "method", value: "4")
        ]
        guard let url = components.url else { status = "Prayer URL error"; return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AladhanResponse.self, from: data)
            let names: [(String, String)] = [
                ("Fajr", response.data.timings.Fajr),
                ("Dhuhr", response.data.timings.Dhuhr),
                ("Asr", response.data.timings.Asr),
                ("Maghrib", response.data.timings.Maghrib),
                ("Isha", response.data.timings.Isha)
            ]
            let cal = Calendar.current
            let day = cal.startOfDay(for: Date())
            var result: [ScheduleBlock] = []

            for (name, raw) in names {
                let time = raw.prefix(5)
                let parts = time.split(separator: ":").compactMap { Int($0) }
                guard parts.count == 2,
                      let prayer = cal.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day)
                else { continue }

                result.append(ScheduleBlock(
                    title: "\(name) Prayer",
                    start: prayer.addingTimeInterval(-10 * 60),
                    end: prayer.addingTimeInterval(20 * 60),
                    kind: .prayer,
                    color: .prayer,
                    isLocked: true
                ))
            }
            blocks = result.sorted { $0.start < $1.start }
            status = "Loaded"
        } catch {
            status = "Prayer data error"
        }
    }
}

private struct AladhanResponse: Decodable {
    let data: AladhanData
}
private struct AladhanData: Decodable {
    let timings: AladhanTimings
}
private struct AladhanTimings: Decodable {
    let Fajr: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}
