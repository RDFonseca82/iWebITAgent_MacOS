//
//  MainLoop.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func mainLoop() {
    log("==> STARTING MAIN LOOP <==")
    
    waitForLogIn()
    
    resetRebootAndShutdownFlags()
    
    log("SYNCING VERSION (new/old): \(Constants.AGENT_VERSION) \(AppInfo.agentversion)")
    AppInfoManager.shared.syncAgentVersion()
    
    updateCompanyInfo(onInit: true)
    
    synchronizeFiles()
    
    if AppInfo.firstrun == "1" {
        AppInfo.firstrun = "0"
    }
    
    prepareAndSendSync("1")
    updateDeviceInfo()
    updateTimers("timesync")
    updateTimers("timealive")
    updateCompanyInfo(onInit: false)
//    checkAppsToUninstall()
    
    if AppInfo.allprepared != "1" {
        AppInfo.allprepared = "1"
    }
    
    var sixtyLoopClock = 0
    
    while true {
        
        if Date().timeIntervalSince(AppInfo.nexttimesync.toDate()) > 0 {
            log("INSIDE FULL SYNC")
            prepareAndSendSync("1")
            
            updateTimers("timesync")
            updateTimers("timealive")
        }
        
        if Date().timeIntervalSince(AppInfo.nexttimealive.toDate()) > 0 {
            log("INSIDE MIN SYNC")
            prepareAndSendSync("2")
            
            updateTimers("timealive")
            
            updateDeviceInfo()
            updateCompanyInfo(onInit: false)
//            checkAppsToUninstall()
        }
        
        if sixtyLoopClock == 60 {
            sixtyLoopClock = 0
            
            secondaryLoop()
        }
        
        log("IM ALIVE", printOnly: true)
        Thread.sleep(forTimeInterval: TimeInterval(5))
        
        sixtyLoopClock += 5
        
    }
}
