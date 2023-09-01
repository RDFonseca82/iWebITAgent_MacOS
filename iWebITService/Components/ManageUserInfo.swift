//
//  ManageUserInfo.swift
//  iWebITService
//
//  Created by Admin on 30/08/2023.
//

import Foundation


func updateDeviceInfo() async {
    log("UPDATING DEVICE INFO", important: true)
    
    await doUntilAsync({
        let deviceInfo = try await GetDeviceDataService.shared.getDevice()
        
        AppInfo.fullsync = String(deviceInfo.fullSync ?? 0)
        AppInfo.devicelocation = String(deviceInfo.deviceLocation ?? 0)
        AppInfo.reboot = String(deviceInfo.operatingSystemReboot ?? 0)
        AppInfo.shutdown = String(deviceInfo.operatingSystemShutDown ?? 0)
        AppInfo.timesync = String(deviceInfo.timeSync ?? 0)
        AppInfo.timealive = String(deviceInfo.timeAlive ?? 0)
        
        return false
    }, 60)
}

func updateCompanyInfo(onInit: Bool) async {
    log("UPDATING COMPANY INFO", important: true)
    
    await doUntilAsync({
        let deviceInfo = try await GetDeviceDataService.shared.getDevice()
        
        if onInit {
            
        } else {
            
        }
        
        return false
    }, 60)
}

