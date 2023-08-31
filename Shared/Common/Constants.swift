//
//  Constants.swift
//  MODA
//
//  Created by Admin on 25/02/2023.
//

import Foundation

struct Constants {
    static var shared = Constants()
    
    static let getDeviceInfoUrl = "http://agent.iwebit.app/scripts/script_api.php"
    static let createOrSendDeviceInfoUrl = "http://agent.iwebit.app/scripts/script_windows.php"
    
    var LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!
    var OLD_LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!
    
}
