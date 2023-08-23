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
    
    @Published var state: HomeState = HomeState()
    
    @Published var searchText: String = ""
    
    @Published var suporteNome: String = ""
    @Published var suporteMensagem: String = ""
    
    func getSupports() async {
        await MainActor.run {
            state = HomeState(error: .none, isLoading: true)
        }
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let supports = try await repository.getSupports()
            await MainActor.run {
                state = HomeState(error: .none, isLoading: false)
                self.supports = supports
            }
        } catch {
            print("ERROR HOME VIEWMODEL: \(error)")
            await MainActor.run {
                state = HomeState(error: error as? iWebITError ?? iWebITError.generalError, isLoading: false)
            }
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
