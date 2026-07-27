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
                    message: "O sistema recusou o agendamento em segundo plano."
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
        guard let operation else {
            await AgentLogger.shared.log(
                .warning,
                category: "background",
                action: "missing-operation",
                message: "Não existe operação de sincronização instalada."
            )
            return false
        }
        return await operation()
    }
}
