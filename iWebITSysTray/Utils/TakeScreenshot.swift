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
        try convertImageToData(image: finalImage)!.write(to: fileUrl)
    }
    catch {print("error: \(error)")}
    
    return finalImage
}

func joinImages(image1: NSImage, image2: NSImage) -> NSImage {
    let newSize = NSSize(width: image1.size.width + image2.size.width,
                         height: max(image1.size.height, image2.size.height))
    
    let joinedImage = NSImage(size: newSize)
    joinedImage.lockFocus()
    
    image1.draw(at: .zero, from: CGRect(origin: .zero, size: image1.size), operation: .sourceOver, fraction: 1.0)
    image2.draw(at: NSPoint(x: image1.size.width, y: 0), from: CGRect(origin: .zero, size: image2.size), operation: .sourceOver, fraction: 1.0)
    
    joinedImage.unlockFocus()
    return joinedImage
}

func convertImageToData(image: NSImage) -> Data? {
    guard let tiffRepresentation = image.tiffRepresentation else {
        return nil
    }
    
    let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation)
    
    if let pngData = bitmapImageRep?.representation(using: .png, properties: [:]) {
        return pngData
    }
    
    if let jpegData = bitmapImageRep?.representation(using: .jpeg, properties: [:]) {
        return jpegData
    }
    
    return nil
}
