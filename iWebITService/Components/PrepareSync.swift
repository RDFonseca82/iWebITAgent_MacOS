//
//  PrepareSync.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 29/08/2023.
//

import Foundation

private func jsonSafeValue(_ value: Any) -> Any {
    if value is NSNull { return NSNull() }
    if let value = value as? String { return value }
    if let value = value as? Bool { return value }
    if let value = value as? Int { return value }
    if let value = value as? Int8 { return Int(value) }
    if let value = value as? Int16 { return Int(value) }
    if let value = value as? Int32 { return Int(value) }
    if let value = value as? Int64 { return value }
    if let value = value as? UInt { return value }
    if let value = value as? UInt8 { return UInt(value) }
    if let value = value as? UInt16 { return UInt(value) }
    if let value = value as? UInt32 { return UInt(value) }
    if let value = value as? UInt64 { return value }
    if let value = value as? Double { return value.isFinite ? value : 0.0 }
    if let value = value as? Float { return value.isFinite ? value : 0.0 }
    if let value = value as? NSNumber {
        let number = value.doubleValue
        return number.isFinite ? value : NSNumber(value: 0)
    }
    if let value = value as? [String: Any] {
        return value.mapValues(jsonSafeValue)
    }
    if let value = value as? [Any] {
        return value.map(jsonSafeValue)
    }

    log("JSON VALUE NORMALIZED: \(String(describing: type(of: value)))", important: true)
    return String(describing: value)
}

private func safeJSONData(from data: [String: Any]) throws -> (object: [String: Any], encoded: Data) {
    guard let object = jsonSafeValue(data) as? [String: Any],
          JSONSerialization.isValidJSONObject(object) else {
        throw iWebITError.decodingError
    }
    return (
        object,
        try JSONSerialization.data(withJSONObject: object, options: .withoutEscapingSlashes)
    )
}

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
    
    log("JSON SANITIZATION STARTED", important: true)
    let safeObject: [String: Any]
    let jsonData: Data
    do {
        let result = try safeJSONData(from: data)
        safeObject = result.object
        jsonData = result.encoded
    } catch {
        log("JSON SERIALIZATION FAILED: \(error)", important: true)
        if typeSync == "1" {
            reportAgentActivity(id: "full_sync", name: "Sincronização completa", status: "failed")
        } else if typeSync == "2" {
            reportAgentActivity(id: "min_sync", name: "Sincronização mínima", status: "failed")
        }
        return
    }
    log("GETTING 13: JSON READY (\(jsonData.count) bytes)", important: true)
    
    if AppInfo.dolog == "1" {
        if let prettyJsonData = try? JSONSerialization.data(withJSONObject: safeObject, options: [.prettyPrinted, .withoutEscapingSlashes]) {
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

