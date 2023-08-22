//
//  OpenWindow.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import SwiftUI


func openDeepLink(appProtocol: String = "iwebit", destination: String) {
    let workspace = NSWorkspace.shared
    
    if let deepLinkUrl = URL(string: "\(appProtocol)://\(destination)") {
        workspace.open(deepLinkUrl)
    }
}
