//
//  DeviceDTO.swift
//  iWebITSysTray
//
//  Created by Admin on 26/08/2023.
//

import Foundation


struct DeviceDTO: Codable {
    let idDevice, uniqueID, idCompany, idSync: String?
    let idDeviceType, active: Int?
    let lastConnectDate: String?
    let fullSync, deviceLocation, operatingSystemReboot, operatingSystemShutDown: Int?
    let timeSync, timeAlive, mssqlServer, androidPrintScreen: Int?
    let androidMessage: Int?
    let androidMessageTxt: String?
    let windowsPrintScreen: Int?
    
    enum CodingKeys: String, CodingKey {
        case idDevice = "IdDevice"
        case uniqueID = "UniqueID"
        case idCompany = "IdCompany"
        case idSync = "IDSync"
        case idDeviceType = "IdDeviceType"
        case active = "Active"
        case lastConnectDate = "LastConnectDate"
        case fullSync = "FullSync"
        case deviceLocation = "DeviceLocation"
        case operatingSystemReboot = "OperatingSystem_Reboot"
        case operatingSystemShutDown = "OperatingSystem_ShutDown"
        case timeSync = "TimeSync"
        case timeAlive = "TimeAlive"
        case mssqlServer = "MSSQLServer"
        case androidPrintScreen = "AndroidPrintScreen"
        case androidMessage = "AndroidMessage"
        case androidMessageTxt = "AndroidMessageTxt"
        case windowsPrintScreen = "WindowsPrintScreen"
    }
}
