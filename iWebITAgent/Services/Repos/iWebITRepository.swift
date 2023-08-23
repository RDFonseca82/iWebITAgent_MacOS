//
//  iWebITRepository.swift
//  iWebITAgent
//
//  Created by Admin on 22/08/2023.
//

import Foundation


class iWebITRepository {
    static let shared = iWebITRepository()
    
    private let getSupportDataService = GetSupportDataService()
    private let sendSupportDataService = SendSupportDataService()
    
    func getSupports() async throws -> [Support] {
        let supports = try await getSupportDataService.getSupport()
        
        return supports.map { Support(dto: $0) }
    }
    
    func sendSupport(nome: String, message: String) async throws {
        try await sendSupportDataService.sendSupport(nome: nome, message: message)
    }
}
