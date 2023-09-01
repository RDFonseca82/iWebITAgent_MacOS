//
//  ConstantsExtended.swift
//  MODA
//
//  Created by Admin on 25/02/2023.
//

import Foundation

extension Constants {
    static let readCompanyInfoUrl = "http://agent.iwebit.app/scripts/script_api.php"
    
    static let VARS_FILE = FilesManager.shared.getApplicationSupportDirectory()!.appendingPathComponent("vars.json")
}
