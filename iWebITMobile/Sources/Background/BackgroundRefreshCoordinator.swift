import BackgroundTasks
import Foundation

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

    func install(_ operation: @escaping @Sendable () async -> Bool) {
        self.operation = operation
    }

    func performBackgroundSync() async -> Bool {
        if let operation {
            return await operation()
        }

        await AgentLogger.shared.log(
            category: "background",
            action: "waiting-for-operation",
            message: "A aguardar a configuração das credenciais para sincronização em segundo plano."
        )

        // When iOS relaunches the app for a background task, SwiftUI may still
        // be restoring the runtime and Keychain credentials. Wait briefly for
        // that setup instead of reporting a false failure immediately.
        for _ in 0..<20 {
            guard !Task.isCancelled else { return false }
            try? await Task.sleep(nanoseconds: 500_000_000)
            if let operation {
                return await operation()
            }
        }

        await AgentLogger.shared.log(
            .warning,
            category: "background",
            action: "missing-operation",
            message: "Não existe operação de sincronização instalada após a inicialização."
        )
        return false
    }
}
