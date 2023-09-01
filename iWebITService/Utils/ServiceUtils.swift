//
//  ServiceUtils.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation
import IOKit.ps
import AppKit

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

func alert(title: String, text: String, alertStyle: NSAlert.Style = .warning) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = text
    alert.addButton(withTitle: "Ok")
    alert.alertStyle = alertStyle
    alert.runModal()
}

