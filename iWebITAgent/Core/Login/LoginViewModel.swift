//
//  LoginViewModel.swift
//  iWebITAgent
//
//  Created by Admin on 17/08/2023.
//

import SwiftUI

class LoginViewModel: ObservableObject {
    
    @Published var idSync: String = ""
    
    func login() {
//        print(shell("launchctl load /Library/LaunchAgents/com.rdfonseca.iWebITAgent.plist"))
        AppInfo.idsync = idSync
        print(AppInfo.idsync)
    }
    
//    func login5() {
//        let myAppleScript = """
//        do shell script \"sudo touch /Library/hello" with administrator privileges
//        """
//        var error: NSDictionary?
//        let scriptObject = NSAppleScript(source: myAppleScript)!
//        scriptObject.executeAndReturnError(&error)
//    }
}
