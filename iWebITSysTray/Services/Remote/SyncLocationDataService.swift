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
        
        let data: [String : Any] = [
            "Latitude": String(coordinate.latitude),
            "Longitude": String(coordinate.longitude),
            "UniqueID": AppInfo.uniqueid,
            "IDSync": AppInfo.idsync,
            "LastConnectDate": Date().toString(),
            "AgentVersion": AppInfo.agentversion,
            "AppleType": 1,
            "IdDeviceType": 62,
        ]
        
        let jsonString = try JSONSerialization.data(withJSONObject: data).toString()!
        
        log(
            try await NetworkingManager.send(
                url: Constants.createOrSendDeviceInfoUrl,
                jsonData: [
                    "json": jsonString
                ]
            ), important: true
        )
    }
}
