//
//  GetDeviceDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import Foundation


class GetDeviceDataService {
    static let shared = GetDeviceDataService()
    
    func getDevice() throws -> DeviceDTO {
        var data: Data
        
        do {
            data = try NetworkingManager.download(url: Constants.getDeviceInfoUrl, parameters: ["UniqueID": AppInfo.uniqueid])
        } catch {
            throw iWebITError.httpError
        }
        
        let jsonString = String(data: data, encoding: .utf8)!
        
        guard let dtoData = (try? JSONDecoder().decode(DeviceDTO.self, from: jsonString.data(using: .utf8)!)) else {
            throw iWebITError.decodingError
        }
        
        return dtoData
    }
}
