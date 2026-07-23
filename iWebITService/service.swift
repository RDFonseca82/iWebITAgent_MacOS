//
//  service.swift
//  iWebITService
//
//  Created by Admin on 26/08/2023.
//

import Foundation
#if IWEBIT_V2
import iWebITCore
#endif

@main
struct Service {
    static func main() throws {
        Constants.shared.LOG_FILE = Constants.shared.LOG_FILE.appendingPathComponent("log_service.log")
        Constants.shared.OLD_LOG_FILE = Constants.shared.OLD_LOG_FILE.appendingPathComponent("old_log_service.log")

        #if IWEBIT_V2
        let stateURL = try daemonStateURL()
        let stateStore = AgentStateStore(fileURL: stateURL)
        let xpcService = AgentXPCService(stateStore: stateStore) { full in
            prepareAndSendSync(full ? "1" : "2")
        }
        xpcService.resume()
        let automaticUpdateTask = MacAutomaticUpdateCoordinator.startIfConfigured(
            installedBuild: Int(Constants.AGENT_BUILD) ?? 0
        ) { event in
            log("UPDATE V2: \(event)", important: true)
        }
        #endif

        mainLoop()

        #if IWEBIT_V2
        withExtendedLifetime((xpcService, automaticUpdateTask)) {}
        #endif
    }

    #if IWEBIT_V2
    private static func daemonStateURL() throws -> URL {
        let root = URL(fileURLWithPath: "/Library/Application Support/iWebITAgent", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("agent-state-v2.json", isDirectory: false)
    }
    #endif
}
