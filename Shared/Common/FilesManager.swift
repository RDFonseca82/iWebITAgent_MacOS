//
//  FilesManager.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 18/08/2023.
//

import Foundation


class FilesManager {
    static let shared = FilesManager()
    
    private let fileManager = FileManager.default
    private let applicationFolderName = Bundle.main.bundleIdentifier!
    
    private init() {}
    
    func getApplicationSupportDirectory() -> URL? {
        guard let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appDirectory = appSupportDir.appendingPathComponent(applicationFolderName)
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
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
    
    func createIfNeeded(filename: String, content: String) {
        if let appDirectory = getApplicationSupportDirectory() {
            let filePath = appDirectory.appendingPathComponent(filename).path
            
            if !fileManager.fileExists(atPath: filePath) {
                fileManager.createFile(atPath: filePath, contents: nil)
                saveFile(filename: filename, content: content)
            }
        }
    }
}
