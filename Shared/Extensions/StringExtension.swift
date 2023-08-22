//
//  StringExtension.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 19/08/2023.
//

import Foundation


extension String {
    func toJsonObject() throws -> [String: Any] {
        guard let jsonData = self.data(using: .utf8) else { throw iWebITError.decodingError }
        return try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    }
    func isBlank() -> Bool {
        return self.trimmingCharacters(in: [" "]) == ""
    }
    func isNotBlank() -> Bool {
        return !self.isBlank()
    }
}
