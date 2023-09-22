//
//  MemoryUsage.swift
//  iWebITService
//
//  Created by Admin on 22/09/2023.
//

import Foundation


func getMemoryUsage() {
    let f1 = 9.313225746154785e-10
    
    let pagesize = Int(shell("pagesize").replacingOccurrences(of: "\n", with: ""))
    
    let vm = shell("vm_stat")
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
    
    let memoryUsed = Double(appMemory + vmStats["Pages wired down"]! + vmStats["Pages occupied by compressor"]!) * f1
    print("Memory Used:\t\t\(memoryUsed) GB")
}
