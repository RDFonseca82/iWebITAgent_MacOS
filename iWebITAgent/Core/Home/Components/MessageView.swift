//
//  MessageView.swift
//  iWebITAgent
//
//  Created by Admin on 22/08/2023.
//

import SwiftUI

struct MessageView: View {
    var body: some View {
        VStack {
            HStack {
                Text("MESSAGEGEGEGEGGEGE message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message")
                    .lineLimit(1)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.lightBlue)
                
                Text("há 50 segundos")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                    .offset(y: -10)
            }
            .padding(.bottom, 2)
            
            Text("message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message message")
                .lineLimit(1)
                .font(.system(size: 15))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fillMaxWidth()
        .padding(12)
        .background(Color.theme.surface.cornerRadius(10))
        .padding(.bottom,12)
        .hoverEffect()
    }
}
