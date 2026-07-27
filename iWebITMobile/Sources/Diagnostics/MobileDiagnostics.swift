import Foundation
import iWebITCore
import UIKit
import UserNotifications

struct DiagnosticItem: Identifiable, Sendable {
    let id = UUID()
    let section: String
    let label: String
    let value: String
}

struct MobileDiagnosticsReport: Sendable {
    let generatedAt: Date
    let items: [DiagnosticItem]
    let logs: [AgentLogEntry]
    let formattedLogs: String
}

struct MobileDiagnosticsBuilder: Sendable {
    @MainActor
    func build(
        credentials: DeviceCredentials,
        lastSuccessfulSyncAt: Date?,
        lastSyncStatus: String,
        pushTokenAvailable: Bool
    ) async -> MobileDiagnosticsReport {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let device = UIDevice.current
        let process = ProcessInfo.processInfo
        let network = MobileNetworkMonitor.shared.current()
        let addresses = await IPAddressResolver().resolve()
        let notificationStatus = await notificationAuthorization()
        let locationStatus = MobileLocationProvider.shared.authorizationDescription
        let logs = await AgentLogger.shared.recent()
        let formattedLogs = await AgentLogger.shared.formattedRecent()
        let server = (
            Bundle.main.object(forInfoDictionaryKey: "IWebITAPIBaseURL") as? String
        ) ?? "não configurado"

        var items: [DiagnosticItem] = [
            item("Agente", "Nome", Bundle.main.object(
                forInfoDictionaryKey: "CFBundleDisplayName"
            ) as? String ?? "iWebIT"),
            item("Agente", "Versão", appVersion),
            item("Agente", "Build", appBuild),
            item("Agente", "Bundle ID", Bundle.main.bundleIdentifier ?? "desconhecido"),
            item("Agente", "Servidor", server),
            item("Agente", "Device ID", credentials.deviceID),
            item("Agente", "Key ID", credentials.keyID),
            item("Sincronização", "Última sincronização", date(lastSuccessfulSyncAt)),
            item("Sincronização", "Último resultado", lastSyncStatus),
            item(
                "Sincronização",
                "Token de notificações",
                pushTokenAvailable ? "registado" : "não registado"
            ),
            item("Dispositivo", "Plataforma", device.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"),
            item("Dispositivo", "Nome", device.name),
            item("Dispositivo", "Modelo", device.model),
            item("Dispositivo", "Identificador do modelo", machineIdentifier()),
            item(
                "Dispositivo",
                "Identificador do fornecedor",
                device.identifierForVendor?.uuidString ?? "indisponível"
            ),
            item("Sistema", "Nome", device.systemName),
            item("Sistema", "Versão", device.systemVersion),
            item("Sistema", "Kernel", kernelVersion()),
            item("Sistema", "Idioma/Região", Locale.current.identifier),
            item("Sistema", "Fuso horário", TimeZone.current.identifier),
            item("Hardware", "Arquitetura", architecture()),
            item("Hardware", "Processadores", String(process.processorCount)),
            item("Hardware", "Processadores ativos", String(process.activeProcessorCount)),
            item("Hardware", "Memória física", bytes(process.physicalMemory)),
            item(
                "Bateria",
                "Nível",
                device.batteryLevel >= 0 ? "\(Int(device.batteryLevel * 100))%" : "indisponível"
            ),
            item("Rede", "Transporte", network.info.currentTransport ?? "indisponível"),
            item("Rede", "Ligação disponível", network.isAvailable ? "sim" : "não"),
            item(
                "Rede",
                "IP local",
                addresses.localAddresses.isEmpty
                    ? "indisponível"
                    : addresses.localAddresses.joined(separator: ", ")
            ),
            item(
                "Rede",
                "IP público",
                addresses.publicAddress ?? addresses.publicLookupError ?? "indisponível"
            ),
            item("Permissões", "Notificações", notificationStatus),
            item("Permissões", "Localização", locationStatus),
            item(
                "Permissões",
                "Atualização em segundo plano",
                UIApplication.shared.backgroundRefreshStatus.diagnosticDescription
            ),
            item("Logs", "Registos disponíveis", String(logs.count))
        ]

        if let expensive = network.info.isExpensive {
            items.append(item("Rede", "Ligação medida", expensive ? "sim" : "não"))
        }
        if let constrained = network.info.isConstrained {
            items.append(item("Rede", "Modo de dados reduzidos", constrained ? "sim" : "não"))
        }

        return MobileDiagnosticsReport(
            generatedAt: Date(),
            items: items,
            logs: logs,
            formattedLogs: formattedLogs
        )
    }

    private func notificationAuthorization() async -> String {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let value: String
                switch settings.authorizationStatus {
                case .notDetermined: value = "não solicitada"
                case .denied: value = "negada"
                case .authorized: value = "autorizada"
                case .provisional: value = "provisória"
                case .ephemeral: value = "temporária"
                @unknown default: value = "desconhecida"
                }
                continuation.resume(returning: value)
            }
        }
    }

    private func item(_ section: String, _ label: String, _ value: String) -> DiagnosticItem {
        DiagnosticItem(section: section, label: label, value: value)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    private func date(_ value: Date?) -> String {
        guard let value else { return "nunca" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: value)
    }

    private func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory)
    }

    private func machineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return tupleString(systemInfo.machine)
    }

    private func kernelVersion() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return tupleString(systemInfo.release)
    }

    private func tupleString<T>(_ tuple: T) -> String {
        Mirror(reflecting: tuple).children.reduce(into: "") { value, element in
            guard let byte = element.value as? Int8, byte != 0 else { return }
            value.append(Character(UnicodeScalar(UInt8(byte))))
        }
    }

    private func architecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}

private extension UIBackgroundRefreshStatus {
    var diagnosticDescription: String {
        switch self {
        case .available: return "disponível"
        case .denied: return "negada"
        case .restricted: return "restrita"
        @unknown default: return "desconhecida"
        }
    }
}
