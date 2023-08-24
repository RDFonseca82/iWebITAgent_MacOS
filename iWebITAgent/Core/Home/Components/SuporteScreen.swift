//
//  SuporteScreen.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import SwiftUI
import SwiftUIIntrospect

struct SuporteScreen: View {
    @EnvironmentObject var toastVm: SnackbarViewModel
    @EnvironmentObject var homeVm: HomeViewModel
    
    @Binding var showingOcorrencias: Bool
    
    @State var showNomeError: Bool = false
    @State var showMensagemError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suporte")
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(.theme.onBackground)
                .padding(.bottom, 40)
            
            CustomTextField(placeholder: "Nome", text: $homeVm.suporteNome.max(50).noNewLine())
                .fillMaxWidth()
                .overlay(
                    HStack {
                        Text(showNomeError ? "Por favor, digite o seu nome." : "")
                            .foregroundColor(.darkRed)
                        Spacer()
                        Text("\(homeVm.suporteNome.count)/50")
                            .foregroundColor(.gray)
                    }
                        .offset(y: 18),
                    alignment: .bottom
                )
                .padding(.bottom, 30)
            
            ZStack(alignment: .topLeading) {
                if homeVm.suporteMensagem.isBlank() {
                    Text("Mensagem de suporte")
                        .foregroundColor(Color.gray)
                        .font(.title3)
                        .padding(.top, 10)
                        .padding(.leading, 10)
                }
                
                TextEditor(text: $homeVm.suporteMensagem.max(5000))
                    .height(300)
                    .introspect(.textEditor, on: .macOS(.v11, .v12, .v13, .v14)) { textEditor in
                        textEditor.backgroundColor = .clear
                        textEditor.textContainerInset = NSSize(width: 4, height: 10)
                    }
                    .font(.title3)
            }
            .overlay(
                HStack {
                    Text(showMensagemError ? "Por favor, digite o seu pedido de suporte." : "")
                        .foregroundColor(.darkRed)
                    Spacer()
                    Text("\(homeVm.suporteMensagem.count)/5000")
                        .foregroundColor(.gray)
                }
                    .offset(y: 18),
                alignment: .bottom
            )
            
            .background(
                Color.theme.darkGray
                    .cornerRadius(8)
                    .shadow(
                        color: Color.theme.onBackground.opacity(0.15),
                        radius: 4
                    )
            )
            .padding(.bottom, 30)
            
            Button {
                showNomeError = homeVm.suporteNome.isBlank()
                showMensagemError = homeVm.suporteMensagem.isBlank()
                
                if showNomeError || showMensagemError {
                    return
                }
                
                Task {
                    await homeVm.sendSupport()
                    if homeVm.state.error == .none {
                        await MainActor.run {
                            toastVm.showSnackbar(text: "Suporte enviado com sucesso.")
                            homeVm.suporteNome = ""
                            homeVm.suporteMensagem = ""
                            showingOcorrencias = true
                        }
                        await homeVm.getSupports()
                    }
                }
            } label: {
                HStack {
                    if homeVm.state.isLoadingSend {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .offset(x: -8)
                    }
                    Text("Enviar")
                }
                .defaultButtonView()
                .hoverEffect()
            }
            .buttonStyle(.plain)
            .disabled(homeVm.state.isLoadingSend)
            Spacer()
        }
        .fillMaxSize()
        .padding(12)
    }
}
