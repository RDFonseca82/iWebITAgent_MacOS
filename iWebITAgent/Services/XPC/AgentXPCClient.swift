import Foundation
import iWebITCore

final class AgentXPCClient {
    static let shared = AgentXPCClient()

    private let connection: NSXPCConnection
    private let decoder: JSONDecoder

    private init() {
        connection = NSXPCConnection(
            machServiceName: AgentXPCConfiguration.machServiceName,
            options: .privileged
        )
        connection.remoteObjectInterface = NSXPCInterface(with: AgentXPCProtocol.self)
        if #available(macOS 13.0, *) {
            connection.setCodeSigningRequirement(
                "anchor apple generic and certificate leaf[subject.OU] = \"\(AgentXPCConfiguration.allowedTeamID)\" and identifier \"com.rdfonseca.iWebITService\""
            )
        }
        connection.resume()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    deinit {
        connection.invalidate()
    }

    func fetchState() async throws -> AgentState {
        try await withCheckedThrowingContinuation { continuation in
            proxy().fetchState { data, error in
                do {
                    if let error { throw error }
                    guard let data else { throw CoreError.invalidResponse }
                    continuation.resume(returning: try self.decoder.decode(AgentState.self, from: data))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func requestSynchronization(full: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            proxy().requestSynchronization(full: full) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func proxy() -> AgentXPCProtocol {
        connection.remoteObjectProxyWithErrorHandler { error in
            log("XPC connection error: \(error)", important: true)
        } as! AgentXPCProtocol
    }
}
