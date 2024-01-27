//
//  AppInfoManager.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 18/08/2023.
//

import Foundation


class AppInfoManager {
    static let shared = AppInfoManager()
    
    private let filesManager = FilesManager.shared
    private let appInfoFileName = "appInfo.json"
    
    init() {
        createAppInfoFileIfNeeded()
    }
    
    func getValue(key: String) -> String {
        do {
            guard let jsonString = filesManager.loadFile(filename: appInfoFileName) else { throw iWebITError.loadingContentError }
            return try jsonString.toJsonObject()[key] ?? "?"
        } catch {
            print("Error getting JSON file: \(error)")
            return "?"
        }
    }
    
    func setValue(key: String, value: String) {
        do {
            var data = try getDecodedAppInfo()
            data[key] = value
            
            filesManager.saveFile(filename: appInfoFileName, content: try data.toJsonString())
        } catch {
            print("Error saving JSON to file: \(error)")
        }
    }
    
    private func getDecodedAppInfo() throws -> [String: Any] {
        guard let jsonString = filesManager.loadFile(filename: appInfoFileName) else { throw iWebITError.loadingContentError}
        return try jsonString.toJsonObject()
    }
    
    private func createAppInfoFileIfNeeded() {
        do {
            try filesManager.createFileIfNeeded(filename: appInfoFileName, content: initialAppInfo)
        } catch {
            print("ERRO1: \(error)")
        }
    }
    
    func syncAgentVersion() {
        if getValue(key: "agentversion") != Constants.AGENT_VERSION && Constants.AGENT_VERSION != "__VERSION__" && Constants.AGENT_VERSION != "" {
            setValue(key: "agentversion", value: Constants.AGENT_VERSION)
        }
    }
}

extension AppInfoManager {
    private var initialAppInfo: String {
        """
        {
          "uniqueid": "?",
          "idsync": "IDSYNC",
          "idcompany": "?",
          "companyname": "?",
          "agentversion": "\(Constants.AGENT_VERSION)",
          "fullsync": "0",
          "forcefullsync": "0",
          "devicelocation": "0",
          "reboot": "0",
          "shutdown": "0",
          "timesync": "?",
          "timealive": "?",
          "nexttimesync": "01/01/1900 00:00:00",
          "nexttimealive": "01/01/1900 00:00:00",
          "firstrun": "1",
          "allprepared": "0",
          "net": "0",
          "manualupdate": "0",
          "dolog": "0",
          "verbose": "0"
        }
        """
    }
}
