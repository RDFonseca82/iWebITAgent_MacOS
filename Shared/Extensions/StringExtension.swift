//
//  StringExtension.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 19/08/2023.
//

import Foundation


extension String {
    func toJsonObject() throws -> [String: String] {
        guard let jsonData = self.data(using: .utf8) else { throw iWebITError.decodingError }
        return try JSONSerialization.jsonObject(with: jsonData) as! [String: String]
    }
    func isBlank() -> Bool {
        return self.trimmingCharacters(in: [" "]) == ""
    }
    func isNotBlank() -> Bool {
        return !self.isBlank()
    }
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }
    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
    func toDate(pattern: String = "dd/MM/yyyy HH:mm:ss") -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return dateFormatter.date(from: self) ?? Date(timeIntervalSinceReferenceDate: 0)
    }
}
