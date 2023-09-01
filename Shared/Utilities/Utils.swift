//
//  Utils.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 30/08/2023.
//

import SwiftUI

func doUntil(_ action: @escaping () throws -> Bool,_ interval: Int, callerName: String = #function, callerLineNum: Int = #line) {
    var repeatAction = true

    while repeatAction {
        do {
            repeatAction = try action()
        } catch { }

        if !repeatAction {
            return
        }

        log("RETRYING IN \(interval)s", important: true, callerName: callerName, callerLineNum: callerLineNum)
        Thread.sleep(forTimeInterval: TimeInterval(interval))
    }
}
func doUntilAsync(_ action: @escaping () async throws -> Bool,_ interval: Int, callerName: String = #function, callerLineNum: Int = #line) async {
    var repeatAction = true

    while repeatAction {
        do {
            repeatAction = try await action()
        } catch { }

        if !repeatAction {
            return
        }

        log("RETRYING IN \(interval)s", important: true, callerName: callerName, callerLineNum: callerLineNum)
        try? await Task.sleep(seconds: interval)
    }
}

func doUntilWithReturn(action: @escaping () throws -> Resource, interval: Int) -> Resource {

    while true {
        do {
            return try action()
        } catch { }

        Thread.sleep(forTimeInterval: TimeInterval(interval))
    }
}

func formatDateStr(_ date: String, option: Int = 0) -> String {
    var option = option
    if date.isEmpty { option = -1 }

    if option == 0 {
        // 20210418201212.000000+000
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        if let parsedDate = formatter.date(from: String(date.prefix(14))) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: parsedDate)
        }
    } else if option == 1 {
        // For timestamps in Security
        // Sat, 10 Dec 2022 12:14:29 GMT
        let dateString = String(date.dropFirst(5).dropLast(4))
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy HH:mm:ss"
        if let parsedDate = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: parsedDate)
        }
    } else if option == 2 {
        // For install dates in Product, etc...
        // 20211224
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        if let parsedDate = formatter.date(from: date) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: parsedDate)
        }
    }

    return "1900-1-1 00:00:00"
}

func holdToRetry(_ interval: Int, callerName: String = #function, callerLineNum: Int = #line, logSpecificRetry: Bool = false) {
    log("RETRYING IN \(interval)", important: false, callerName: callerName, callerLineNum: callerLineNum, retry: logSpecificRetry)
    Thread.sleep(forTimeInterval: TimeInterval(interval))
}
