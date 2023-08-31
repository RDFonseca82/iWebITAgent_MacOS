//
//  GetDeviceSyncInfo.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func getDeviceSyncInfo() {
    let jsonData = shell("system_profiler -json SPApplicationsDataType SPEthernetDataType SPHardwareDataType SPMemoryDataType SPNetworkDataType SPNetworkLocationDataType SPPowerDataType SPSerialATADataType SPSoftwareDataType SPStorageDataType 2>/dev/null").data(using: .utf8)
    
    do {
        guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData!) as? [String: Any] else {
            throw iWebITError.decodingError
        }
        
        print(jsonObject["SPPowerDataType"]!)
    } catch {
        print("Error parsing JSON: \(error)")
    }
}

