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
        syncAppInfoNewKeys()
    }
    
    func getValue(key: String) -> String {
        do {
            return try (getDecodedAppInfo()[key] as? String) ?? "?"
        } catch {
            log("Error getting JSON file: \(error)", important: true)
            return "?"
        }
    }
    
    func setValue(key: String, value: String) {
        do {
            var data = try getDecodedAppInfo()
            data[key] = value
            
            filesManager.saveFile(filename: appInfoFileName, content: try data.toJsonString())
        } catch {
            log("Error saving JSON to file: \(error)", important: true)
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
            log("ERRO: \(error)", important: true)
        }
    }
    
    func syncAppInfoNewKeys() {
        var currentAppInfo = (try? getDecodedAppInfo()) ?? [:]
        let defaultAppInfo = try! initialAppInfo.toJsonObject()
        
        let currentKeys = currentAppInfo.keys
        let defaultKeys = defaultAppInfo.keys
        
        guard !currentKeys.isEmpty else {
            createAppInfoFileIfNeeded()
            return
        }
        
        let keysToAppend = defaultKeys.filter { !currentKeys.contains($0) }
        let keysToRemove = currentKeys.filter { !defaultKeys.contains($0) }
        
        keysToRemove.forEach { key in
            currentAppInfo.removeValue(forKey: key)
        }
        
        keysToAppend.forEach { key in
            currentAppInfo[key] = defaultAppInfo[key]
        }
        do {
            filesManager.saveFile(filename: appInfoFileName, content: try currentAppInfo.toJsonString())
        } catch {
            log("Error saving JSON to file: \(error)", important: true)
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
