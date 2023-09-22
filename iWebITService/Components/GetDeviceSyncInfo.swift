//
//  GetDeviceSyncInfo.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation

typealias AnyDict = [String:Any]
typealias AnyList = [Any]

let fullSyncVars = [""]
let minSyncVars = ["SPNetworkDataType"]

func prepareFullSyncData() -> [String: Any] {
    return [:]
}

func prepareMinSyncData() -> [String: Any] {
//    let dInfo = getDeviceSyncInfo(minSyncVars)
//    var data = [String: Any]()
    
    
    return [:]
}

//data["DeviceHost"] = dInfo["SPNetworkDataType"][0]["ip_address"][0] as? String ?? ""
//data["DeviceHost"] = ((dInfo["SPNetworkDataType"] as? AnyList)?
//                      [0])
//data["AppleMemoryTotal"] =
//data["AppleMemoryUsed"] =

//SPApplicationsDataType SPEthernetDataType SPHardwareDataType SPMemoryDataType SPNetworkDataType SPNetworkLocationDataType SPPowerDataType SPSerialATADataType SPSoftwareDataType SPStorageDataType

func getDeviceSyncInfo(_ varsList: [String]) -> [String: Any] {
    let jsonData = shell("system_profiler -json \(varsList.joined(separator: " ")) 2>/dev/null").data(using: .utf8)
    
    do {
        guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData!) as? [String: Any] else {
            throw iWebITError.decodingError
        }
        
        return jsonObject
    } catch {
        log("Error parsing JSON: \(error)", important: true)
    }
    return [:]
}
