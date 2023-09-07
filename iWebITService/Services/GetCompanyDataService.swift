//
//  GetCompanyDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import Foundation
import Combine


class GetCompanyDataService {
    static let shared = GetCompanyDataService()
    
    func getCompany() throws -> CompanyDTO {
        var data: Data
        
        do {
            data = try NetworkingManager.download(url: Constants.readCompanyInfoUrl, parameters: ["IdSync": AppInfo.idsync])
        } catch {
            throw iWebITError.httpError
        }
        
        let jsonString = String(data: data, encoding: .utf8)!
        
        guard let dtoData = (try? JSONDecoder().decode(CompanyDTO.self, from: jsonString.data(using: .utf8)!)) else {
            throw iWebITError.decodingError
        }
        
        return dtoData
    }
}
