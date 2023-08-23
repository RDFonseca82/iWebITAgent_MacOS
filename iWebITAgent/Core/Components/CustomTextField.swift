//
//  TextField.swift
//  MODA
//
//  Created by Admin on 06/03/2023.
//

import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    @State var isFocused: Bool = false
    
    var body: some View {
        TextField(placeholder, text: $text, onEditingChanged: { isEditing in
            isFocused = isEditing
        }, onCommit: {
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        })
        .lineLimit(1)
        .font(.title3)
        .textFieldStyle(.plain)
        .foregroundColor(.theme.onBackground)
        .padding(10)
        .background(
            Color.theme.darkGray
                .cornerRadius(8)
                .brightness(isFocused ? 0.04 : 0)
                .shadow(
                    color: Color.theme.onBackground.opacity(0.15),
                    radius: 4
                )
        )
    }
}
