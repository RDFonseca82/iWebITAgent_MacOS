import Foundation

public struct AgentState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var deviceID: String?
    public var companyID: String?
    public var companyName: String?
    public var lastSuccessfulSyncAt: Date?
    public var nextFullSyncAt: Date?
    public var nextHeartbeatAt: Date?
    public var lastAcceptedCommandAt: Date?
    public var pushToken: Data?

    public init(
        schemaVersion: Int = AgentState.currentSchemaVersion,
        deviceID: String? = nil,
        companyID: String? = nil,
        companyName: String? = nil,
        lastSuccessfulSyncAt: Date? = nil,
        nextFullSyncAt: Date? = nil,
        nextHeartbeatAt: Date? = nil,
        lastAcceptedCommandAt: Date? = nil,
        pushToken: Data? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.deviceID = deviceID
        self.companyID = companyID
        self.companyName = companyName
        self.lastSuccessfulSyncAt = lastSuccessfulSyncAt
        self.nextFullSyncAt = nextFullSyncAt
        self.nextHeartbeatAt = nextHeartbeatAt
        self.lastAcceptedCommandAt = lastAcceptedCommandAt
        self.pushToken = pushToken
    }
}

/// This store is intended to live only in the daemon. UI processes access it through XPC.
public actor AgentStateStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var cachedState: AgentState?

    public init(fileURL: URL) {
        self.fileURL = fileURL
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() throws -> AgentState {
        if let cachedState {
            return cachedState
        }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let state = AgentState()
            cachedState = state
            return state
        }
        do {
            let state = try decoder.decode(AgentState.self, from: Data(contentsOf: fileURL))
            guard state.schemaVersion <= AgentState.currentSchemaVersion else {
                throw CoreError.stateCorrupted
            }
            cachedState = state
            return state
        } catch {
            throw CoreError.stateCorrupted
        }
    }

    @discardableResult
    public func update(_ mutation: @Sendable (inout AgentState) -> Void) throws -> AgentState {
        var state = try load()
        mutation(&state)
        state.schemaVersion = AgentState.currentSchemaVersion

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try encoder.encode(state).write(to: fileURL, options: .atomic)
        cachedState = state
        return state
    }
}
