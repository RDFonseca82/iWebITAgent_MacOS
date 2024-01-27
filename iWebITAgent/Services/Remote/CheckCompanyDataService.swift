//
//  CheckCompanyDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import Foundation
import Combine


class CheckCompanyDataService {
    static let shared = CheckCompanyDataService()
    
    func checkCompany(idSync: String) async throws -> Bool {
        var data: Data
        
        do {
            data = try await NetworkingManager.download(url: Constants.readCompanyInfoUrl, parameters: ["IdSync": idSync])
        } catch {
            throw iWebITError.httpError
        }
        
        guard let jsonString = data.toString(), jsonString != "null" else { return false }
        
        return true
    }
}
