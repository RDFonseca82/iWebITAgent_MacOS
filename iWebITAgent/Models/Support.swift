//
//  Support.swift
//  iWebITAgent
//
//  Created by Admin on 22/08/2023.
//

import Foundation


struct Support {
    let nome, deviceSupport, deviceSupportDate: String?
    
    init() {
        nome = "-"
        deviceSupport = "-"
        deviceSupportDate = "-"
    }
    
    init(dto: SupportDTO) {
        nome = dto.nome ?? "-"
        deviceSupport = dto.deviceSupport ?? "-"
        deviceSupportDate = dto.deviceSupportDate ?? "-"
    }
}
