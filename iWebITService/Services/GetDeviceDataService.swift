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
        
        guard let dtoData = (try? JSONDecoder().decode(DeviceDTO.self, from: data)) else {
            throw iWebITError.decodingError
        }
        
        return dtoData
    }
}
