//
//  Constants.swift
//  MODA
//
//  Created by Admin on 25/02/2023.
//

import Foundation

struct Constants {
    static var shared = Constants()
    
    static let AGENT_VERSION = Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String ?? "2.0.0"
    static let AGENT_BUILD = Bundle.main.object(
        forInfoDictionaryKey: "CFBundleVersion"
    ) as? String ?? "201"
    
    static let PRODUCT_DIR = "__PRODUCT_DIR__"
    static let BUNDLE_ID = "com.rdfonseca.iWebIT"

    // Legacy remote actions stay disabled until the backend emits authenticated,
    // signed v2 commands and signed update manifests.
    static let allowLegacyUnsignedUpdates = false
    static let allowLegacyDestructiveCommands = false
    static let allowLegacyPrivacyCommands = false
    
    static let getDeviceInfoUrl = "https://agent.iwebit.app/scripts/script_api.php"
    static let readCompanyInfoUrl = "https://agent.iwebit.app/scripts/script_api.php"
    static let getAppsToUninstall = "https://agent.iwebit.app/scripts/script_api.php"
    static let createOrSendDeviceInfoUrl = "https://agent.iwebit.app/scripts/script_ios.php"
    
    var LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!
    var OLD_LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!
    
}
