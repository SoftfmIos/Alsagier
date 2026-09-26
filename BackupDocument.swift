import SwiftUI
import UniformTypeIdentifiers

struct AlsagierBackup: Codable {
    var version: Int = 1
    var createdAt: Date = Date()
    var projects: [Project]
    var tasks: [ExecutiveTask]
    var habits: [Habit]
    var dayPlans: [DayPlan]
    var settings: AppSettings
}

struct AlsagierBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var backup: AlsagierBackup

    init(backup: AlsagierBackup) { self.backup = backup }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        backup = try decoder.decode(AlsagierBackup.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return FileWrapper(regularFileWithContents: try encoder.encode(backup))
    }
}
