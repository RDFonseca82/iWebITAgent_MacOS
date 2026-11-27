import BackgroundTasks
import Foundation
import iWebITCore
import UIKit

final class BackgroundRefreshCoordinator {
    static let shared = BackgroundRefreshCoordinator()

    static let refreshIdentifier = "app.iwebit.mobile.refresh"
    static let processingIdentifier = "app.iwebit.mobile.processing"

    private init() {}

    func register() {
        let registered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                Task {
                    await AgentLogger.shared.log(
                        .error,
                        category: "background",
                        action: "invalid-task",
                        message: "Tipo de tarefa de background inesperado."
                    )
                }
                return
            }
            self.handle(refreshTask)
        }
        Task {
            await AgentLogger.shared.log(
                registered ? .info : .warning,
                category: "background",
                action: "register",
                message: registered
                    ? "Tarefa de atualização registada."
                    : "Não foi possível registar a tarefa de atualização."
            )
        }
    }

    func scheduleRefresh(earliestBeginDate: Date = Date(timeIntervalSinceNow: 15 * 60)) {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshIdentifier)
        request.earliestBeginDate = earliestBeginDate
        do {
            try BGTaskScheduler.shared.submit(request)
            Task {
                await AgentLogger.shared.log(
                    category: "background",
                    action: "scheduled",
                    message: "Atualização em segundo plano agendada."
                )
            }
        } catch {
            Task {
                await AgentLogger.shared.log(
                    .warning,
                    category: "background",
                    action: "schedule-failure",
                    message: "O sistema recusou o agendamento em segundo plano (\(String(describing: error)))."
                )
            }
        }
    }

    private func handle(_ task: BGAppRefreshTask) {
        scheduleRefresh()
        Task {
            await AgentLogger.shared.log(
                category: "background",
                action: "execute",
                message: "Atualização em segundo plano iniciada."
            )
        }
        let syncTask = Task {
            let success = await MobileSyncTrigger.shared.performBackgroundSync()
            task.setTaskCompleted(success: success)
            await AgentLogger.shared.log(
                success ? .info : .warning,
                category: "background",
                action: "complete",
                message: success
                    ? "Atualização em segundo plano concluída."
                    : "Atualização em segundo plano falhou."
            )
        }
        task.expirationHandler = {
            syncTask.cancel()
            Task {
                await AgentLogger.shared.log(
                    .warning,
                    category: "background",
                    action: "expired",
                    message: "Atualização cancelada pelo limite do sistema."
                )
            }
        }
    }
}

actor MobileSyncTrigger {
    static let shared = MobileSyncTrigger()
    private var operation: (@Sendable () async -> Bool)?
    private var isSynchronizing = false

    func install(_ operation: @escaping @Sendable () async -> Bool) {
        self.operation = operation
    }

    func performBackgroundSync() async -> Bool {
        guard !isSynchronizing else {
            await AgentLogger.shared.log(
                category: "background",
                action: "already-running",
                message: "Já existe uma sincronização em segundo plano em execução."
            )
            return true
        }
        isSynchronizing = true
        defer { isSynchronizing = false }

        if let operation {
            return await operation()
        }

        await AgentLogger.shared.log(
            category: "background",
            action: "independent-sync",
            message: "A sincronização em segundo plano será executada sem depender da interface."
        )
        return await MobileBackgroundSynchronizer.shared.synchronize()
    }
}

private actor MobileBackgroundSynchronizer {
    static let shared = MobileBackgroundSynchronizer()

    private let credentialStore = KeychainLegacyAppleCredentialStore()

    func synchronize() async -> Bool {
        do {
            guard try credentialStore.load() != nil else {
                await AgentLogger.shared.log(
                    .warning,
                    category: "background",
                    action: "credentials-unavailable",
                    message: "Não existem credenciais guardadas para a sincronização em segundo plano."
                )
                return false
            }

            let client = try LegacyAppleAPIClient(
                syncURL: try configuredURL("IWebITAppleSyncURL"),
                apiURL: try configuredURL("IWebITLegacyAPIURL"),
                supportURL: try configuredURL("IWebITLegacySupportURL")
            )
            let pushTokenAvailable = await MainActor.run {
                UIApplication.shared.isRegisteredForRemoteNotifications
            }
            let service = MobileSyncService(
                client: client,
                credentialStore: credentialStore,
                pushTokenAvailable: pushTokenAvailable
            )
            let success = await service.synchronize()
            await AgentLogger.shared.log(
                success ? .info : .warning,
                category: "background",
                action: "independent-result",
                message: success
                    ? "Sincronização autónoma em segundo plano concluída."
                    : "A sincronização autónoma em segundo plano falhou."
            )
            return success
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "background",
                action: "independent-configuration-failure",
                message: "Não foi possível configurar a sincronização autónoma."
            )
            return false
        }
    }

    private func configuredURL(_ key: String) throws -> URL {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: rawValue) else {
            throw CoreError.invalidURL
        }
        return url
    }
}
