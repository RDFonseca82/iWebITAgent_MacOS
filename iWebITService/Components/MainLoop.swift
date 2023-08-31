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
        
        if Date().timeIntervalSince(AppInfo.nexttimesync.toDate()) > 0 {
            log("INSIDE FULL SYNC")
//            prepareAndSendSync("1")
            
//            updateTimers("timesync")
//            updateTimers("timealive")
        }
        
        if Date().timeIntervalSince(AppInfo.nexttimealive.toDate()) > 0 {
            log("INSIDE MIN SYNC")
//            prepareAndSendSync("2")
            
//            updateTimers("timealive")
            
//            updateDeviceInfo()
//            updateCompanyInfo(firstTime: false)
//            checkAppsToUninstall()
        }
        
        if sixtyLoopClock == 60 {
            sixtyLoopClock = 0
            
            secondaryLoop()
        }
        
        log("IM ALIVE", printOnly: true)
        try? await Task.sleep(seconds: 5)
        
        sixtyLoopClock += 5
        
    }
}
