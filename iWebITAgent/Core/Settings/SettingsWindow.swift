//
//  SettingsWindow.swift
//  iWebITAgent
//
//  Created by Admin on 16/08/2023.
//

import SwiftUI

struct SettingsWindow: View {
    @Environment(\.openURL) var openUrl

    @State private var isHovering = false
    @State private var accessCode = ""
    @State private var isUnlocked = false
    @State private var validationMessage: String?

    var body: some View {
        Group {
            if isUnlocked {
                settingsContent
            } else {
                accessGate
            }
        }
        .fillMaxSize()
        .onDisappear {
            accessCode = ""
            isUnlocked = false
            validationMessage = nil
        }
    }

    private var accessGate: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield")
                .font(.system(size: 46))
                .foregroundColor(.theme.accent)

            Text("Definições protegidas")
                .font(.system(size: 28, weight: .semibold))

            Text("Introduza o IDSYNC deste agente para abrir as definições.")
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.secondary)

            SecureField("IDSYNC", text: $accessCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 280)

            if let validationMessage = validationMessage {
                Text(validationMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 13))
            }

            Button {
                unlockSettings()
            } label: {
                Text("Abrir definições")
                    .defaultButtonView()
                    .hoverEffect()
            }
            .buttonStyle(.plain)
            .disabled(accessCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color.theme.background)
    }

    private var settingsContent: some View {
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
        .background(Color.theme.background)
    }

    private func unlockSettings() {
        let candidate = accessCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard candidate == AppInfo.idsync else {
            validationMessage = "IDSYNC incorreto."
            log("SETTINGS ACCESS DENIED", important: true)
            return
        }

        validationMessage = nil
        accessCode = ""
        isUnlocked = true
        log("SETTINGS ACCESS GRANTED", important: true)
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