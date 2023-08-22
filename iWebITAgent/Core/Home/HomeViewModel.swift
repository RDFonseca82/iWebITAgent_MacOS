//
//  HomeViewModel.swift
//  iWebITAgent
//
//  Created by Admin on 21/08/2023.
//

import Foundation


class HomeViewModel: ObservableObject {
    @Published var searchText: String = ""
    
    @Published var suporteNome: String = ""
    @Published var suporteMensagem: String = ""
    
}
