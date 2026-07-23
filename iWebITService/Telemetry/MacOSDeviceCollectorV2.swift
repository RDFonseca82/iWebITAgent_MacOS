import Foundation
import iWebITCore

struct MacOSDeviceCollectorV2 {
    func collect() -> DeviceSnapshot {
        let profiler = getDeviceSyncInfo(fullSyncVars)
        let software = getSPSoftwareDataType(profiler["SPSoftwareDataType"] as? AnyList)
        let hardware = getSPHardwareDataType(profiler["SPHardwareDataType"] as? AnyList)
        let totalStorage = FileManager.getTotalStorageCapacity()
        let usedStorage = FileManager.getUsedStorageSpace()
        let availableStorage: Int64?
        if let totalStorage, let usedStorage {
            availableStorage = totalStorage - usedStorage
        } else {
            availableStorage = nil
        }
        let battery = BatteryFinder().getInternalBattery()

        return DeviceSnapshot(
            platform: .macOS,
            identity: DeviceIdentity(
                deviceID: AppInfo.uniqueid,
                displayName: software.hostName,
                serialNumber: hardware.serialNumber.nilIfEmpty,
                model: hardware.appleModel,
                modelIdentifier: hardware.appleModel.nilIfEmpty
            ),
            operatingSystem: OperatingSystemInfo(
                name: "macOS",
                version: software.appleVersion,
                build: command("/usr/sbin/sysctl", ["-n", "kern.osversion"]).nilIfEmpty,
                kernelVersion: command("/usr/sbin/sysctl", ["-n", "kern.osrelease"]).nilIfEmpty,
                locale: Locale.current.identifier,
                timeZone: TimeZone.current.identifier,
                uptimeSeconds: ProcessInfo.processInfo.systemUptime
            ),
            hardware: HardwareInfo(
                architecture: architecture(),
                processor: hardware.cpuType.nilIfEmpty,
                processorCount: Int(hardware.numProcessors) ?? ProcessInfo.processInfo.processorCount,
                activeProcessorCount: ProcessInfo.processInfo.activeProcessorCount,
                physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
                bootROMVersion: hardware.bootRom.nilIfEmpty,
                smcVersion: hardware.smcVersionSystem.nilIfEmpty
            ),
            storage: StorageInfo(
                totalBytes: totalStorage,
                availableBytes: availableStorage
            ),
            battery: battery.map {
                BatteryInfo(
                    level: $0.charge,
                    state: nil,
                    isLowPowerModeEnabled: lowPowerModeEnabled()
                )
            },
            network: NetworkInfo(
                hostName: software.hostName,
                interfaces: [],
                currentTransport: nil
            ),
            security: SecurityInfo(
                isEncrypted: command("/usr/bin/fdesetup", ["status"]).contains("FileVault is On"),
                systemIntegrityProtectionEnabled: command("/usr/bin/csrutil", ["status"]).contains("enabled"),
                firewallEnabled: command(
                    "/usr/libexec/ApplicationFirewall/socketfilterfw",
                    ["--getglobalstate"]
                ).contains("enabled"),
                gatekeeperEnabled: command("/usr/sbin/spctl", ["--status"]).contains("enabled")
            ),
            management: ManagementInfo(isManaged: false),
            agent: AgentInfo(
                version: Constants.AGENT_VERSION,
                build: Constants.AGENT_BUILD,
                bundleIdentifier: Constants.BUNDLE_ID,
                pushTokenAvailable: false,
                backgroundRefreshStatus: "launchd"
            ),
            location: nil,
            applications: applications(from: profiler["SPApplicationsDataType"] as? AnyList),
            services: getServices().map {
                SystemService(
                    label: $0["Name"] ?? "unknown",
                    state: $0["State"] ?? "unknown",
                    startMode: $0["StartMode"],
                    executablePath: $0["PathName"]
                )
            },
            permissions: [],
            collection: [
                CollectionResult(category: "identity", state: .collected, source: .privilegedAgent),
                CollectionResult(category: "hardware", state: .collected, source: .privilegedAgent),
                CollectionResult(category: "applications", state: .collected, source: .privilegedAgent),
                CollectionResult(category: "services", state: .collected, source: .privilegedAgent),
                CollectionResult(
                    category: "location",
                    state: .unavailable,
                    source: .privilegedAgent,
                    message: "Location is supplied separately by the consented UI process."
                )
            ]
        )
    }

    private func applications(from values: AnyList?) -> [InstalledApplication] {
        guard let applications = values as? [AnyDict] else { return [] }
        return applications.map {
            InstalledApplication(
                name: $0["_name"] as? String ?? "Unknown",
                bundleIdentifier: $0["info"] as? String,
                version: $0["version"] as? String,
                installedAt: ($0["lastModified"] as? String).flatMap(ISO8601DateFormatter().date),
                path: $0["path"] as? String,
                source: .privilegedAgent
            )
        }
    }

    private func command(_ executable: String, _ arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            return String(
                decoding: pipe.fileHandleForReading.readDataToEndOfFile(),
                as: UTF8.self
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return ""
        }
    }

    private func lowPowerModeEnabled() -> Bool {
        if #available(macOS 12.0, *) {
            return ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        return false
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
