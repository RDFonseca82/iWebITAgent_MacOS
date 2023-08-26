//
//  RunShellScript.swift
//  iWebITAgent
//
//  Created by Admin on 20/08/2023.
//

import Foundation

func shell(_ cmd: String) -> String {
    let pipe = Pipe()
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", String(format:"%@", cmd)]
    process.standardOutput = pipe
    let fileHandle = pipe.fileHandleForReading
    process.launch()
    return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8) ?? ""
}
