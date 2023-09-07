//
//  TaskExtension.swift
//  iWebITService
//
//  Created by Admin on 01/09/2023.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Int) async throws {
        try await sleep(nanoseconds: UInt64(seconds*1_000_000_000))
    }
}
