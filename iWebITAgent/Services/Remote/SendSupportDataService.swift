//
//  SendSupportDataService.swift
//  MODA
//
//  Created by Admin on 23/08/2023.
//

import Foundation


class SendSupportDataService {
    
    func sendSupport(nome: String, message: String) async throws {
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let _ = try await NetworkingManager.send(
                url: Constants.postSupportUrl+"?UniqueID=\(AppInfo.uniqueid)",
                formEncoded: "Nome=\(nome)&DeviceSupport=\(message)&DeviceSupportDate=\(formatter.string(from: Date()))".data(using: .utf8)!
            )
        } catch {
            throw iWebITError.httpError
        }
            
    }
}
