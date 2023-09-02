//
//  ManageUserInfo.swift
//  iWebITService
//
//  Created by Admin on 30/08/2023.
//

import Foundation


func updateDeviceInfo(callerName: String = #function, callerLineNum: Int = #line) async {
    log("UPDATING DEVICE INFO", important: true, callerName: callerName, callerLineNum: callerLineNum)
    
    await doUntilAsync({
        ensureUserLoggedIn()
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

func updateCompanyInfo(onInit: Bool, callerName: String = #function, callerLineNum: Int = #line) async {
    log("UPDATING COMPANY INFO", important: true, callerName: callerName, callerLineNum: callerLineNum)
    
    await doUntilAsync({
        ensureUserLoggedIn()
        let companyInfo = try await GetCompanyDataService.shared.getCompany()
        
        if onInit {
            let idCompany = companyInfo.idCompany!
            AppInfo.idcompany = idCompany
            AppInfo.companyname = companyInfo.company!
            AppInfo.timesync = String(companyInfo.timeSync ?? 0)
            AppInfo.timealive = String(companyInfo.timeAlive ?? 0)
            
            let localHostName = (getDeviceSyncInfo(["SPSoftwareDataType"])["SPSoftwareDataType"] as! [[String:Any]])[0]["local_host_name"] as! String
            
            let uniqueId = createUniqueId(value: idCompany+localHostName)
            
            if AppInfo.uniqueid == "?" {
                AppInfo.uniqueid = uniqueId
            }
            
            log("GENERATED UNIQUE ID: \(uniqueId)")
        } else {
            
        }
        
        return false
    }, 60)
}

func updateTimers(_ timeType: String) {
    let timeString = timeType == "timesync" ? AppInfo.timesync : AppInfo.timealive
    let timeValue = Int(timeString) ?? (timeType == "timesync" ? 120 : 5)
    
    let timeDelta = TimeInterval(timeValue) * 60
    let futureDateString = Date(timeIntervalSinceNow: timeDelta).toString()
    
    if timeType == "timesync" {
        AppInfo.nexttimesync = futureDateString
    } else {
        AppInfo.nexttimealive = futureDateString
    }
}

func resetRebootAndShutdownFlags() async {
    if AppInfo.reboot == "1" {
        await prepareAndSendSync(extraData: [
            "OperatingSystem_Reboot": "0"
        ])
        AppInfo.reboot = "0"
    }
    if AppInfo.shutdown == "1" {
        await prepareAndSendSync(extraData: [
            "OperatingSystem_ShutDown": "0"
        ])
        AppInfo.shutdown = "0"
    }
}

