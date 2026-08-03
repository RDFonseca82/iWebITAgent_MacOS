//
//  OpenWindow.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import SwiftUI


func openDeepLink(appProtocol: String = "iwebit", destination: String) {
    let workspace = NSWorkspace.shared

    guard let deepLinkURL = URL(string: "\(appProtocol)://\(destination)") else { return }
    guard appProtocol == "iwebit" else {
        workspace.open(deepLinkURL)
        return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    workspace.open(
        [deepLinkURL],
        withApplicationAt: Bundle.main.bundleURL,
        configuration: configuration
    ) { _, error in
        if let error = error {
            log("Unable to open internal destination \(destination): \(error)", important: true)
        }
    }
}
