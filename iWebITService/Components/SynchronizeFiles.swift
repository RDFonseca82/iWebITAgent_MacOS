//
//  SynchronizeFiles.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation
import AppKit


func synchronizeFiles() {
    reportAgentActivity(id: "files", name: "Sincronização de ficheiros", status: "running")
    var filesToSync = [
        FileSyncModel(
            fileName: "logo-on.jpg",
            jsonCorresponding: .logoOn,
            isImage: true,
            size: CGSize(width: 18, height: 18)),
        FileSyncModel(
            fileName: "logo-off.jpg",
            jsonCorresponding: .logoOff,
            isImage: true,
            size: CGSize(width: 18, height: 18)),
    ]
    
    getFileLinks(filesToSync: &filesToSync)
    
    downloadFiles(filesToSync: &filesToSync)
    
    saveFiles(filesToSync: filesToSync)
    reportAgentActivity(id: "files", name: "Sincronização de ficheiros", status: "completed")
}


func getFileLinks(filesToSync: inout [FileSyncModel]) {
    log("GETTING NEEDED FILE LINKS")
    
    doUntil({
        ensureUserLoggedIn()
        let companyInfo = try GetCompanyDataService.shared.getCompany()
        
        for i in filesToSync.indices {
            filesToSync[i].link = companyInfo.getFileSyncCorrespondingLink(corresponding: filesToSync[i].jsonCorresponding)
        }
        
        return false
    }, 60)
}


func downloadFiles(filesToSync: inout [FileSyncModel]) {
    for i in filesToSync.indices {
        guard let link = filesToSync[i].link else {
            log("LINK IS NULL: \(filesToSync[i].jsonCorresponding)", important: true)
            continue
        }
        
        log("DOWNLOADING: \(link)")
        doUntil({
            filesToSync[i].fileData = try NetworkingManager.download(url: link)
            
            return false
        }, 60)
    }
}

func saveFiles(filesToSync: [FileSyncModel]) {
    guard let appSupportFolder = FilesManager.shared.getApplicationSupportDirectory() else {
        log("APP SUPPORT DIR IS NULL", important: true)
        return
    }
    
    let fileManager = FileManager.default
    
    for fileToSync in filesToSync {
        log("SAVING: \(fileToSync.fileName)")
        
        guard var fileData = fileToSync.fileData else {
            log("FILE \(fileToSync.fileName) HAS NO DATA, SKIPING", important: true)
            continue
        }
        
        if fileToSync.isImage, let newSize = fileToSync.size {
            if let image = NSImage(data: fileData),
               let resizedData = image.resized(newSize: newSize).dataRepresentation() {
                fileData = resizedData
            }
            else {
                log("FAILED TO RESIZE IMAGE", important: true)
            }
        }
        
        if areFilesEqual(fileName: fileToSync.fileName, newData: fileData) {
            log("FILES ARE EQUAL, SKIPING")
            continue
        }
        
        let filePath = appSupportFolder.appendingPathComponent(fileToSync.fileName).path
        
        if fileManager.fileExists(atPath: filePath) {
            try? fileManager.removeItem(atPath: filePath)
        }
        
        fileManager.createFile(atPath: filePath, contents: fileData)
    }
}

func areFilesEqual(fileName: String, newData: Data) -> Bool {
    guard let appSupportFolder = FilesManager.shared.getApplicationSupportDirectory() else {
        log("APP SUPPORT DIR IS NULL", important: true)
        return false
    }
    
    let fileUrl = appSupportFolder.appendingPathComponent(fileName)
    
    if !FileManager.default.fileExists(atPath: fileUrl.path) {
        return false
    }
    
    guard let data1 = try? Data(contentsOf: fileUrl) else {
        return false
    }
    
    return data1 == newData
}

