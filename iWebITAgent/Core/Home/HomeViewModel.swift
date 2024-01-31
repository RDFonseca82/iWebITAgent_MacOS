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
    @Published var filteredSupports: [Support] = []
    
    @Published var state: HomeState = HomeState()
    
    @Published var searchBy: String = ""
    
    @Published var suporteNome: String = ""
    @Published var suporteMensagem: String = ""
    
    @Published var firstRequest: Bool = true
    
    private var sortJob: Task<(), Never>? = nil
    
    func getSupports() async {
        await MainActor.run {
            state = HomeState(error: .none, isLoading: true)
        }
        do {
            let supports = try await repository.getSupports()
            await MainActor.run {
                state = HomeState(error: .none, isLoading: false)
                self.supports = supports
                self.filterSupports(nil)
            }
        } catch {
            log("ERROR HOME VIEWMODEL: \(error)", important: true)
            await MainActor.run {
                state = HomeState(error: error as? iWebITError ?? iWebITError.generalError, isLoading: false)
            }
        }
    }
    
    func sendSupport() async {
        await MainActor.run {
            state = HomeState(isLoadingSend: true)
        }
        do {
            try await repository.sendSupport(nome: suporteNome, message: suporteMensagem)
            
            await MainActor.run {
                state = HomeState(isLoadingSend: false)
            }
        } catch {
            log("ERROR HOME VIEWMODEL: \(error)", important: true)
            await MainActor.run {
                state = HomeState(error: error as? iWebITError ?? iWebITError.generalError, isLoadingSend: false)
            }
        }
    }
    
    func filterSupports(
        _ newSearchBy: String? = ""
    ) {
        sortJob?.cancel()
        
        sortJob = Task { @MainActor in
            var temp = supports
            
            let _searchBy = newSearchBy ?? searchBy
            
            if _searchBy.trimmingCharacters(in: .whitespaces) != "" {
                let lowercasedText = _searchBy.lowercased()
                temp = temp.filter {
                    $0.nome?.lowercased().contains(lowercasedText) ?? false ||
                    $0.deviceSupport?.lowercased().contains(lowercasedText) ?? false
                }
            }
            
            filteredSupports = temp
        }
        
        searchBy = newSearchBy ?? searchBy
    }
    
    
}
