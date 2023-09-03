//
//  SecondaryLoop.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func secondaryLoop() async {
    log("====> 2nd  LOOP <====")
    
    log("** Checking For FULLSYNC Request **")
    
    if AppInfo.forcefullsync == "1" || AppInfo.fullsync == "1" {
//        await prepareAndSendSync("1")
        AppInfo.forcefullsync = "0"
        AppInfo.fullsync = "0"
        
        updateTimers("timesync")
        updateTimers("timealive")
    }
    
//    log("** Checking For MANUAL UPDATE **")
//
//    if AppInfo.manualupdate == "1" {
//        AppInfo.manualupdate = "0"
//        updateToNewVersion(true)
//    }
    
    log("** Checking For REBOOT **")
    
    if AppInfo.reboot == "1" {
        log("!!! RESTARTING IN 1 MINUTE !!!")
        alert(title: "Reinício pendente", text: "O sistema irá reiniciar em 1 minuto.")
        try? await Task.sleep(seconds: 60)
        shell("sudo shutdown -r now")
    }
    
    log("** Checking For SHUTDOWN **")
    
    if AppInfo.shutdown == "1" {
        log("!!! SHUTTING DOWN IN 1 MINUTE !!!")
        alert(title: "Encerramento pendente", text: "O sistema irá encerrar em 1 minuto.")
        try? await Task.sleep(seconds: 60)
        shell("sudo shutdown -h now")
    }
    
    log("====>    END    <====")
    
}
