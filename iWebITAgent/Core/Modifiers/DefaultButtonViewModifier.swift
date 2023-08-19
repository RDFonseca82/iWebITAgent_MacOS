//
//  DefaultButtonViewModifier.swift
//  iWebITAgent
//
//  Created by Admin on 17/08/2023.
//

import SwiftUI

struct DefaultButtonViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .frame(height: 40)
            .padding(.horizontal)
            .background(Color.theme.accent)
            .cornerRadius(8)
            .cursor(.pointingHand)
    }
}

extension View {
    func defaultButtonView() -> some View {
        modifier(DefaultButtonViewModifier())
    }
}
