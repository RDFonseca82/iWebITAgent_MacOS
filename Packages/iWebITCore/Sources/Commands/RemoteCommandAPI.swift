import Foundation

public struct PendingCommandsResponse: Codable, Equatable, Sendable {
    public let commands: [SignedCommand]
    public let nextCursor: String?

    public init(commands: [SignedCommand], nextCursor: String? = nil) {
        self.commands = commands
        self.nextCursor = nextCursor
    }
}

public struct CommandResultRequest: Codable, Equatable, Sendable {
    public let result: RemoteCommandResult

    public init(result: RemoteCommandResult) {
        self.result = result
    }
}

public struct RemoteCommandAPI: Sendable {
    private let client: SecureAPIClient

    public init(client: SecureAPIClient) {
        self.client = client
    }

    public func pending(after cursor: String? = nil) async throws -> PendingCommandsResponse {
        let query = cursor.map { [URLQueryItem(name: "after", value: $0)] } ?? []
        return try await client.get(
            "/v2/devices/commands",
            query: query,
            as: PendingCommandsResponse.self
        )
    }

    public func report(_ result: RemoteCommandResult) async throws {
        try await client.postWithoutResponse(
            "/v2/devices/commands/\(result.commandID.uuidString.lowercased())/result",
            body: CommandResultRequest(result: result)
        )
    }
}
