import Foundation

enum AgentLogLevel: String, Codable, Sendable {
    case debug
    case info
    case warning
    case error
}

struct AgentLogEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let level: AgentLogLevel
    let category: String
    let action: String
    let message: String
}

actor AgentLogger {
    static let shared = AgentLogger()

    private let fileManager = FileManager.default
    private let maximumFileSize = 512 * 1024
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logURL: URL
    private let rotatedLogURL: URL

    private init() {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("AgentLogs", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        logURL = directory.appendingPathComponent("agent.log")
        rotatedLogURL = directory.appendingPathComponent("agent.previous.log")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func log(
        _ level: AgentLogLevel = .info,
        category: String,
        action: String,
        message: String
    ) {
        let entry = AgentLogEntry(
            id: UUID(),
            timestamp: Date(),
            level: level,
            category: sanitize(category),
            action: sanitize(action),
            message: sanitize(message)
        )
        guard var data = try? encoder.encode(entry) else { return }
        data.append(0x0A)

        rotateIfNeeded(adding: data.count)
        if !fileManager.fileExists(atPath: logURL.path) {
            _ = fileManager.createFile(
                atPath: logURL.path,
                contents: nil,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
        }
        guard let handle = try? FileHandle(forWritingTo: logURL) else { return }
        defer { try? handle.close() }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            return
        }
    }

    func recent(limit: Int = 500) -> [AgentLogEntry] {
        let entries = [rotatedLogURL, logURL].flatMap(readEntries)
        return Array(entries.suffix(max(1, min(limit, 2_000))).reversed())
    }

    func formattedRecent(limit: Int = 500) -> String {
        let formatter = ISO8601DateFormatter()
        return recent(limit: limit).map {
            "\(formatter.string(from: $0.timestamp)) [\($0.level.rawValue.uppercased())] " +
                "\($0.category).\($0.action) — \($0.message)"
        }.joined(separator: "\n")
    }

    func clear() {
        try? fileManager.removeItem(at: logURL)
        try? fileManager.removeItem(at: rotatedLogURL)
    }

    private func rotateIfNeeded(adding bytes: Int) {
        let attributes = try? fileManager.attributesOfItem(atPath: logURL.path)
        let currentSize = (attributes?[.size] as? NSNumber)?.intValue ?? 0
        guard currentSize + bytes > maximumFileSize else { return }
        try? fileManager.removeItem(at: rotatedLogURL)
        try? fileManager.moveItem(at: logURL, to: rotatedLogURL)
    }

    private func readEntries(from url: URL) -> [AgentLogEntry] {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            return []
        }
        return text.split(separator: "\n").compactMap {
            try? decoder.decode(AgentLogEntry.self, from: Data($0.utf8))
        }
    }

    private func sanitize(_ value: String) -> String {
        String(
            value
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .prefix(1_000)
        )
    }
}
