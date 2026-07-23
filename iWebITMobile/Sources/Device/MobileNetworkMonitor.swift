import Foundation
import Network
import iWebITCore

final class MobileNetworkMonitor: @unchecked Sendable {
    static let shared = MobileNetworkMonitor()

    struct Snapshot {
        let info: NetworkInfo
        let isAvailable: Bool
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "app.iwebit.mobile.network")
    private let lock = NSLock()
    private var snapshot = Snapshot(info: NetworkInfo(), isAvailable: false)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.store(path)
        }
        monitor.start(queue: queue)
    }

    func current() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshot
    }

    private func store(_ path: NWPath) {
        let transport: String?
        if path.usesInterfaceType(.wifi) {
            transport = "wifi"
        } else if path.usesInterfaceType(.cellular) {
            transport = "cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            transport = "wiredEthernet"
        } else if path.usesInterfaceType(.loopback) {
            transport = "loopback"
        } else if path.usesInterfaceType(.other) {
            transport = "other"
        } else {
            transport = nil
        }

        let updated = Snapshot(
            info: NetworkInfo(
                interfaces: [],
                currentTransport: transport,
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained
            ),
            isAvailable: path.status == .satisfied
        )
        lock.lock()
        snapshot = updated
        lock.unlock()
    }
}
