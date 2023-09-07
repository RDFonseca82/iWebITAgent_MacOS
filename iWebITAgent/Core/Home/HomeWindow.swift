//
//  HomeScreen.swift
//  iWebITAgent
//
//  Created by Admin on 16/08/2023.
//

import SwiftUI

struct HomeWindow: View {
    @State private var window: NSWindow?
    
    @StateObject var homeVm = HomeViewModel()
    @StateObject var toastVm = SnackbarViewModel()
    
    @State private var showingOcorrencias = true
    
    var body: some View {
        HStack {
            NavBar(showingOcorrencias: $showingOcorrencias)
            ZStack {
                if showingOcorrencias {
                    OcorrenciasScreen()
                } else {
                    SuporteScreen(showingOcorrencias: $showingOcorrencias)
                }
            }
            .fillMaxSize()
            .background(Color.theme.background)
        }
        .ignoresSafeArea()
        .background(WindowAccessor(window: $window, initialTitle: "Ocorrências", shouldCenter: false))
        .overlay(
            ZStack {
                if toastVm.showing {
                    Toast(vm: toastVm)
                        .padding(.bottom)
                        .padding(.leading, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            },
            alignment: .bottomLeading
        )
        .onAppear {
            Task {
                await homeVm.getSupports()
                homeVm.firstRequest = false
            }
        }
        .onChange(of: homeVm.state.error) { newError in
            if newError != .none {
                toastVm.showSnackbar(
                    text: newError.description
                )
            } else {
                toastVm.close()
            }
        }
        .environmentObject(homeVm)
        .environmentObject(toastVm)
    }
}
