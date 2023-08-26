//
//  SendScreenshotDataService.swift
//  MODA
//
//  Created by Admin on 04/03/2023.
//

import SwiftUI
import Combine


class SendScreenshotDataService {
    static let shared = SendScreenshotDataService()
    
    func sendScreenshot(screenshot: NSImage) async throws {
        do {
            var multipart = MultipartRequest()
            multipart.add(key: "uniqueId", value: AppInfo.uniqueid)
            multipart.add(key: "File", fileName: "sct.jpg", fileMimeType: "image/jpg", fileData: convertImageToData(image: screenshot)!)
            
            try await NetworkingManager.send(url: Constants.postScreenshotUrl+"?UniqueId=\(AppInfo.uniqueid)", multipart: multipart)
        } catch {
            throw iWebITError.httpError
        }
    }
}
