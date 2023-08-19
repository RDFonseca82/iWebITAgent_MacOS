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
                
                HStack {
                    Button {
                        openURL(Constants.iwebitSiteUrl)
                    } label: {
                        Text("Não tem o seu IdSync?")
                    }
                    .buttonStyle(.link)
                    .cursor(.pointingHand)
                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Text("Entrar")
                            .defaultButtonView()
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
