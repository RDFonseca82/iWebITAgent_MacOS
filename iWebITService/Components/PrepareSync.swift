//
//  PrepareSync.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 29/08/2023.
//

import Foundation

let fullSyncVars = [""]
let minSyncVars = [""]

func prepareAndSendSync(_ typeSync: String = "0", extraData: [String: Any]? = nil) async {
    ensureUserLoggedIn()
    var data = [String: Any]()
    if typeSync == "1" {
        log("DOING FULL SYNC")
//        data = getDeviceSyncInfo(fullSyncVars)
        
    } else if typeSync == "2" {
        log("DOING MIN SYNC")
        data = getDeviceSyncInfo(minSyncVars)
        
    } else {
        log("SENDING SWITCH VARIABLE")
        guard let extraData = extraData else {
            print("ERROR")
            fatalError("Providing 0 as type sync requires extra data to be not null.")
        }
        data = extraData
        
    }
    if typeSync != "0" {
        data["TypeSync"] = typeSync
        
    }
    data["UniqueID"] = AppInfo.uniqueid
    data["IDSync"] = AppInfo.idsync
    data["LastConnectDate"] = Date().toString()
    data["AgentVersion"] = AppInfo.agentversion
    
    guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .withoutEscapingSlashes) else {
        log("ERROR \(iWebITError.decodingError)", important: true)
        return
    }
    
    if AppInfo.dolog == "1" {
        if let prettyJsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .withoutEscapingSlashes]) {
            FileManager.default.createFile(atPath: Constants.VARS_FILE.path, contents: prettyJsonData, attributes: nil)
        }
    }
    
    log("PREPARED TO SEND DATA")
    await doUntilAsync({
        try await NetworkingManager.send(url: Constants.createOrSendDeviceInfoUrl, jsonData: ["json": String(data: jsonData, encoding: .utf8)!])
        return false
    }, 60)
    
}

