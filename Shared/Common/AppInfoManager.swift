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
    
    func getValue(key: String) -> Any {
        do {
            guard let jsonString = filesManager.loadFile(filename: appInfoFileName) else { throw iWebITError.loadingContentError }
            return try jsonString.toJsonObject()[key] ?? "?"
        } catch {
            print("Error getting JSON file: \(error)")
            return "?"
        }
    }
    
    func setValue(key: String, value: Any) {
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
        filesManager.createIfNeeded(filename: appInfoFileName, content: initialAppInfo)
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
          "agentversion": "AGENTVERSION",
          "fullsync": "0",
          "devicelocation": "0",
          "reboot": "0",
          "shutdown": "0",
          "timesync": "?",
          "timealive": "?",
          "nexttimesync": "01/01/1900 00:00:00",
          "nexttimealive": "01/01/1900 00:00:00",
          "firstrun": "1",
          "allprepared": "0",
          "mssqlserver": "0",
          "servicerunning": "0",
          "net": "0",
          "manualupdate": "0",
          "dolog": "0"
        }
        """
    }
}
