//
//  GetSupportDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import Foundation
import Combine


class GetSupportDataService {
    static let shared = GetSupportDataService()
    
    func getSupport() async throws -> [SupportDTO] {
        var data: Data
        
        do {
            data = try await NetworkingManager.download(url: Constants.getSupportUrl, parameters: ["Support": "1", "UniqueID": AppInfo.uniqueid])
        } catch {
            throw iWebITError.httpError
        }
        
        let jsonString = "[\(String(decoding: data, as: UTF8.self))]".replacingOccurrences(of: "}{", with: "}, {")
        
        guard let dtoData = (try? JSONDecoder().decode([SupportDTO].self, from: jsonString.data(using: .utf8)!)) else {
            throw iWebITError.decodingError
        }
        
        return dtoData
    }
}
