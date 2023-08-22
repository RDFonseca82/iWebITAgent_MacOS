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
        // TODO
        AppInfo.uniqueid = "bb01123842c6187babfe654137e712c02fba689741ba8fd4e78b5f1d8e94e8fe"
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        print("HEYYE")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
