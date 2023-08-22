//
//  SupportDTO.swift
//  iWebITAgent
//
//  Created by Admin on 22/08/2023.
//

import Foundation

struct SupportDTO: Codable {
    let idDeviceSupport, nome, deviceSupport, deviceSupportDate: String?
    let deviceSupportClose: Int?
    let deviceSupportCloseDate: String?
    let deviceSupportCloseUser: String?
    let idCompany: String?
    let uniqueID: String?
    let supportCanceled: Int?
    let supportCanceledDate: String?
    let idDevice: String?
    let idUserSupport, idUser: String?
    let supportInternal, supportAddOn: Int?
    let reportTec, deviceSupportDateWork, deviceSupportTimeWork, respNote: String?

    enum CodingKeys: String, CodingKey {
        case idDeviceSupport = "IdDeviceSupport"
        case nome = "Nome"
        case deviceSupport = "DeviceSupport"
        case deviceSupportDate = "DeviceSupportDate"
        case deviceSupportClose = "DeviceSupportClose"
        case deviceSupportCloseDate = "DeviceSupportCloseDate"
        case deviceSupportCloseUser = "DeviceSupportCloseUser"
        case idCompany = "IdCompany"
        case uniqueID = "UniqueID"
        case supportCanceled = "SupportCanceled"
        case supportCanceledDate = "SupportCanceledDate"
        case idDevice = "IdDevice"
        case idUserSupport = "IdUserSupport"
        case idUser = "IdUser"
        case supportInternal = "SupportInternal"
        case supportAddOn = "SupportAddOn"
        case reportTec = "ReportTec"
        case deviceSupportDateWork = "DeviceSupportDateWork"
        case deviceSupportTimeWork = "DeviceSupportTimeWork"
        case respNote = "RespNote"
    }
}
