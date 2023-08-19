//
//  iWebITCommands.swift
//  iWebITAgent
//
//  Created by Admin on 16/08/2023.
//

import SwiftUI

extension Scene {
    func iwebitCommands() -> some Scene {
        return self
            .commands {
                CommandGroup(replacing: .pasteboard) { }
                CommandGroup(replacing: .undoRedo) { }
                CommandGroup(replacing: .newItem) { }
                CommandGroup(replacing: .help) { }
            }
    }
}
