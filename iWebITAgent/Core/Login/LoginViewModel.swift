//
//  LoginViewModel.swift
//  iWebITAgent
//
//  Created by Admin on 17/08/2023.
//

import SwiftUI

class LoginViewModel: ObservableObject {
    
    @Published var idSync: String = ""
    
    @Published var state = LoginState()
    
    func login(loginWindow: NSWindow) async {
        await MainActor.run {
            state = LoginState(error: .none, isLoading: true)
        }
        do {
            let companyExists = try await CheckCompanyDataService.shared.checkCompany(idSync: idSync)
            
            if !companyExists {
                throw iWebITError.invalidCredentials
            }
            
            var count = 0
            
            AppInfo.idsync = idSync
            
            while AppInfo.allprepared != "1" {
                if count >= 120 {
                    AppInfo.idsync = ""
                    throw iWebITError.incompleteOperation
                }
                
                try? await Task.sleep(seconds: 5)
                count += 5
            }
            
            await MainActor.run {
                state = LoginState(error: .none, isLoading: false)
                
                let workspace = NSWorkspace.shared
                
                if let deepLinkUrl = URL(string: "iwebit://support") {
                    workspace.open(deepLinkUrl)
                }
                loginWindow.close()
            }
        } catch {
            print("ERROR HOME VIEWMODEL: \(error)")
            await MainActor.run {
                state = LoginState(error: error as? iWebITError ?? iWebITError.generalError, isLoading: false)
            }
        }
    }
    
//        print(shell("launchctl load /Library/LaunchAgents/com.rdfonseca.iWebITAgent.plist"))
//    func login5() {
//        let myAppleScript = """
//        do shell script \"sudo touch /Library/hello" with administrator privileges
//        """
//        var error: NSDictionary?
//        let scriptObject = NSAppleScript(source: myAppleScript)!
//        scriptObject.executeAndReturnError(&error)
//    }
}
