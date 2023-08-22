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
    func width(_ width: CGFloat) -> some View {
        return self.frame(width: width)
    }
    func height(_ height: CGFloat) -> some View {
        return self.frame(height: height)
    }
    func size(_ width: CGFloat, _ height: CGFloat) -> some View {
        return self.frame(width: width, height: height)
    }
    func size(_ size: CGFloat) -> some View {
        return self.frame(width: size, height: size)
    }
    func align(_ alignment: Alignment) -> some View {
        return self.frame(alignment: alignment)
    }
}
