//
//  ImageManipulation.swift
//  iWebITSysTray
//
//  Created by Admin on 27/08/2023.
//

import SwiftUI

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

extension NSImage {
    func areEqual(_ image2: NSImage) -> Bool {
        if let data1 = self.dataRepresentation(), let data2 = image2.dataRepresentation() {
            return data1 == data2
        }
        return false
    }
    
    func dataRepresentation() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else {
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
}
