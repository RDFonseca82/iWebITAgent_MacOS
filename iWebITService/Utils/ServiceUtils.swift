//
//  ServiceUtils.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation
import IOKit.ps

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

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Int) async throws {
        try await sleep(nanoseconds: UInt64(seconds*1_000_000_000))
    }
}

extension String {
    func toDate(pattern: String = "dd/MM/yyyy HH:mm:ss") -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return dateFormatter.date(from: self) ?? Date(timeIntervalSinceReferenceDate: 0)
    }
}

