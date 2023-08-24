//
//  SettingsWindow.swift
//  iWebITAgent
//
//  Created by Admin on 16/08/2023.
//

import SwiftUI

struct SettingsWindow: View {
    @Environment(\.openURL) var openUrl
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Detalhes")
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(.theme.onBackground)
                .padding([.leading, .top], 10)
            
            header(text: "Definições da Empresa")
            
            infoRow(key: "ID do Dispositivo", value: AppInfo.uniqueid)
            infoRow(key: "ID da Sincronização", value: AppInfo.idsync)
            infoRow(key: "Nome da Empresa", value: AppInfo.companyname)
            infoRow(key: "Versão do Agente", value: AppInfo.agentversion)
            
            header(text: "Política de Privacidade")
                .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
                .onHover { hovering in
                    withAnimation {
                        self.isHovering = hovering
                    }
                }
                .onTapGesture {
                    openUrl(Constants.privacyPolicyUrl)
                }
            
            Spacer()
        }
        .fillMaxSize()
    }
}

extension SettingsWindow {
    func infoRow(key: String, value: String) -> some View {
        HStack(alignment: .center) {
            Text(key)
                .font(.system(size: 16))
            Spacer()
            GeometryReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .center) {
                        Spacer()
                        Text(value)
                            .font(.system(size: 14))
                    }
                    .frame(minWidth: proxy.size.width, minHeight: 40)
                }
                .frame(maxHeight: 40)
            }
            .frame(maxHeight: 40)
        }
        .height(40)
        .padding(.horizontal)
    }
    
    func header(text: String) -> some View {
        VStack {
            Divider()
            HStack {
                Text(text)
                    .font(.system(size: 25))
                Spacer()
            }
            .padding(.horizontal)
            Divider()
        }
    }
}
