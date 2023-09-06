//
//  SynchronizeFiles.swift
//  iWebITService
//
//  Created by Admin on 31/08/2023.
//

import Foundation


func synchronizeFiles() {
    var filesToSync = [
        FileSyncModel(fileName: "logo-on.jpg", jsonCorresponding: .logoOn),
        FileSyncModel(fileName: "logo-off.jpg", jsonCorresponding: .logoOff),
    ]
    
    getFileLinks(filesToSync: &filesToSync)
    
    downloadFiles(filesToSync: &filesToSync)
    
    saveFiles(filesToSync: filesToSync)
}


func getFileLinks(filesToSync: inout [FileSyncModel]) {
    log("GETTING NEEDED FILE LINKS")
    
    doUntilWithReturn({
        ensureUserLoggedIn()
        let companyInfo = try GetCompanyDataService.shared.getCompany()
        
        for i in filesToSync.indices {
            filesToSync[i].link = companyInfo.getFileSyncCorrespondingLink(corresponding: filesToSync[i].jsonCorresponding)
        }
        
        return
    }, 60)
}


func downloadFiles(filesToSync: inout [FileSyncModel]) {
    for i in filesToSync.indices {
        guard let link = filesToSync[i].link else {
            log("LINK IS NULL: \(filesToSync[i].jsonCorresponding)")
            continue
        }
        
        log("DOWNLOADING: \(link)")
        doUntilWithReturn({
            filesToSync[i].fileData = try NetworkingManager.download(url: link)
            
            return
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
        
        guard let fileData = fileToSync.fileData else {
            log("FILE \(fileToSync.fileName) HAS NO DATA, SKIPING")
            continue
        }
        
        if areFilesEqual(file: fileToSync) {
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

func areFilesEqual(file: FileSyncModel) -> Bool {
    guard let appSupportFolder = FilesManager.shared.getApplicationSupportDirectory() else {
        log("APP SUPPORT DIR IS NULL", important: true)
        return false
    }
    
    let fileUrl = appSupportFolder.appendingPathComponent(file.fileName)
    
    if !FileManager.default.fileExists(atPath: fileUrl.path) {
        return false
    }
    
    guard let data1 = try? Data(contentsOf: fileUrl) else {
        return false
    }
    
    
    let data2 = file.fileData!
    
    return data1 == data2
}
