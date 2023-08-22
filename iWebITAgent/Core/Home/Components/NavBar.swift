//
//  NavBar.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import SwiftUI

struct NavBar: View {
    @Environment(\.openURL) var openURL
    
    @Binding var showingOcorrencias: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image("iwebit")
                .resizable()
                .scaledToFit()
                .height(60)
            
            NavBarItem(
                imageName: "clipboard",
                tooltipText: "Ocorrências",
                selected: showingOcorrencias
            )
            .onTapGesture { withAnimation { showingOcorrencias = true } }
            NavBarItem(
                imageName: "support",
                tooltipText: "Suporte",
                selected: !showingOcorrencias
            )
            .onTapGesture { withAnimation { showingOcorrencias = false } }
            NavBarItem(
                imageName: "globe",
                tooltipText: "Site iWebIT",
                selected: false
            )
            .onTapGesture { openURL(Constants.iwebitSiteUrl) }
            
            Spacer()
            
            NavBarItem(
                imageName: "settings",
                tooltipText: "Definições",
                selected: false
            )
            .onTapGesture { openDeepLink(destination: "settings") }
        }
        .width(90)
        .fillMaxHeight()
        .padding(.top, 40)
        .padding(.bottom, 10)
        .background(Color.theme.background.shadow(color: .theme.onBackground.opacity(0.15), radius: 7))
    }
}

struct NavBarItem: View {
    let imageName: String
    let tooltipText: String
    let selected: Bool
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .height(30)
        }
        .size(65)
        .background((selected ? Color.theme.accent : (isHovering ? Color.gray.opacity(0.1) : Color.clear)).cornerRadius(8))
        .onHover { hovering in
            withAnimation {
                self.isHovering = hovering
            }
        }
        .help(tooltipText)
    }
}
