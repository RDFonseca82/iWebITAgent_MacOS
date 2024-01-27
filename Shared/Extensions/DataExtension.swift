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
    
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
            
        } else {
            try write(to: fileURL, options: .atomic)
            
        }
    }
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
