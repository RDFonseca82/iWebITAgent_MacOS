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
    
    @State private var showingOcorrencias = true
    
    var body: some View {
        HStack {
            NavBar(showingOcorrencias: $showingOcorrencias)
            ZStack {
                if showingOcorrencias {
                    OcorrenciasScreen()
                } else {
                    SuporteScreen()
                }
            }
            .fillMaxSize()
            .background(Color.theme.background)
        }
        .ignoresSafeArea()
        .background(WindowAccessor(window: $window, initialTitle: "Ocorrências", shouldCenter: false))
        .environmentObject(homeVm)
//        .onAppear {
//            Task {
//                await homeVm.getSupports()
//            }
//        }
    }
}
