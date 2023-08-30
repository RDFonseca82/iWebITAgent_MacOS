//
//  Constants.swift
//  MODA
//
//  Created by Admin on 25/02/2023.
//

import Foundation

struct Constants {
    static let getDeviceInfoUrl = "http://agent.iwebit.app/scripts/script_api.php"
    static let createOrSendDeviceInfoUrl = "http://agent.iwebit.app/scripts/script_windows.php"
    
    static let LOG_TAG = "IWEBIT"
    static let LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!.appendingPathComponent("log_\(Bundle.main.bundleIdentifier!).txt")
    static let OLD_LOG_FILE = FilesManager.shared.getApplicationSupportDirectory()!.appendingPathComponent("old_log_\(Bundle.main.bundleIdentifier!).txt")
}
