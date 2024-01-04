//
//  AutoUpdate.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func updateToNewVersion(manual: Bool) {
    log("UPDATING TO NEW VERSION...")
    
    guard let appSupportFolder = FilesManager.shared.getApplicationSupportDirectory() else {
        log("APP SUPPORT DIR IS NULL", important: true)
        return
    }
    
    let installerPath = appSupportFolder.appendingPathComponent("iWebITInstaller.pkg").path
    let installerLogPath = appSupportFolder.appendingPathComponent("install_log.log").path
    var installerFound = false
    
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
            
            FileManager.default.createFile(atPath: installerPath, contents: installer)
            
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
    
    let output = shell("sudo installer -pkg \"\(installerPath)\" -target / -verboseR").data(using: .utf8)
    
    FileManager.default.createFile(atPath: installerLogPath, contents: output)
}
