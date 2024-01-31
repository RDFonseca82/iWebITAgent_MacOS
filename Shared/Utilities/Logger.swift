//
//  Logger.swift
//  MODA
//
//  Created by Admin on 30/07/2023.
//

import Foundation

#if DEBUG
let DEBUG = true
#else
let DEBUG = false
#endif


func log(_ text: String, important: Bool = false, callerName: String = #function, callerLineNum: Int = #line, retry: Bool = false, printOnly: Bool = false) {

    if AppInfo.verbose == "0" && !important {
        return
    }
    
    if AppInfo.verbose == "1" || DEBUG {
        print(text)
    }
    
    if printOnly {
        return
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
    let dateString = dateFormatter.string(from: Date())
    
    let line = "\(dateString): \(text)\(important ? " || \(callerName) -> \(callerLineNum)" : "")"
    
    var logCreateDate = Date(timeIntervalSinceReferenceDate: 0)
    
    let logPath = Constants.shared.LOG_FILE
    let oldLogPath = Constants.shared.OLD_LOG_FILE

    if FileManager.default.fileExists(atPath: logPath.path) {
        if let content = FileManager.default.contents(atPath: logPath.path),
           let firstLine = content.toString()?.components(separatedBy: .newlines).first {
            if let parsedDate = dateFormatter.date(from: String(firstLine.prefix(19))) {
                logCreateDate = parsedDate
            }
        }
    }
    
    do {
        if !FileManager.default.fileExists(atPath: logPath.path) || Date().timeIntervalSince(logCreateDate) > 0 {
            if FileManager.default.fileExists(atPath: logPath.path) {
                if FileManager.default.fileExists(atPath: oldLogPath.path) {
                    try FileManager.default.removeItem(atPath: oldLogPath.path)
                }
                try FileManager.default.moveItem(atPath: logPath.path, toPath: oldLogPath.path)
            }

            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let newLogHeader = dateFormatter.string(from: tomorrow) + ": Start Of Log File\n"

            try newLogHeader.write(toFile: logPath.path, atomically: true, encoding: .utf8)
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
        try line.appendLineToURL(fileURL: logPath)
    } catch { print("ERROR WRITING LOG: \(error)")}
}
