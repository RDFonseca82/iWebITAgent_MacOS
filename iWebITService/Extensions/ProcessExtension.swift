//
//  ProcessExtension.swift
//  iWebITService
//
//  Created by Admin on 22/09/2023.
//

import Foundation

extension Process {
    func run(_ executable: String, _ arguments: String...) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            print("Error: \(error)")
            exit(1)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
    }
}
