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
        print(jsonData)
        return try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    }
}
