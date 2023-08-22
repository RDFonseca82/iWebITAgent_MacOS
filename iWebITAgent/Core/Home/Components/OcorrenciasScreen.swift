//
//  OcorrenciasScreen.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import SwiftUI
import SwiftUIIntrospect

struct OcorrenciasScreen: View {
    @EnvironmentObject var homeVm: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Ocorrências")
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(.theme.onBackground)
            
            HStack {
                CustomTextField(placeholder: "Procurar...", text: $homeVm.searchText)
                    .width(250)
                
                Image("refresh")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .height(40)
                    .background(
                        Color.theme.darkGray.cornerRadius(8)
                    )
                    .hoverEffect()
            }
            .padding(.top, -14)
            
            Divider()
                .padding(.leading, -12)
                .padding(.top, -6)
                .offset(y: 12)
            
            ScrollView {
                LazyVStack {
                    Spacer()
                        .height(12)
                    ForEach(0..<100) { index in
                        MessageView()
                    }
                }
                .padding(.trailing, 16)
            }
            .overlay(
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.theme.background)
                            .shadow(
                                color: Color.theme.onBackground.opacity(0.15),
                                radius: 7
                            )
                    )
                    .padding(.bottom),
                alignment: .bottom
            )
        }
        .fillMaxSize()
        .padding([.leading, .top], 12)
    }
}
