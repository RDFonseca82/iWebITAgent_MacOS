//
//  HomeViewModel.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import Foundation


class HomeViewModel: ObservableObject {
    private let repository = iWebITRepository.shared
    
    @Published var supports: [Support] = []
    @Published var selectedSupport: Support = Support()
    
    @Published var state: HomeState = HomeState()
    
    @Published var searchText: String = ""
    
    @Published var suporteNome: String = ""
    @Published var suporteMensagem: String = ""
    
    func getSupports() async {
        do {
            let supports = try await repository.getSupports()
            await MainActor.run {
                self.supports = supports
            }
            print(supports)
        } catch {
            print("ERROR HOME VIEWMODEL: \(error)")
        }
    }
    
    func sendSupport() async {
        do {
            try await repository.sendSupport(nome: suporteNome, message: suporteMensagem)
        } catch {
            print("ERROR HOME VIEWMODEL: \(error)")
        }
    }
    
    
}
