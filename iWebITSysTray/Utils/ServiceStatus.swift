//
//  ServiceStatus.swift
//  iWebITSysTray
//
//  Created by Admin on 26/08/2023.
//

import SwiftUI


func isServiceRunning() -> Bool {
    var isRunning = false
    let process = Process()
    process.launchPath = "/bin/ps"
    process.arguments = ["axc", "-o", "comm"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        if output.contains("iWebITService") {
            isRunning = true
        }
    }
    process.waitUntilExit()
    return isRunning
}
