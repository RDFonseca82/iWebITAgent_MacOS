//
//  FilesManager.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 18/08/2023.
//

import SwiftUI


class FilesManager {
    static let shared = FilesManager()
    
    private let fileManager = FileManager.default
    private let applicationFolderName = "com.rdfonseca.iWebITAgent"
    
    private init() {}
    
    func getApplicationSupportDirectory() -> URL? {
        guard let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .localDomainMask).first else {
            return nil
        }
        let appDirectory = appSupportDir.appendingPathComponent(applicationFolderName)
        if !fileManager.dirExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(atPath: appDirectory.path, withIntermediateDirectories: true)
        }
        return appDirectory
    }
    
    func saveFile(filename: String, content: String) {
        if let appDirectory = getApplicationSupportDirectory() {
            let filePath = appDirectory.appendingPathComponent(filename)
            do {
                try content.write(to: filePath, atomically: true, encoding: .utf8)
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
    
    func loadFile(filename: String) -> String? {
        if let appDirectory = getApplicationSupportDirectory() {
            let filePath = appDirectory.appendingPathComponent(filename)
            do {
                let content = try String(contentsOf: filePath, encoding: .utf8)
                return content
            } catch {
                print("Error loading file: \(error)")
            }
        }
        return nil
    }
    
    func saveImage(filename: String, content: NSImage) {
        if let appDirectory = getApplicationSupportDirectory() {
            let filePath = appDirectory.appendingPathComponent(filename)
            do {
                let imageData = content.dataRepresentation()!
                try imageData.write(to: filePath)
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
    
    func loadImage(filename: String) -> NSImage? {
        if let appDirectory = getApplicationSupportDirectory() {
            let filePath = appDirectory.appendingPathComponent(filename)
            do {
                let imageData = try Data(contentsOf: filePath)
                return NSImage(data: imageData)
            } catch { }
        }
        return nil
    }
    
    func createFileIfNeeded(filename: String, content: String) throws {
        if let appDirectory = getApplicationSupportDirectory() {
            let filePath = appDirectory.appendingPathComponent(filename).path
            if !fileManager.fileExists(atPath: filePath) {
                try content.write(toFile: filePath, atomically: false, encoding: .utf8)
            }
        }
    }
}

extension FileManager {
    func dirExists(atPath: String) -> Bool {
        var isDirectory : ObjCBool = true
        let exists = FileManager.default.fileExists(atPath: atPath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
