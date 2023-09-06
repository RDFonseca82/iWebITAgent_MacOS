//
//  FileSync.swift
//  iWebITService
//
//  Created by Admin on 06/09/2023.
//

import Foundation


struct FileSyncModel {
    let fileName: String
    var jsonCorresponding: FileSyncJsonCorresponding
    var link: String? = nil
    var fileData: Data? = nil
}

enum FileSyncJsonCorresponding {
    case logoOn, logoOff
}
