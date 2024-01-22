//
//  AppsToUninstallDTO.swift
//  iWebITService
//
//  Created by Admin on 01/09/2023.
//

import Foundation


struct AppsToUninstallDTO: Codable {
    let appName: String?
    
    enum CodingKeys: String, CodingKey {
        case appName = "SoftwareName"
    }
}
