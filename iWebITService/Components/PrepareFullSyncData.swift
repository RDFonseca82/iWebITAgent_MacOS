//
//  PrepareFullSyncData.swift
//  iWebITService
//
//  Created by Admin on 23/09/2023.
//

import Foundation


let fullSyncVars = ["SPNetworkDataType", "SPHardwareDataType", "SPSoftwareDataType", "SPApplicationsDataType"]

func prepareFullSyncData() -> [String: Any] {
    let dInfo = getDeviceSyncInfo(fullSyncVars)
    var data = [String: Any]()
    
    data["DeviceHost"] = getDeviceHost(dInfo["SPNetworkDataType"] as? AnyList)
    data["AppleMemoryTotal"] = getTotalMemory(dInfo["SPHardwareDataType"] as? AnyList)
    data["AppleMemoryUsed"] = getMemoryUsage()
    
    let softwareData = getSPSoftwareDataType(dInfo["SPSoftwareDataType"] as? AnyList)
    
    data["ComputerSystem_DNSHostName"] = softwareData.hostName
    data["AppleVersion"] = softwareData.appleVersion
    
    let hardwareData = getSPHardwareDataType(dInfo["SPHardwareDataType"] as? AnyList)
    
    data["AppleBootRomVersion"] = hardwareData.bootRom
    data["AppleModel"] = hardwareData.appleModel
    data["AppleCpuType"] = hardwareData.cpuType
    data["AppleProcessorSpeed"] = hardwareData.processorSpeed
    data["AppleNProcessors"] = pickNumProcessors(hardwareData.numProcessors)
    data["AppleOsLoader"] = hardwareData.osLoader
    
    data["AppleStorage"] = FileManager.getTotalStorageCapacity() ?? 0
    data["AppleStorageUsed"] = FileManager.getUsedStorageSpace() ?? 0
    
    data["Aplications"] = getSPApplicationsDataType(dInfo["SPApplicationsDataType"] as? AnyList)
    
    return data
}

func getSPSoftwareDataType(_ spSoftwareDataType: AnyList?) -> (hostName: String, appleVersion: String) {
    guard
        let spSoftwareDataType = spSoftwareDataType,
        spSoftwareDataType.count > 0,
        let info = spSoftwareDataType[0] as? AnyDict
    else { return ("","") }
    
    let hostName = info["local_host_name"] as? String
    let appleVersion = info["os_version"] as? String
    
    return (hostName ?? "", appleVersion ?? "")
}

func getSPHardwareDataType(_ spHardwareDataType: AnyList?) -> (bootRom: String, cpuType: String, processorSpeed: String, appleModel: String, numProcessors: String, osLoader: String) {
    guard
        let spHardwareDataType = spHardwareDataType,
        spHardwareDataType.count > 0,
        let info = spHardwareDataType[0] as? AnyDict
    else { return ("", "", "", "", "", "") }
    
    let bootRom = info["boot_rom_version"] as? String ?? ""
    let cpuType = info["cpu_type"] as? String ?? ""
    let processorSpeed = info["current_processor_speed"] as? String ?? ""
    let appleModel = info["machine_model"] as? String ?? ""
    let numProcessors = String(info["number_processors"] as? Int ?? -1)
    let osLoader = info["os_loader_version"] as? String ?? ""
    
    return (bootRom, cpuType, processorSpeed, appleModel, numProcessors, osLoader)
}

func getSPApplicationsDataType(_ spApplicationsDataType: AnyList?) -> [[String:String]] {
    guard
        let spApplicationsDataType = spApplicationsDataType,
        spApplicationsDataType.count > 0,
        let info = spApplicationsDataType as? [AnyDict]
    else { return [] }
    
    
    let applications: [[String:String]] = info.map { app in
        let name = app["_name"] as? String ?? "None"
        let date = (app["lastModified"] as? String ?? "1900-01-01T00:00:01Z")
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
        return ["name": name, "date": date]
    }
    
    
    return applications
}

func pickNumProcessors(_ strNumProcessors: String) -> String {
    if strNumProcessors.contains("proc") {
        //proc 11:5:6
        let numProcessors = String(strNumProcessors
            .split(separator: " ")[1]
            .split(separator: ":")[0])
        
        return numProcessors
    } else {
        return strNumProcessors
    }
}


