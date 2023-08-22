//
//  iWebITAgentApp.swift
//  iWebITAgent
//
//  Created by Admin on 10/08/2023.
//

import SwiftUI

@main
struct iWebITAgent: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("Ocorrências") {
            HomeWindow()
                .defaultWindowSize()
                .handlesExternalEvents(preferring: ["support"], allowing: ["support"])
        }
        .handlesExternalEvents(matching: ["support"])
        .windowStyle(HiddenTitleBarWindowStyle())
        
        WindowGroup("Login") {
            LoginWindow()
                .frame(width: 650, height: 300)
                .handlesExternalEvents(preferring: ["login"], allowing: ["login"])
        }
        .handlesExternalEvents(matching: ["login"])
        .windowStyle(HiddenTitleBarWindowStyle())
        .iwebitCommands()
        
        WindowGroup {
            SupportDetailWindow()
                .defaultWindowSize()
                .handlesExternalEvents(preferring: ["detail"], allowing: ["detail"])
        }
        .handlesExternalEvents(matching: ["detail"])
        .windowStyle(HiddenTitleBarWindowStyle())
        
        WindowGroup("Definições") {
            SettingsWindow()
                .defaultWindowSize()
                .handlesExternalEvents(preferring: ["settings"], allowing: ["settings"])
        }
        .handlesExternalEvents(matching: ["settings"])
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
