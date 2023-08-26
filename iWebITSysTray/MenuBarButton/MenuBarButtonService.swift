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
    
    private var cancellables: [AnyCancellable] = []
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        
        checkforSct()
        
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.setIconBasedOnStatus()}
            .store(in: &cancellables)
        
        Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkforSct()}
            .store(in: &cancellables)
        
    }
    
    func setIconBasedOnStatus() {
        
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
}
