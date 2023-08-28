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
            .sink { [weak self] _ in self?.checkforSct(); self?.checkforSct()}
            .store(in: &cancellables)
        
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkForNewIcon()}
            .store(in: &cancellables)
        
    }
    
    func setIconBasedOnStatus() {
        guard let button = statusItem.button else { return }
        let hasNet = AppInfo.net == "1"
        let serviceRunnin = isServiceRunning()
        let filesManager = FilesManager.shared
        
        if !AppInfo.isLoggedIn() {
            if iconState != .inactive {
                button.image = NSImage(named: "iwebit_inactive")
                iconState = .inactive
            }
            forceUpdateIcon = false
            return
        }
        
        if (!hasNet || !serviceRunnin) && (iconState != .down || forceUpdateIcon) {
            button.image = filesManager.loadImage(filename: "logo-off.jpg") ?? NSImage(named: "iwebit_down")
            forceUpdateIcon = false
            
        } else if hasNet && serviceRunnin && (iconState != .up || forceUpdateIcon) {
            button.image = filesManager.loadImage(filename: "logo-on.jpg") ?? NSImage(named: "iwebit_up")
            forceUpdateIcon = false
        }
    }
    
    func checkForNewIcon() {
        guard let currentImage = statusItem.button?.image, iconState == .inactive && !forceUpdateIcon else { return }
        
        let newImage = FilesManager.shared.loadImage(filename: iconState == .up ? "logo-on.jpg" : "logo-off.jpg")
        
        if currentImage.isEqual(to: newImage) {
            forceUpdateIcon = true
        }
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
