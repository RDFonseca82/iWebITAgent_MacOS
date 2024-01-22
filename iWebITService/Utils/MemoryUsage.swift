//
//  MemoryUsage.swift
//  iWebITService
//
//  Created by Admin on 22/09/2023.
//

import Foundation


func getMemoryUsage() -> Int {
    let pagesize = Int(String(data: shell("pagesize"), encoding: .utf8)!.replacingOccurrences(of: "\n", with: ""))
    
    let vm = String(data: shell("vm_stat"), encoding: .utf8)!
    let vmLines = vm.components(separatedBy: "\n")
    let vmStats = Dictionary(uniqueKeysWithValues: vmLines[1..<(vmLines.count - 2)].map { line in
        let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
        let key = components[0]
        
        let value = Int(
            components[1]
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ".", with: ""))! * pagesize!
        return (key, value)
    })
    
    let appMemory = vmStats["Anonymous pages"]! - vmStats["Pages purgeable"]!
    
    return appMemory + vmStats["Pages wired down"]! + vmStats["Pages occupied by compressor"]!
}
