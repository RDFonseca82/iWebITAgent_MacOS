//
//  DefaultWindowSizeModifier.swift
//  iWebITAgent
//
//  Created by Admin on 16/08/2023.
//

import SwiftUI

struct DefaultWindowSizeModifier: ViewModifier {
    let minWidth: CGFloat
    let minHeight: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: minWidth, maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity)
    }
}


extension View {
    func defaultWindowSize(minWidth: CGFloat = 500, minHeight: CGFloat = 500) -> some View {
        modifier(DefaultWindowSizeModifier(minWidth: minWidth, minHeight: minHeight))
    }
}
