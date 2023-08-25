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
        print("HEY")
        TakeScreensShots(folderName: "~/Desktop/")
    }
}
