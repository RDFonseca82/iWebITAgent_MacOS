//
//  HoverEffectViewModifier.swift
//  iWebITAgent
//
//  Created by Admin on 18/08/2023.
//

import SwiftUI

struct HoverEffectViewModifier: ViewModifier {
    
    @State var isHovering = false
    
    func body(content: Content) -> some View {
        return content
            .onHover { hovering in
                withAnimation {
                    self.isHovering = hovering
                }
            }
            .brightness(isHovering ? 0.1 : 0)
    }
}

extension View {
    func hoverEffect() -> some View {
        modifier(HoverEffectViewModifier())
    }
}
