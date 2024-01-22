//
//  UninstallApps.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func checkAppsToUninstall() {
    let dInfo = getDeviceSyncInfo(["SPApplicationsDataType"])
    let installedApps = getAppsWithPath(dInfo["SPApplicationsDataType"] as? AnyList)
    let fileManager = FileManager.default
    
    doUntil({
        log("CHECKING APPS TO UNINSTALL")
        
        ensureUserLoggedIn()
        
        let appsToUninstall = try GetAppsToUninstallDataService.shared.getAppsToUninstall()
        
        if appsToUninstall.isEmpty {
            log("NO APPS TO UNINSTALL")
            return false
        }
        
        var uninstalledAppsPaths: [String] = []
        
        for app in appsToUninstall {
            guard let appName = app.appName
            else {
                log("APP NAME IS NULL")
                log("NO PATH FOUND FOR \(app.appName ?? "NULL")")
                continue
            }
            
            let appMatches = installedApps.filter({ $0.name == appName })

            guard !appMatches.isEmpty else {
                log("NO MATCHING APP FOUND FOR \(appName)")
                continue
            }
            
            let paths = appMatches.map { $0.path }
            
            for path in paths {
                if fileManager.fileExists(atPath: path) {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        log("COULDN'T REMOVE APP: \(appName)")
                    }
                } else {
                    log("APP NOT FOUND: \(appName)")
                    continue
                }
                uninstalledAppsPaths.append(path)
            }
        }
        
        if !uninstalledAppsPaths.isEmpty {
            prepareAndSendSync("1")
            updateTimers("timesync")
            updateTimers("timealive")
        }
        
        log("APPS UNINSTALLED (\(uninstalledAppsPaths.count)): \(uninstalledAppsPaths.joined(separator: ", "))")
        
        return false
    }, 60)
}

func getAppsWithPath(_ spApplicationsDataType: AnyList?) -> [AppObj] {
    guard
        let spApplicationsDataType = spApplicationsDataType,
        spApplicationsDataType.count > 0,
        let info = spApplicationsDataType as? [AnyDict]
    else { return [] }
    
    return info.map { app in
        let name = app["_name"] as? String ?? "None"
        let path = app["path"] as? String ?? "None"
        return AppObj(name: name, path: path)
    }
}

struct AppObj {
    let name: String
    let path: String
}
