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
            
            AppInfo.idsync = idSync
            // Initial inventory and synchronization continue in the daemon.
            // Slow background work must not keep the user trapped in this window.
            
            await MainActor.run {
                state = LoginState(error: .none, isLoading: false)
                
                openDeepLink(destination: "support")
                loginWindow.close()
            }
        } catch {
            log("ERROR LOGIN VIEWMODEL: \(error)", important: true)
            await MainActor.run {
                state = LoginState(error: error as? iWebITError ?? iWebITError.generalError, isLoading: false)
            }
        }
    }
}
