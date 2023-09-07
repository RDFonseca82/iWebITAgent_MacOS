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
    @StateObject var toastVm = SnackbarViewModel()
    
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
                    .disabled(loginVm.state.isLoading)
                
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
                        if loginVm.idSync.isBlank() {
                            toastVm.showSnackbar(
                                text: "Por favor, insira o IDSync para prosseguir.",
                                timeMillis: 8000
                            )
                            return
                        }
                        Task {
                            await loginVm.login(loginWindow: window!)
                        }
                    } label: {
                        HStack {
                            if loginVm.state.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .controlSize(.small)
                                    .offset(x: -8)
                            }
                            
                            Text("Entrar")
                        }
                        .defaultButtonView()
                        .hoverEffect()
                    }
                    .buttonStyle(.plain)
                    .disabled(loginVm.state.isLoading)

                }
            }
            .fillMaxWidth()
            .padding(.horizontal, 30)
        }
        .background(WindowAccessor(window: $window, shouldCenter: true))
        .overlay(
            ZStack {
                if toastVm.showing {
                    Toast(vm: toastVm)
                        .offset(y: 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            },
            alignment: .bottomLeading
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if AppInfo.isLoggedIn() {
                    if let window = window {
                        let workspace = NSWorkspace.shared
                        
                        if let deepLinkUrl = URL(string: "iwebit://support") {
                            workspace.open(deepLinkUrl)
                        }
                        window.close()
                    }
                }
            }
        }
        .onChange(of: loginVm.state.error) { newError in
            if newError != .none {
                toastVm.showSnackbar(
                    text: newError.description,
                    timeMillis: 8000
                )
            } else {
                toastVm.close()
            }
        }
    }
}
