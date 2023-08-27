//
//  ServiceStatus.swift
//  iWebITSysTray
//
//  Created by Admin on 26/08/2023.
//

import SwiftUI


func isServiceRunning() -> Bool {
    let workspace = NSWorkspace.shared
    let apps = workspace.runningApplications
    let serviceApps = apps.filter { app in
        return app.bundleIdentifier == "com.rdfonseca.iWebITService"
    }
    
    return !serviceApps.isEmpty
}
