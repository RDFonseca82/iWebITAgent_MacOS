//
//  SuporteScreen.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import SwiftUI
import SwiftUIIntrospect

struct SuporteScreen: View {
    @EnvironmentObject var homeVm: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suporte")
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(.theme.onBackground)
                .padding(.bottom, 40)
            
            CustomTextField(placeholder: "Nome", text: $homeVm.suporteNome)
                .fillMaxWidth()
                .padding(.bottom, 30)
            
            TextEditor(text: $homeVm.suporteMensagem)
                .height(300)
                .padding(.bottom, 30)
            
            Button {
                
            } label: {
                Text("Entrar")
                    .defaultButtonView()
                    .hoverEffect()
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .fillMaxSize()
        .padding(12)
    }
}
