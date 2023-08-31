//
//  MainLoop.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func mainLoop() async {
    log("==> STARTING MAIN LOOP <==")
    
//    resetRebootAndShutdownFlags()
    
//    updateCompanyInfo(firstTime: true)
    
//    synchronizeFiles()
    
    if AppInfo.firstrun == "1" {
        AppInfo.firstrun = "0"
    }
    
//    prepareAndSendSync("1")
//    updateDeviceInfo()
//    updateTimers("timesync")
//    updateTimers("timealive")
//    updateCompanyInfo(firstTime: false)
//    checkAppsToUninstall()
    
    if AppInfo.allprepared != "1" {
        AppInfo.allprepared = "1"
    }
    
    var sixtyLoopClock = 0
    
    while true {
        
        log("IM ALIVE", printOnly: true)
        try? await Task.sleep(seconds: 5)
        
        sixtyLoopClock += 5
        
    }
}
