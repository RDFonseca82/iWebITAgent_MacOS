//
//  NSImageExt.swift
//  iWebITService
//
//  Created by Admin on 27/10/2023.
//

import AppKit


extension NSImage {
    func resized(newSize: CGSize) -> NSImage {
        let ratioX = newSize.width / size.width
        let ratioY = newSize.height / size.height
        let ratio = ratioX < ratioY ? ratioX : ratioY
        let newHeight = size.height * ratio
        let newWidth = size.width * ratio
        let newSize = NSSize(width: newWidth, height: newHeight)
        let image = NSImage(size: newSize)
        image.lockFocus() // this will be deprecated
        let context = NSGraphicsContext.current
        context!.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: newSize), from: NSZeroRect, operation: .copy, fraction: 1)
        image.unlockFocus()
        return image
    }
}

// >= macOS 13.0
//func resizedMaintainingAspectRatio(width: CGFloat, height: CGFloat) -> NSImage {
//    let ratioX = width / size.width
//    let ratioY = height / size.height
//    let ratio = ratioX < ratioY ? ratioX : ratioY
//    let newHeight = size.height * ratio
//    let newWidth = size.width * ratio
//    let newSize = NSSize(width: newWidth, height: newHeight)
//    let image = NSImage(size: newSize, flipped: false) { destRect in
//        NSGraphicsContext.current!.imageInterpolation = .high
//        self.draw(in: destRect, from: NSZeroRect, operation: .copy, fraction: 1)
//        return true
//    }
//    return image
//}
