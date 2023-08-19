//
//  DictionaryExtension.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 19/08/2023.
//

import Foundation


extension Dictionary {
    func toJsonString() throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { throw iWebITError.decodingError }
        return jsonString
    }
}
