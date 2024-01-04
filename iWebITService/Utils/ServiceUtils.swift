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
        log("NO IDSYNC SPECIFIED, WAITING 15s")
        Thread.sleep(forTimeInterval: TimeInterval(15))
    }
}

func ensureUserLoggedIn() {
    if !AppInfo.isLoggedIn() {
        log("!!! ROLLBACK TO SERVICE START: USER NOT LOGGED IN !!!")
        fatalError("USER NOT LOGGED IN")
    }
}


extension FileManager {
    
    static func getTotalStorageCapacity() -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: "/")
            if let totalSize = attributes[.systemSize] as? Int64 {
                return totalSize
            }
        } catch {
            log("ERROR GETTING TOTAL STORAGE CAPACITY: \(error)")
        }
        return nil
    }
    
    static func getUsedStorageSpace() -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: "/")
            if let freeSize = attributes[.systemFreeSize] as? Int64 {
                if let totalSize = attributes[.systemSize] as? Int64 {
                    let usedSize = totalSize - freeSize
                    return usedSize
                }
            }
        } catch {
            log("ERROR GETTING USED STORAGE SPACE: \(error)")
        }
        return nil
    }
}

