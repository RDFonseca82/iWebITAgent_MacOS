//
//  PrepareSync.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 29/08/2023.
//

import Foundation


func prepareAndSendSync(_ typeSync: String = "0", extraData: [String: Any]? = nil) {
    ensureUserLoggedIn()
    var data = [String: Any]()
    if typeSync == "1" {
        reportAgentActivity(id: "full_sync", name: "Sincronização completa", status: "running")
        log("DOING FULL SYNC")
        data = prepareFullSyncData()
        
    } else if typeSync == "2" {
        reportAgentActivity(id: "min_sync", name: "Sincronização mínima", status: "running")
        log("DOING MIN SYNC")
        data = prepareMinSyncData()
        
    } else {
        log("SENDING SWITCH VARIABLE")
        guard let extraData = extraData else {
            fatalError("Providing 0 as type sync requires extra data to be not null.")
        }
        data = extraData
        
    }
    log("GETTING 10")
    if typeSync != "0" {
        data["TypeSync"] = typeSync
    }
    log("GETTING 11")
    
    data["UniqueID"] = AppInfo.uniqueid
    data["IDSync"] = AppInfo.idsync
    data["IdCompany"] = AppInfo.idcompany
    data["LastConnectDate"] = Date().toString()
    data["AgentVersion"] = AppInfo.agentversion
    data["IdDeviceType"] = 62
    data["AppleBattery"] = BatteryFinder().getInternalBattery()?.charge ?? 100.0
    data["AppleType"] = 1 // para ios é 2
    data["ComputerSystem_UserName"] = getUserNameId()
    log("GETTING 12", important: true)
    
    guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .withoutEscapingSlashes) else {
        log("ERROR \(iWebITError.decodingError)", important: true)
        return
    }
    
    log("GETTING 13")
    
    if AppInfo.dolog == "1" {
        if let prettyJsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .withoutEscapingSlashes]) {
            FileManager.default.createFile(atPath: Constants.VARS_FILE.path, contents: prettyJsonData, attributes: nil)
        }
    }
    
    log("PREPARED TO SEND DATA")
    doUntil({
        try NetworkingManager.send(url: Constants.createOrSendDeviceInfoUrl, data: ["json": jsonData.toString()!])
        return false
    }, 60)

    if typeSync == "1" {
        reportAgentActivity(id: "full_sync", name: "Sincronização completa", status: "completed")
    } else if typeSync == "2" {
        reportAgentActivity(id: "min_sync", name: "Sincronização mínima", status: "completed")
    }
    
}

