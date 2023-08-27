//
//  service.swift
//  iWebITService
//
//  Created by Admin on 26/08/2023.
//

import Foundation

@main
struct Service {
    static func main() async throws {
        AppInfo.companyname = "0"
        while(true) {
            AppInfo.companyname = String((Int(AppInfo.companyname) ?? 0)+1)
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
