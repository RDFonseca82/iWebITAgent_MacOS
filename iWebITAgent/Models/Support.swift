//
//  Support.swift
//  iWebITAgent
//
//  Created by Admin on 22/08/2023.
//

import Foundation


struct Support: Identifiable {
    let id = UUID().uuidString
    let nome, deviceSupport: String?
    let deviceSupportDate: Date
    
    init() {
        nome = "-"
        deviceSupport = "-"
        deviceSupportDate = FormatDt.shared.defaultDate
    }
    
    init(dto: SupportDTO) {
        nome = dto.nome ?? "-"
        deviceSupport = dto.deviceSupport ?? "-"
        deviceSupportDate = FormatDt.shared.toDate(stringData: String(dto.deviceSupportDate?.prefix(19) ?? "")) ?? FormatDt.shared.defaultDate
    }
}
