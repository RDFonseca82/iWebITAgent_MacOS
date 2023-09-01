//
//  CompanyDTO.swift
//  iWebITService
//
//  Created by Admin on 01/09/2023.
//

import Foundation


struct CompanyDTO: Codable {
    let idSync, idCompany, company: String?
    let active: Int?
    let logoOnline, logoOffline, logoInactive: String?
    let deviceSupportx86, deviceSupportx64: String?
    let eventViewerLines, timeSync, timeAlive: Int?
    let agentVersion: String?
    let agentDownload: String?
    
    enum CodingKeys: String, CodingKey {
        case idSync = "IDSync"
        case idCompany = "IdCompany"
        case company = "Company"
        case active = "Active"
        case logoOnline = "LogoOnline"
        case logoOffline = "LogoOffline"
        case logoInactive = "LogoInactive"
        case deviceSupportx86 = "DeviceSupportx86"
        case deviceSupportx64 = "DeviceSupportx64"
        case eventViewerLines = "EventViewerLines"
        case timeSync = "TimeSync"
        case timeAlive = "TimeAlive"
        case agentVersion = "AgentVersion"
        case agentDownload = "AgentDownload"
    }
}
