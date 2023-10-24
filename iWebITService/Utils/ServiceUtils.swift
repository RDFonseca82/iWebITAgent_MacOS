//
//  ServiceUtils.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation
import AppKit
import CommonCrypto

typealias AnyDict = [String:Any]
typealias AnyList = [Any]

let gigabyteToByte: Int64 = 1024 * 1024 * 1024

func createUniqueId(value: String) -> String {
    if let valueData = value.data(using: .utf8) {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        valueData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(valueData.count), &hash)
            
        }
        return hash.map { String(format: "%02hhx", $0) }.joined()
        
    }
    return ""
}

func alert(title: String, text: String, alertStyle: NSAlert.Style = .warning) {
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.addButton(withTitle: "Ok")
        alert.alertStyle = alertStyle
        alert.runModal()
    }
}

func waitForLogIn() {
    while !AppInfo.isLoggedIn() {
        log("NO IDSYNC SPECIFIED, WAITING 120s")
        Thread.sleep(forTimeInterval: TimeInterval(120))
    }
}

func ensureUserLoggedIn() {
    if !AppInfo.isLoggedIn() {
        log("!!! ROLLBACK TO SERVICE START: USER NOT LOGGED IN !!!")
        fatalError("USER NOT LOGGED IN")
    }
}


extension FileManager {

    static func getFileSize(for key: FileAttributeKey) -> Int64? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)

        guard
            let lastPath = paths.last,
            let attributeDictionary = try? FileManager.default.attributesOfFileSystem(forPath: lastPath) else { return nil }

        if let size = attributeDictionary[key] as? NSNumber {
            return size.int64Value
        } else {
            return nil
        }
    }

    static func convert(_ bytes: Int64, to units: ByteCountFormatter.Units = .useGB) -> String? {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = units
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes)
    }

}

