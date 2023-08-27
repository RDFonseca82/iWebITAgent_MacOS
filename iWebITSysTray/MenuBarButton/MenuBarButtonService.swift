//
//  MenuBarButtonService.swift
//  iWebITSysTray
//
//  Created by Admin on 24/08/2023.
//

import SwiftUI
import Combine


class MenuBarButtonService {
    
    let statusItem: NSStatusItem
    
    private var iconState = IconState.inactive
    private var forceUpdateIcon: Bool = false
    
    private var cancellables: [AnyCancellable] = []
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        
        setIconBasedOnStatus()
        
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.setIconBasedOnStatus()}
            .store(in: &cancellables)
        
        Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkforSct()}
            .store(in: &cancellables)
        
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkForNewIcon()}
            .store(in: &cancellables)
        
    }
    
    func setIconBasedOnStatus() {
        let hasNet = AppInfo.net == "1"
        let serviceRunnin = isServiceRunning()
        
        if !AppInfo.isLoggedIn() && iconState != .inactive {
            return
        }
        
        
        if (!hasNet || !serviceRunnin) && (iconState != .down || forceUpdateIcon) {
            
        } else if hasNet && serviceRunnin && (iconState != .up || forceUpdateIcon) {
            
        }
    }
    
    func checkForNewIcon() {
        
    }
    
    func checkforSct() {
        Task {
            do {
                let deviceInfo = try await GetDevicetDataService.shared.getDevice()
                if deviceInfo.windowsPrintScreen == 1 {
                    if let screenshot = takeScreenShot() {
                        try await SendScreenshotDataService.shared.sendScreenshot(screenshot: screenshot)
                    }
                }
            } catch {
                print("ERROR SENDING SCREENSHOT: \(error)")
            }
        }
    }
    
    enum IconState {
        case up, down, inactive
    }
}
