//
//  TakeScreenshot.swift
//  iWebITSysTray
//
//  Created by Admin on 25/08/2023.
//

import SwiftUI
import AVFoundation


func takeScreenShot() -> NSImage? {
    
    var displayCount: UInt32 = 0;
    var result = CGGetActiveDisplayList(0, nil, &displayCount)
    if (result != CGError.success) {
        print("error: \(result)")
        return nil
    }
    let allocated = Int(displayCount)
    let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
    result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
    
    if (result != CGError.success) {
        print("error: \(result)")
        return nil
    }
    
    var displaysShots: [NSImage] = []
    
    for i in 1...displayCount {
        let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
        let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
        let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
        displaysShots.append(NSImage(data: jpegData)!)
    }
    
    var finalImage: NSImage = NSImage()
    
    for image in displaysShots {
        finalImage = joinImages(image1: finalImage, image2: image)
    }
    
    let fileUrl = FilesManager.shared.getApplicationSupportDirectory()!.appendingPathComponent("sct.jpg")
    
    do {
        try finalImage.dataRepresentation()!.write(to: fileUrl)
    }
    catch {print("error: \(error)")}
    
    return finalImage
}
