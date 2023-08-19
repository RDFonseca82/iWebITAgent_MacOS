//
//
//  AppDelegate.swift
//  MODA
//
//  Created by Admin on 13/04/2023.
//

import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        print("HEYYE")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
