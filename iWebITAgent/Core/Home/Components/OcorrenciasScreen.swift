//
//  OcorrenciasScreen.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import SwiftUI

struct OcorrenciasScreen: View {
    @EnvironmentObject var globalVm: GlobalViewModel
    @EnvironmentObject var homeVm: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Ocorrências")
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(.theme.onBackground)
            
            HStack {
                CustomTextField(placeholder: "Procurar...", text: $homeVm.searchBy.max(50).noNewLine())
                    .width(350)
                    .height(40)
                    .fixedSize()
                
                Image("refresh")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .height(40)
                    .background(
                        Color.theme.darkGray.cornerRadius(8)
                    )
                    .hoverEffect()
                    .onTapGesture {
                        if homeVm.state.isLoading {
                            return 
                        }
                        Task {
                            await homeVm.getSupports()
                        }
                    }
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
                    ForEach(homeVm.filteredSupports) { support in
                        MessageView(support: support)
                            .onTapGesture {
                                globalVm.selectedSupport = support
                                openDeepLink(destination: "detail")
                            }
                    }
                }
                .padding(.trailing, 16)
            }
            .overlay(
                ZStack {
                    if (homeVm.state.error == .httpError || homeVm.state.error == .generalError) && homeVm.supports.isEmpty {
                        VStack {
                            Image("no_internet")
                                .resizable()
                                .scaledToFit()
                                .height(250)
                            Text(homeVm.state.error.description)
                                .foregroundColor(.gray)
                                .font(.system(size: 15))
                        }
                    } else if homeVm.supports.isEmpty && !homeVm.state.isLoading && !homeVm.firstRequest {
                        VStack {
                            Image("empty_list")
                                .resizable()
                                .scaledToFit()
                                .height(250)
                            Text("Aparentemente, ainda não reportou ocorrências.")
                                .foregroundColor(.gray)
                                .font(.system(size: 15))
                        }
                    }
                }
            )
            .overlay(
                ZStack {
                    if homeVm.state.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.theme.background)
                                    .shadow(
                                        color: Color.theme.onBackground.opacity(0.15),
                                        radius: 7
                                    )
                            )
                    }
                }
                    .padding(.bottom),
                alignment: .bottom
            )
        }
        .fillMaxSize()
        .padding([.leading, .top], 12)
        .onChange(of: homeVm.searchBy) { newValue in
            homeVm.filterSupports(newValue)
        }
    }
}
