//
//  GetDeviceSyncInfo.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


//SPApplicationsDataType SPEthernetDataType SPHardwareDataType SPMemoryDataType SPNetworkDataType SPNetworkLocationDataType SPPowerDataType SPSerialATADataType SPSoftwareDataType SPStorageDataType

func getDeviceSyncInfo(_ varsList: [String]) -> [String: Any] {
    let jsonData = shell("system_profiler -json \(varsList.joined(separator: " ")) 2>/dev/null")
    
    do {
        guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw iWebITError.decodingError
        }
        
        return jsonObject
    } catch {
        log("Error parsing JSON: \(error)", important: true)
    }
    return [:]
}
