//
//  HomeViewModel.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import Foundation


class HomeViewModel: ObservableObject {
    private let repository = iWebITRepository.shared
    
    @Published var searchText: String = ""
    
    @Published var suporteNome: String = ""
    @Published var suporteMensagem: String = ""
    
    @Published var supports: [Support] = []
    
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
    
    
}
