//
//  RunShellScript.swift
//  iWebITAgent
//
//  Created by Admin on 20/08/2023.
//

import Foundation

@discardableResult func shell(_ cmd: String) -> Data {
    let pipe = Pipe()
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", String(format:"%@", cmd)]
    process.standardOutput = pipe
    let fileHandle = pipe.fileHandleForReading
    process.launch()
    return fileHandle.readDataToEndOfFile()
}
