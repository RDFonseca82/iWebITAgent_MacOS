//
//  Logger.swift
//  MODA
//
//  Created by Admin on 30/07/2023.
//

import Foundation


func log(_ text: String, important: Bool = false, callerName: String = #function, callerLineNum: Int = #line, retry: Bool = false, printOnly: Bool = false) {

    if printOnly {
        return
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
    let dateString = dateFormatter.string(from: Date())
    
    let line = "\(dateString): \(text)\(important ? " || \(callerName) -> \(callerLineNum)" : "")"
    
    var logCreateDate = Date(timeIntervalSinceReferenceDate: 0)

    if FileManager.default.fileExists(atPath: Constants.LOG_FILE.path) {
        if let content = FileManager.default.contents(atPath: Constants.LOG_FILE.path),
           let firstLine = String(data: content, encoding: .utf8)?.components(separatedBy: .newlines).first {
            if let parsedDate = dateFormatter.date(from: String(firstLine.prefix(19))) {
                logCreateDate = parsedDate
            }
        }
    }
    
    do {
        if !FileManager.default.fileExists(atPath: Constants.LOG_FILE.path) || Date().timeIntervalSince(logCreateDate) > 0 {
            if FileManager.default.fileExists(atPath: Constants.LOG_FILE.path) {
                if FileManager.default.fileExists(atPath: Constants.OLD_LOG_FILE.path) {
                    try FileManager.default.removeItem(atPath: Constants.OLD_LOG_FILE.path)
                }
                try FileManager.default.moveItem(atPath: Constants.LOG_FILE.path, toPath: Constants.OLD_LOG_FILE.path)
            }

            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let newLogHeader = dateFormatter.string(from: tomorrow) + ": Start Of Log File\n"

            try newLogHeader.write(toFile: Constants.LOG_FILE.path, atomically: true, encoding: .utf8)
        }
    } catch {
        print("ERROR MANAGING LOGS: \(error)")
        if !retry {
            holdToRetry(5, callerName: callerName, callerLineNum: callerLineNum, logSpecificRetry: true)
            log(text, important: important, callerName: callerName, callerLineNum: callerLineNum, retry: true)
        }
        return
    }

    do {
        try line.appendLineToURL(fileURL: Constants.LOG_FILE)
    } catch { print("ERROR WRITING LOG: \(error)")}
}
