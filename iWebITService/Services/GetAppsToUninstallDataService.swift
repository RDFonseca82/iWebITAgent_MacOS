//
//  GetDeviceDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import Foundation


class GetAppsToUninstallDataService {
    static let shared = GetAppsToUninstallDataService()
    
    func getAppsToUninstall() throws -> [AppsToUninstallDTO] {
        var data: Data
        
        do {
            data = try NetworkingManager.download(url: Constants.getAppsToUninstall, parameters: ["Uninstall": "1", "UniqueID": AppInfo.uniqueid])
        } catch {
            throw iWebITError.httpError
        }
        
        let jsonString = String(data: data, encoding: .utf8)!
        
        if jsonString == "null" || jsonString == "" {
            return []
        }
        
        guard let dtoData = (try? JSONDecoder().decode([AppsToUninstallDTO].self, from: jsonString.data(using: .utf8)!)) else {
            throw iWebITError.decodingError
        }
        
        return dtoData
    }
}
