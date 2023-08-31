//
//  MenuBarButtonService.swift
//  iWebITSysTray
//
//  Created by Admin on 24/08/2023.
//

import SwiftUI
import Combine
import CoreLocation


class MenuBarButtonService: NSObject, CLLocationManagerDelegate {
    
    let statusItem: NSStatusItem
    var locationManager: CLLocationManager? = nil
    
    private var iconState = IconState.none
    private var forceUpdateIcon: Bool = false
    private var lastLocation: LocationPoint = LocationPoint(latitude: 0, longitude: 0)
    private var syncingLocation = false
    
    private var cancellables: [AnyCancellable] = []
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        super.init()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        }
        
//        let hasScreenAccess = CGPreflightScreenCaptureAccess();
//        if !hasScreenAccess {
//            CGRequestScreenCaptureAccess()
//        }
        
        setIconBasedOnStatus()
        
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.setIconBasedOnStatus()}
            .store(in: &cancellables)
        
        Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.the15sstep()}
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
        
        print("\(AppInfo.isLoggedIn()) \(hasNet) \(serviceRunnin)")
        
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
    
    func the15sstep() {
        Task {
            do {
                let deviceInfo = try await GetDevicetDataService.shared.getDevice()
                
                if let notificationMsg = deviceInfo.androidMessageTxt, notificationMsg.isNotBlank() {
                    notify(title: "Nova mensagem", subtitle: notificationMsg)
                }
                if deviceInfo.deviceLocation == 1 {
                    locationManager?.requestLocation()
                }
                
                if deviceInfo.windowsPrintScreen == 1 {
                    try await screenshotAndSend()
                }
                
            } catch {
                print("ERROR SENDING 15s step: \(error)")
            }
        }
    }
    
    func screenshotAndSend() async throws {
        if let screenshot = takeScreenShot() {
            try await SendScreenshotDataService.shared.sendScreenshot(screenshot: screenshot)
        }
    }
    
    func sendLocation(newLocation: LocationPoint) {
        Task {
            do {
                try await SyncLocationDataService.shared.syncLocation(coordinate: newLocation)
                
                lastLocation = newLocation
            } catch {
                
            }
            await MainActor.run {
                syncingLocation = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinates = locations.last!.coordinate
        let newLocation = LocationPoint(latitude: coordinates.latitude, longitude: coordinates.longitude)
        if newLocation != lastLocation && !syncingLocation {
            syncingLocation = true
            sendLocation(newLocation: newLocation)
            
            print("NEW LOCATION: \(coordinates.latitude) \(coordinates.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !syncingLocation {
            print("FAILED: \(error)")
        }
    }
    
    enum IconState {
        case up, down, inactive, none
    }
}

struct LocationPoint {
    let latitude: Double
    let longitude: Double
    
    static func ==(lhs: LocationPoint, rhs: LocationPoint) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    static func !=(lhs: LocationPoint, rhs: LocationPoint) -> Bool {
        !(lhs == rhs)
    }
}
