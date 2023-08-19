//
//  WindowAccessor.swift
//  iWebITAgent
//
//  Created by Admin on 17/08/2023.
//

import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    var windowTitle: String? = nil
    var shouldCenter: Bool = false
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
            if let title = windowTitle {
                self.window?.title = title
            }
            if shouldCenter {
                self.window?.setPosition(vertical: .center, horizontal: .center)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
