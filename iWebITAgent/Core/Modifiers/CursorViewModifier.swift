//
//  CursorViewModifier.swift
//  iWebITAgent
//
//  Created by Admin on 18/08/2023.
//

import SwiftUI

struct CursorViewModifier: ViewModifier {
    let cursor: NSCursor
    let withEffect: Bool
    @State var isHovering: Bool = false
    
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            return content
                .onContinuousHover { phase in
                    switch phase {
                    case .active(_):
                        self.isHovering = true
                    case .ended:
                        self.isHovering = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        if self.isHovering {
                            cursor.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .brightness(withEffect && isHovering ? 0.1 : 0)
        } else {
            return content
                .onHover { hovering in
                    self.isHovering = hovering
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        if self.isHovering {
                            cursor.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .brightness(withEffect && isHovering ? 0.1 : 0)
        }
    }
}

extension View {
    func cursor(_ cursor: NSCursor, withEffect: Bool = true) -> some View {
        modifier(CursorViewModifier(cursor: cursor, withEffect: withEffect))
    }
}
