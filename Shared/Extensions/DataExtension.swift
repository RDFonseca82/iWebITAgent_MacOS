//
//  DataExtension.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 25/08/2023.
//

import Foundation


public extension Data {

    mutating func append(
        _ string: String,
        encoding: String.Encoding = .utf8
    ) {
        guard let data = string.data(using: encoding) else {
            return
        }
        append(data)
    }
}
