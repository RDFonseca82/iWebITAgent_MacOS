import Foundation
import iWebITCore

final class AgentXPCService: NSObject, NSXPCListenerDelegate, AgentXPCProtocol {
    typealias SyncHandler = @Sendable (_ full: Bool) async throws -> Void

    private let listener: NSXPCListener
    private let stateStore: AgentStateStore
    private let syncHandler: SyncHandler
    private let signatureValidator: ClientCodeSignatureValidator
    private let encoder: JSONEncoder

    init(
        stateStore: AgentStateStore,
        syncHandler: @escaping SyncHandler
    ) {
        self.listener = NSXPCListener(machServiceName: AgentXPCConfiguration.machServiceName)
        self.stateStore = stateStore
        self.syncHandler = syncHandler
        self.signatureValidator = ClientCodeSignatureValidator(
            teamID: AgentXPCConfiguration.allowedTeamID,
            bundleIdentifiers: AgentXPCConfiguration.allowedBundleIdentifiers
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        super.init()
        listener.delegate = self
    }

    func resume() {
        listener.resume()
    }

    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        guard signatureValidator.prepare(newConnection) else {
            return false
        }
        newConnection.exportedInterface = NSXPCInterface(with: AgentXPCProtocol.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = {}
        newConnection.interruptionHandler = {}
        newConnection.resume()
        return true
    }

    func fetchState(withReply reply: @escaping (Data?, NSError?) -> Void) {
        Task {
            do {
                let data = try encoder.encode(await stateStore.load())
                reply(data, nil)
            } catch {
                reply(nil, error as NSError)
            }
        }
    }

    func requestSynchronization(full: Bool, withReply reply: @escaping (NSError?) -> Void) {
        Task {
            do {
                try await syncHandler(full)
                reply(nil)
            } catch {
                reply(error as NSError)
            }
        }
    }

    func storePushToken(_ token: Data, withReply reply: @escaping (NSError?) -> Void) {
        Task {
            do {
                _ = try await stateStore.update { state in
                    state.pushToken = token
                }
                reply(nil)
            } catch {
                reply(error as NSError)
            }
        }
    }
}
