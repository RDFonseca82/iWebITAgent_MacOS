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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Constants.shared.LOG_FILE = Constants.shared.LOG_FILE.appendingPathComponent("log_iwebit.log")
        Constants.shared.OLD_LOG_FILE = Constants.shared.OLD_LOG_FILE.appendingPathComponent("old_log_iwebit.log")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
