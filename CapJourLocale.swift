import Foundation

enum CapJourLocale {
    static var arabic: Bool {
        let setting = UserDefaults.standard.string(forKey: "capjour.interfaceLanguage") ?? "automatic"
        return setting == "arabic" || (setting == "automatic" && Locale.current.language.languageCode?.identifier == "ar")
    }
    static var locale: Locale { Locale(identifier: arabic ? "ar_SA@numbers=latn" : "en_US_POSIX") }
    static func text(_ english: String, _ arabicText: String) -> String { arabic ? arabicText : english }
    static func number(_ value: Int) -> String { String(value) }
    static func duration(_ minutes: Int) -> String {
        if minutes < 60 { return arabic ? "\(minutes) دقيقة" : "\(minutes)m" }
        let h = minutes / 60, m = minutes % 60
        if arabic { return m == 0 ? "\(h) ساعة" : "\(h) ساعة و\(m) دقيقة" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
    static func date(_ value: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return f.string(from: value)
    }
    static func time(_ value: Date) -> String {
        let f = DateFormatter()
        // Respect the device's 12/24-hour preference, independent of interface language.
        let deviceFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "h a"
        let uses24 = deviceFormat.contains("H") || deviceFormat.contains("k")
        f.locale = locale
        f.dateFormat = uses24 ? "HH:mm" : "h:mm a"
        return f.string(from: value)
    }
    static func prayer(_ title: String) -> String {
        guard arabic else { return title }
        let names = ["Fajr":"الفجر", "Dhuhr":"الظهر", "Asr":"العصر", "Maghrib":"المغرب", "Isha":"العشاء"]
        return names[title] ?? title
    }
    static func next(_ title: String, _ time: Date) -> String {
        arabic ? "التالي: \(prayer(title)) • \(self.time(time))" : "Next: \(title) • \(self.time(time))"
    }
}
