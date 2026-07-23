//
//  SecondaryLoop.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func secondaryLoop() {
    log("====> 2nd  LOOP <====")
    
    log("** Checking For FULLSYNC Request **")
    
    if AppInfo.forcefullsync == "1" || AppInfo.fullsync == "1" {
        prepareAndSendSync("1")
        AppInfo.forcefullsync = "0"
        AppInfo.fullsync = "0"
        
        updateTimers("timesync")
        updateTimers("timealive")
    }
    
    log("** Checking For MANUAL UPDATE **")

    if AppInfo.manualupdate == "1" {
        AppInfo.manualupdate = "0"
        updateToNewVersion(manual: true)
    }
    
    if !Constants.allowLegacyDestructiveCommands &&
       (AppInfo.reboot == "1" || AppInfo.shutdown == "1") {
        log("BLOCKED legacy reboot/shutdown request", important: true)
        resetRebootAndShutdownFlags()
    }

    log("** Checking For REBOOT **")
    
    if AppInfo.reboot == "1" && Constants.allowLegacyDestructiveCommands {
        log("!!! RESTARTING IN 1 MINUTE !!!")
        alert(title: "Reinício pendente", text: "O sistema irá reiniciar em 1 minuto.")
        Thread.sleep(forTimeInterval: TimeInterval(60))
        shell("sudo shutdown -r now")
    }
    
    log("** Checking For SHUTDOWN **")
    
    if AppInfo.shutdown == "1" && Constants.allowLegacyDestructiveCommands {
        log("!!! SHUTTING DOWN IN 1 MINUTE !!!")
        alert(title: "Encerramento pendente", text: "O sistema irá encerrar em 1 minuto.")
        Thread.sleep(forTimeInterval: TimeInterval(60))
        shell("sudo shutdown -h now")
    }
    
    log("====>    END    <====")
    
}
