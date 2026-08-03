import AppKit
import UserNotifications
import SwiftUI

class MenuBarButton {
    
    let statusItem: NSStatusItem
    let service: MenuBarButtonService
    
    init() {
        statusItem = NSStatusBar.system
            .statusItem(withLength: CGFloat(NSStatusItem.squareLength))
        statusItem.isVisible = true
        
        service = MenuBarButtonService(statusItem: statusItem)
                
        guard let button = statusItem.button else {
            return
        }
        
        button.imagePosition = NSControl.ImagePosition.imageOnly
        button.target = self
        button.action = #selector(showMenu(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    // MARK: - Show Menu
    
    @objc
    func showMenu(_ sender: AnyObject?) {
        Task {
            let menu = NSMenu()
            await MainActor.run {
                service.setIconBasedOnStatus()
            }
            if AppInfo.isLoggedIn() {
                addItem("Acerca da Aplicação iWebIT", action: #selector(showAbout), key: "", to: menu)
                addItem("Pedido de Suporte", action: #selector(showSuporte), key: "", to: menu)
                menu.addItem(NSMenuItem.separator())
                addItem("Forçar Sincronização", action: #selector(forceSync), key: "", to: menu)
            } else {
                addItem("Iniciar sessão no agente", action:  #selector(showLogin), key: "", to: menu)
            }
            var notificationEnabled = false
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                notificationEnabled = settings.authorizationStatus == .authorized
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            if !notificationEnabled {
                addItem("Permitir Notificações", action: #selector(showNotificationsPanel), key: "", imageNamed: "iwebit_normal", to: menu)
            }
            if !service.getLocationStatus() {
                addItem("Permitir Localização", action: #selector(showSettingsLocationPanel), key: "", imageNamed: "iwebit_normal", to: menu)
            }
            await MainActor.run {
                showStatusItemMenu(menu)
            }
        }
    }
    
    private func showStatusItemMenu(_ menu: NSMenu) {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    private func addItem(_ title: String, action: Selector?, key: String, imageNamed: String? = nil, to menu: NSMenu) {
        let item = NSMenuItem()
        item.title = title
        item.target = self
        item.action = action
        item.keyEquivalent = key
        if let imageNamed = imageNamed {
            item.image = NSImage(named: imageNamed)
        }
        menu.addItem(item)
    }
    
    // MARK: - Actions
    
    @objc
    func showLogin() {
        openAgent(destination: "login")
    }
    
    @objc
    func showAbout() {
        openAgent(destination: "settings")
    }

    @objc
    func showSuporte() {
        openAgent(destination: "support")
    }

    private func openAgent(destination: String) {
        let workspace = NSWorkspace.shared

        guard let deepLinkURL = URL(string: "iwebit://\(destination)") else {
            log("Invalid agent destination: \(destination)", important: true)
            return
        }

        if workspace.urlForApplication(toOpen: deepLinkURL) != nil,
           workspace.open(deepLinkURL) {
            return
        }

        let agentURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("iWebIT.app", isDirectory: true)
        guard FileManager.default.fileExists(atPath: agentURL.path) else {
            log("Agent UI not found at \(agentURL.path)", important: true)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        workspace.openApplication(at: agentURL, configuration: configuration) { _, error in
            if let error = error {
                log("Unable to open agent UI: \(error)", important: true)
                return
            }

            // Launching the bundle registers its URL schemes. Retry the deep
            // link so support/settings route to the requested scene as well.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if !workspace.open(deepLinkURL) {
                    log("Unable to open agent destination: \(destination)", important: true)
                }
            }
        }
    }

    @objc
    func showNotificationsPanel() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
        }
    }

    @objc
    func showSettingsLocationPanel() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc
    func forceSync() {
        AppInfo.forcefullsync = "1"
        let alert = NSAlert()
        alert.messageText = "Agente iWebIT"
        alert.informativeText = "O serviço irá realizar uma sincronização completa."
        alert.addButton(withTitle: "Ok")
        alert.alertStyle = .informational
        alert.runModal()
    }
}
