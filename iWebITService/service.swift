//
//  service.swift
//  iWebITService
//
//  Created by Admin on 26/08/2023.
//

import SwiftUI

@main
struct Service {
    static func main() throws {
        Constants.shared.LOG_FILE = Constants.shared.LOG_FILE.appendingPathComponent("log_service.log")
        Constants.shared.OLD_LOG_FILE = Constants.shared.OLD_LOG_FILE.appendingPathComponent("old_log_service.log")
        
        //getServices()
        
        print(shell("launchctl list application.com.microsoft.VSCode.12899099958.12899099964"))
        
        //mainLoop()
    }
}

