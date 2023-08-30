//
//  SendLocationDataService.swift
//  MODA
//
//  Created by Admin on 23/08/2023.
//

import Foundation


class SyncLocationDataService {
    static let shared = SyncLocationDataService()
    
    func syncLocation(coordinate: LocationPoint) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let data: [String : Any] = [
            "Latitude": String(coordinate.latitude),
            "Longitude": String(coordinate.longitude),
            "UniqueID": AppInfo.uniqueid,
            "IDSync": AppInfo.idsync,
            "LastConnectDate": formatter.string(from: Date()),
            "AgentVersion": AppInfo.agentversion,
        ]
        log("HEYEYEY SENDING LOCATION: ")
        let jsonString = String(data: try JSONSerialization.data(withJSONObject: data), encoding: .utf8)!
        log(jsonString)
        
        let _ = try await NetworkingManager.send(
            url: Constants.createOrSendDeviceInfoUrl,
            jsonData: [
                "json": jsonString
            ]
        )
    }
}
