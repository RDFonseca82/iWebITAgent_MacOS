//
//  LoginWindow.swift
//  iWebITAgent
//
//  Created by Admin on 16/08/2023.
//

import SwiftUI

struct LoginWindow: View {
    @State private var window: NSWindow?
    
    @Environment(\.openURL) var openURL
    
    @StateObject var loginVm = LoginViewModel()
    
    var body: some View {
        HStack {
            Image("iwebit")
                .resizable()
                .scaledToFit()
                .frame(height: 140)
                .padding(.leading, 30)
            VStack {
                Text("Por favor, insira o seu **IDSync** no campo abaixo para começar a utilizar o **iWebITAgent**.")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .foregroundColor(.theme.secondary)
                    .padding(.bottom, 30)
                
                CustomTextField(placeholder: "IDSync", text: $loginVm.idSync)
                    .padding(.bottom, 10)
                
                HStack {
                    Button {
                        openURL(Constants.iwebitSiteUrl)
                    } label: {
                        Text("Não tem o seu IdSync?")
                            .hoverEffect()
                    }
                    .buttonStyle(.link)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await loginVm.login(loginWindow: window!)
                        }
                    } label: {
                        Text("Entrar")
                            .defaultButtonView()
                            .hoverEffect()
                    }
                    .buttonStyle(.plain)

                }
            }
            .fillMaxWidth()
            .padding(.horizontal, 30)
        }
        .background(WindowAccessor(window: $window, shouldCenter: true))
    }
}
