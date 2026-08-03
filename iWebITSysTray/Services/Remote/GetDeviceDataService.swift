//
//  GetDeviceDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import Foundation


class GetDeviceDataService {
    static let shared = GetDeviceDataService()
    
    func getDevice() async throws -> DeviceDTO {
        var data: Data
        
        do {
            data = try await NetworkingManager.download(url: Constants.getDeviceInfoUrl, parameters: ["UniqueID": AppInfo.uniqueid])
        } catch {
            AppInfo.net = "0"
            log("BACKEND REQUEST FAILED: \(error)", important: true)
            throw iWebITError.httpError
        }

        AppInfo.net = "1"
        do {
            return try JSONDecoder().decode(DeviceDTO.self, from: data)
        } catch {
            log("BACKEND RESPONSE INVALID: \(data.count) bytes; \(error)", important: true)
            throw iWebITError.decodingError
        }
    }
}
