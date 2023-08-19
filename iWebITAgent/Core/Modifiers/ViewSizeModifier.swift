//
//  ViewSizeModifier.swift
//  iWebITAgent
//
//  Created by Admin on 17/08/2023.
//

import SwiftUI


extension View {
    func fillMaxHeight() -> some View {
        return self.frame(maxHeight: .infinity)
    }
    func fillMaxWidth() -> some View {
        return self.frame(maxWidth: .infinity)
    }
    func fillMaxSize() -> some View {
        return self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
