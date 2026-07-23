import Foundation

public enum SupportTicketStatus: String, Codable, Sendable {
    case open
    case waitingForUser
    case waitingForSupport
    case resolved
    case closed
}

public struct SupportTicket: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let subject: String
    public let latestMessage: String
    public let createdAt: Date
    public let updatedAt: Date
    public let status: SupportTicketStatus

    public init(
        id: String,
        subject: String,
        latestMessage: String,
        createdAt: Date,
        updatedAt: Date,
        status: SupportTicketStatus
    ) {
        self.id = id
        self.subject = subject
        self.latestMessage = latestMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
    }
}

public struct SupportTicketList: Codable, Equatable, Sendable {
    public let tickets: [SupportTicket]

    public init(tickets: [SupportTicket]) {
        self.tickets = tickets
    }
}

public struct CreateSupportTicketRequest: Codable, Equatable, Sendable {
    public let name: String
    public let message: String

    public init(name: String, message: String) {
        self.name = name
        self.message = message
    }
}

public struct SupportRepository: Sendable {
    private let client: SecureAPIClient

    public init(client: SecureAPIClient) {
        self.client = client
    }

    public func tickets() async throws -> [SupportTicket] {
        try await client.get("/v2/support/tickets", as: SupportTicketList.self).tickets
    }

    public func create(name: String, message: String) async throws -> SupportTicket {
        try await client.post(
            "/v2/support/tickets",
            body: CreateSupportTicketRequest(name: name, message: message),
            as: SupportTicket.self
        )
    }
}
