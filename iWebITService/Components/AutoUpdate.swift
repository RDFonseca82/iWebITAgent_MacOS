//
//  AutoUpdate.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation
import AppKit


func updateToNewVersion(manual: Bool) {
    log("UPDATING TO NEW VERSION...")
    
    guard let appSupportFolder = FilesManager.shared.getApplicationSupportDirectory() else {
        log("APP SUPPORT DIR IS NULL", important: true)
        return
    }
    
    let installerPath = appSupportFolder.appendingPathComponent("iWebITInstaller.pkg").path
    let installerLogPath = appSupportFolder.appendingPathComponent("install_log.log").path
    let updateSignalPath = appSupportFolder.appendingPathComponent("UPDATE").path
    var installerFound = false
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: installerPath) && !manual {
        try? fileManager.removeItem(atPath: installerPath)
    }
    
    if fileManager.fileExists(atPath: updateSignalPath) {
        try? fileManager.removeItem(atPath: updateSignalPath)
    }
    
    if !manual {
        doUntil({
            log("GETTING INSTALLER URL")
            
            ensureUserLoggedIn()
            
            let companyInfo = try GetCompanyDataService.shared.getCompany()
            
            let installerUrl = companyInfo.appleAgentDownload
            
            guard let installerUrl = installerUrl, !installerUrl.isEmpty else {
                log("INSTALLER URL IS EMPTY", important: true)
                return false
            }
            
            log("DOWNLOADING INSTALLER...")
            
            var installer: Data? = nil
            
            do {
                installer = try NetworkingManager.download(url: installerUrl)
                
                guard installer != nil else {
                    log("NO INSTALLER FOUND")
                    return false
                }
            } catch {
                if AppInfo.net == "1" {
                    log("NO INSTALLER FOUNd")
                    
                    return false
                }
                return true
            }
            
            fileManager.createFile(atPath: installerPath, contents: installer)
            
            log("DONE")
            
            installerFound = true
            
            return false
        }, 60)
    }
    
    if !installerFound && !manual {
        log("COULD NOT INSTALL NEW VERSION")
        return
    }
    
    log("====> INSTALLING <====")
    
    let workspace = NSWorkspace.shared
    let apps = workspace.runningApplications.filter { (app) -> Bool in
        return app.activationPolicy == .regular
    }.map { $0.bundleIdentifier ?? "" }
    
    if !apps.contains(Constants.BUNDLE_ID) {
        fileManager.createFile(atPath: updateSignalPath, contents: nil)
    }
    
    let output = shell("sudo installer -pkg \"\(installerPath)\" -target / -verboseR").data(using: .utf8)
    
    fileManager.createFile(atPath: installerLogPath, contents: output)
}
