import BackgroundTasks

final class BackgroundRefreshCoordinator {
    static let shared = BackgroundRefreshCoordinator()

    static let refreshIdentifier = "app.iwebit.mobile.refresh"
    static let processingIdentifier = "app.iwebit.mobile.processing"

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handle(refreshTask)
        }
    }

    func scheduleRefresh(earliestBeginDate: Date = Date(timeIntervalSinceNow: 15 * 60)) {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshIdentifier)
        request.earliestBeginDate = earliestBeginDate
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Scheduling is opportunistic. Foreground and APNs sync remain the fallback.
        }
    }

    private func handle(_ task: BGAppRefreshTask) {
        scheduleRefresh()
        let syncTask = Task {
            let success = await MobileSyncTrigger.shared.performBackgroundSync()
            task.setTaskCompleted(success: success)
        }
        task.expirationHandler = {
            syncTask.cancel()
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
        guard let operation else { return false }
        return await operation()
    }
}
