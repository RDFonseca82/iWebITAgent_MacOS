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
    data["AppleSerialNumber"] = hardwareData.serialNumber
    data["AppleSMCVersionSystem"] = hardwareData.smcVersionSystem
    
    data["AppleStorage"] = FileManager.getTotalStorageCapacity() ?? 0
    data["AppleStorageUsed"] = FileManager.getUsedStorageSpace() ?? 0
    
    data["Aplications"] = getSPApplicationsDataType(dInfo["SPApplicationsDataType"] as? AnyList)
    
    data["Services"] = getServices()
    
    return data
}

func getSPSoftwareDataType(_ spSoftwareDataType: AnyList?) -> (hostName: String, appleVersion: String) {
    guard
        let spSoftwareDataType = spSoftwareDataType,
        spSoftwareDataType.count > 0,
        let info = spSoftwareDataType[0] as? AnyDict
    else { return ("","") }
    
    let hostName = info["local_host_name"] as? String ?? ""
    let appleVersion = info["os_version"] as? String ?? ""
    
    return (hostName, appleVersion)
}

func getSPHardwareDataType(_ spHardwareDataType: AnyList?) -> (
    bootRom: String, cpuType: String, processorSpeed: String,
    appleModel: String, numProcessors: String, osLoader: String,
    serialNumber: String, smcVersionSystem: String) {
    guard
        let spHardwareDataType = spHardwareDataType,
        spHardwareDataType.count > 0,
        let info = spHardwareDataType[0] as? AnyDict
    else { return ("", "", "", "", "", "", "", "") }
    
    let bootRom = info["boot_rom_version"] as? String ?? ""
    let cpuType = info["cpu_type"] as? String ?? ""
    let processorSpeed = info["current_processor_speed"] as? String ?? ""
    let appleModel = info["machine_model"] as? String ?? ""
    let numProcessors = String(info["number_processors"] as? Int ?? -1)
    let osLoader = info["os_loader_version"] as? String ?? ""
    let serialNumber = info["serial_number"] as? String ?? ""
    let smcVersionSystem = info["SMC_version_system"] as? String ?? ""
    
    return (bootRom, cpuType, processorSpeed, appleModel, numProcessors, osLoader, serialNumber, smcVersionSystem)
}

func getSPApplicationsDataType(_ spApplicationsDataType: AnyList?) -> [[String:String]] {
    guard
        let spApplicationsDataType = spApplicationsDataType,
        spApplicationsDataType.count > 0,
        let info = spApplicationsDataType as? [AnyDict]
    else { return [] }
    
    
    let applications: [[String:String]] = info.map { app in
        // .folding(options: .diacriticInsensitive, locale: .current)
        let name = (app["_name"] as? String ?? "None")
            .replacingOccurrences(of: "ã", with: "ã")
            .replacingOccurrences(of: "ç", with: "ç")
            .replacingOccurrences(of: "é", with: "é")
            .replacingOccurrences(of: "ê", with: "ê")
            .replacingOccurrences(of: "Á", with: "Á")
            .replacingOccurrences(of: "á", with: "á")
            .replacingOccurrences(of: "à", with: "à")
            .replacingOccurrences(of: "ó", with: "ó")
            .replacingOccurrences(of: "õ", with: "õ")
            .replacingOccurrences(of: "í", with: "í")
            .replacingOccurrences(of: "ú", with: "ú")
        let date = (app["lastModified"] as? String ?? "1900-01-01T00:00:01Z")
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
        
        return ["name": name, "date": date]
    }
    
    return applications
}

func getServices() -> [[String:String]] {
    #if DEBUG
    guard let output = shell("( launchctl list ) | grep -v 'com.apple.'").toString() else { return [] }
    #else
    guard let output = shell("( launchctl list ; su - \(getUserNameId()) -c 'launchctl list' ) | grep -v 'com.apple.'").toString() else { return [] }
    #endif
    
    let lines = output.split(separator: "\n")
    var services: [[String:String]] = []
    let fileManager = FileManager.default
    let possiblePlistLocations = ["/Users/\(getUserNameId())/Library/LaunchAgents", "/Library/LaunchAgents", "/Library/LaunchDaemons"]
    
    for line in lines {
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        if components.contains("PID") { continue }
        
        if components.count == 3 {
            let state = components[1] == "0" ? "Running" : "Stopped"
            let name = components[2]
            
            if name.contains("application.") { continue }
            
            let plistPaths = possiblePlistLocations
                .map { "\($0)/\(name).plist" }
                .filter { fileManager.fileExists(atPath: $0) }
            
            if !plistPaths.isEmpty {
                for path in plistPaths {
                    do {
                        let url = URL(fileURLWithPath: path)
                        let data = try Data(contentsOf:url)
                        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String:Any] else {
                            log("NO DATA FOR \(path)", important: true)
                            continue
                        }
                        services.append(
                            ["Name": name,
                             "State": state,
                             "StartMode": (plist["RunAtLoad"] as? Int ?? 0) == 1 ? "Auto" : "Manual",
                             "PathName": (plist["ProgramArguments"] as! NSArray)[0] as! String]
                        )
                    } catch {
                        log("ERROR READING PLIST FOR \(path): \(error)", important: true)
                    }
                }
            } else {
                var output = shell("launchctl list \(name)").toString()!
                
                if output.contains("Could not find service") || output.isBlank() {
                    output = shell("su - \(getUserNameId()) -c 'launchctl list \(name)'").toString()!
                }
                
                if output.contains("Could not find service") || output.isBlank() {
                    continue
                }
                
                var programPath = output
                    .split(separator: "\n")
                    .filter { $0.contains("Program\"") }[0]
                    .replacingOccurrences(of: "\t", with: "")
                    .split(separator: "=")[1]
                
                programPath = programPath
                    .prefix(upTo: programPath.index(programPath.endIndex, offsetBy: -2))
                    .suffix(from: programPath.index(programPath.startIndex, offsetBy: 2))
                
                services.append(
                    ["Name": name,
                     "State": state,
                     "StartMode": "Auto",
                     "PathName": String(programPath)]
                )
            }
        }
    }
    
    return services
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

extension Data {
    var stringEncoding: String.Encoding? {
        var nsString: NSString?
        guard case let rawValue = NSString.stringEncoding(for: self, encodingOptions: nil, convertedString: &nsString, usedLossyConversion: nil), rawValue != 0 else { return nil }
        return .init(rawValue: rawValue)
    }
}
