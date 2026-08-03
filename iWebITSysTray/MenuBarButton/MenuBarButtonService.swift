//
//  MenuBarButtonService.swift
//  iWebITSysTray
//
//  Created by Admin on 24/08/2023.
//

import SwiftUI
import Combine
import CoreLocation
import Network


class MenuBarButtonService: NSObject, CLLocationManagerDelegate {
    
    let statusItem: NSStatusItem
    var locationManager: CLLocationManager? = nil
    
    private var iconState = IconState.none
    private var forceUpdateIcon: Bool = false
    private var lastLocation: LocationPoint = LocationPoint(latitude: 0, longitude: 0)
    private var syncingLocation = false
    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "app.iwebit.agent.network-monitor")
    private let networkStateLock = NSLock()
    private var networkAvailable: Bool?
    private var lastLoopError: String?
    private var devicePollInFlight = false
    
    private var cancellables: [AnyCancellable] = []
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        super.init()

        startNetworkMonitor()
        setIconBasedOnStatus()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        }
        
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
    
    deinit {
        pathMonitor.cancel()
    }

    private func startNetworkMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let isAvailable = path.status == .satisfied
            self.networkStateLock.lock()
            let changed = self.networkAvailable != isAvailable
            self.networkAvailable = isAvailable
            self.networkStateLock.unlock()

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if changed {
                    log("NETWORK PATH: \(isAvailable ? "available" : "unavailable")", important: true)
                }
                if isAvailable {
                    self.the15sstep()
                } else {
                    AppInfo.net = "0"
                }
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }

    private func currentNetworkAvailability() -> Bool? {
        networkStateLock.lock()
        defer { networkStateLock.unlock() }
        return networkAvailable
    }

    private func logLoopState(_ message: String) {
        guard lastLoopError != message else { return }
        lastLoopError = message
        log(message, important: true)
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
            iconState = .down
            forceUpdateIcon = false
            
        } else if hasNet && serviceRunnin && (iconState != .up || forceUpdateIcon) {
            button.image = filesManager.loadImage(filename: "logo-on.jpg") ?? NSImage(named: "iwebit_up")
            iconState = .up
            forceUpdateIcon = false
        }
    }
    
    func checkForNewIcon() {
        guard let currentImage = statusItem.button?.image, !forceUpdateIcon else { return }
        
        let newImage = FilesManager.shared.loadImage(filename: iconState == .up ? "logo-on.jpg" : "logo-off.jpg")
        
        if !currentImage.isEqual(to: newImage) {
            forceUpdateIcon = true
        }
    }
    
    func the15sstep() {
        if !AppInfo.isLoggedIn() { return }
        guard AppInfo.uniqueid.isNotBlank(), AppInfo.uniqueid != "?" else {
            AppInfo.net = "0"
            logLoopState("DEVICE POLL PAUSED: registration has no UniqueID")
            return
        }
        guard let networkAvailable = currentNetworkAvailability() else { return }
        guard networkAvailable else {
            AppInfo.net = "0"
            logLoopState("DEVICE POLL PAUSED: no network path")
            return
        }
        guard !devicePollInFlight else { return }
        devicePollInFlight = true
        Task {
            defer { devicePollInFlight = false }
            do {
                let deviceInfo = try await GetDeviceDataService.shared.getDevice()
                lastLoopError = nil
                
                if let notificationMsg = deviceInfo.androidMessageTxt, notificationMsg.isNotBlank() {
                    notify(title: "Nova mensagem", subtitle: notificationMsg)
                }
                if deviceInfo.deviceLocation == 1 && Constants.allowLegacyPrivacyCommands {
                    locationManager?.requestLocation()
                }
                
                if deviceInfo.windowsPrintScreen == 1 && Constants.allowLegacyPrivacyCommands {
                    try await screenshotAndSend()
                }
                
            } catch {
                logLoopState("DEVICE POLL FAILED: \(error)")
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
            
            log("NEW LOCATION: \(coordinates.latitude) \(coordinates.longitude)", important: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !syncingLocation {
            log("FAILED TO GET LOCATION: \(error)", important: true)
        }
    }
    
    func getLocationStatus() -> Bool {
        return CLLocationManager.locationServicesEnabled()
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
