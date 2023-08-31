//
//  CreateUniqueId.swift
//  iWebITService
//
//  Created by Admin on 30/08/2023.
//

import Foundation
import CommonCrypto

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
