//
//  Constants.swift
//  MODA
//
//  Created by Admin on 25/02/2023.
//

import Foundation

struct Constants {
    static var shared = Constants()
    
    #if DEBUG
    static let AGENT_VERSION = "1.0.0.5"
    #else
    static let AGENT_VERSION = "__VERSION__"
    #endif
    
    static let PRODUCT_DIR = "__PRODUCT_DIR__"
    static let BUNDLE_ID = "com.rdfonseca.iWebIT"
    
    static let getDeviceInfoUrl = "http://agent.iwebit.app/scripts/script_api.php"
    static let readCompanyInfoUrl = "http://agent.iwebit.app/scripts/script_api.php"
    static let getAppsToUninstall = "http://agent.iwebit.app/scripts/script_api.php"
    static let createOrSendDeviceInfoUrl = "http://agent.iwebit.app/scripts/script_ios.php"
    
    var LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!
    var OLD_LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!
    
}
