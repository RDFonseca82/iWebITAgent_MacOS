import AppKit
import SwiftUI

class MenuBarButton {
    
    let statusItem: NSStatusItem
    
    init() {
        statusItem = NSStatusBar.system
            .statusItem(withLength: CGFloat(NSStatusItem.squareLength))
                
        guard let button = statusItem.button else {
            return
        }
        
        button.image = NSImage(named: "iwebit_inactive")
        button.imagePosition = NSControl.ImagePosition.imageOnly
        button.target = self
        button.action = #selector(showMenu(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    // MARK: - Show Menu
    
    @objc
    func showMenu(_ sender: AnyObject?) {
        let menu = NSMenu()
        addItem("Acerca da Aplicação iWebIT", action: #selector(showLogin), key: "", to: menu)
        addItem("Apoio Técnico Remoto", action: #selector(showHome), key: "", to: menu)
        addItem("Pedido de Suporte", action: #selector(showDetail), key: "", to: menu)
        menu.addItem(NSMenuItem.separator())
        addItem("Forçar Sincronização", action: #selector(showSettings), key: "", to: menu)
        showStatusItemMenu(menu)
    }
    
    private func showStatusItemMenu(_ menu: NSMenu) {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    private func addItem(_ title: String, action: Selector?, key: String, to menu: NSMenu) {
        let item = NSMenuItem()
        item.title = title
        item.target = self
        item.action = action
        item.keyEquivalent = key
        menu.addItem(item)
    }
    
    // MARK: - Actions
    
    @objc
    func showLogin() {
        let workspace = NSWorkspace.shared
        
        if let deepLinkUrl = URL(string: "iwebit://login") {
            workspace.open(deepLinkUrl)
        }
    }

    @objc
    func showHome() {
        let workspace = NSWorkspace.shared
        
        if let deepLinkUrl = URL(string: "iwebit://support") {
            workspace.open(deepLinkUrl)
        }
    }

    @objc
    func showDetail() {
        let workspace = NSWorkspace.shared
        
        if let deepLinkUrl = URL(string: "iwebit://detail") {
            workspace.open(deepLinkUrl)
        }
    }

    @objc
    func showSettings() {
        let workspace = NSWorkspace.shared
        
        if let deepLinkUrl = URL(string: "iwebit://settings") {
            workspace.open(deepLinkUrl)
        }
    }
}
