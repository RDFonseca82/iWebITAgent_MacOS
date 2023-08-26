//
//  GetDeviceDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import Foundation
import Combine


class GetDevicetDataService {
    static let shared = GetDevicetDataService()
    
    func getDevice() async throws -> DeviceDTO {
        var data: Data
        
        do {
            data = try await NetworkingManager.download(url: Constants.getDeviceInfoUrl, parameters: ["UniqueID": AppInfo.uniqueid])
        } catch {
            throw iWebITError.httpError
        }
        
        let jsonString = String(decoding: data, as: UTF8.self)
        
        guard let dtoData = (try? JSONDecoder().decode(DeviceDTO.self, from: jsonString.data(using: .utf8)!)) else {
            throw iWebITError.decodingError
        }
        
        return dtoData
    }
}
