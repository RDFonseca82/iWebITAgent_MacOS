//
//  PrepareMinSyncData.swift
//  iWebITService
//
//  Created by Admin on 23/09/2023.
//

import Foundation


let minSyncVars = ["SPNetworkDataType", "SPHardwareDataType"]


func prepareMinSyncData() -> [String: Any] {
    let dInfo = getDeviceSyncInfo(minSyncVars)
    var data = [String: Any]()
    
    data["DeviceHost"] = getDeviceHost(dInfo["SPNetworkDataType"] as? AnyList)
    data["AppleMemoryTotal"] = getTotalMemory(dInfo["SPHardwareDataType"] as? AnyList)
    data["AppleMemoryUsed"] = getMemoryUsage()
    
    return data
}


func getTotalMemory(_ spHardwareDataType: AnyList?) -> Int64 {
    guard
        let spHardwareDataType = spHardwareDataType,
        spHardwareDataType.count > 0,
        let info = spHardwareDataType[0] as? AnyDict,
        let memoryGb = info["physical_memory"] as? String
    else { return 0 }
    
    return Int64(memoryGb.split(separator: " ")[0])! * gigabyteToByte
}

func getDeviceHost(_ spNetworkDataType: AnyList?) -> String {
    guard
        let spNetworkDataType = spNetworkDataType,
        spNetworkDataType.count > 0,
        let info = spNetworkDataType[0] as? AnyDict,
        let ipAdresses = info["ip_address"] as? AnyList,
        ipAdresses.count > 0
    else { return "" }
    
    return ipAdresses[0] as! String
}
