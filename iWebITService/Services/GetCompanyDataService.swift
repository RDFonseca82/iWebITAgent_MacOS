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
        
        guard let dtoData = (try? JSONDecoder().decode(CompanyDTO.self, from: data)) else {
            throw iWebITError.decodingError
        }
        
        return dtoData
    }
}
