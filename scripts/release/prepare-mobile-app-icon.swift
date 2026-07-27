#!/usr/bin/env swift

import CoreGraphics
import Darwin
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum AppIconError: LocalizedError {
    case usage
    case unreadableSource(String)
    case contextCreation
    case imageCreation
    case destinationCreation(String)
    case pngEncoding

    var errorDescription: String? {
        switch self {
        case .usage:
            return "Usage: prepare-mobile-app-icon.swift SOURCE_PNG OUTPUT_PNG"
        case let .unreadableSource(path):
            return "Could not read source app icon: \(path)"
        case .contextCreation:
            return "Could not create the opaque RGB bitmap context."
        case .imageCreation:
            return "Could not create the flattened app icon image."
        case let .destinationCreation(path):
            return "Could not create the output PNG destination: \(path)"
        case .pngEncoding:
            return "Could not encode the opaque app icon as PNG."
        }
    }
}

func prepareAppIcon(sourcePath: String, outputPath: String) throws {
    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard
        let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
        let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
        throw AppIconError.unreadableSource(sourcePath)
    }

    let pixelSize = 1024
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
    guard let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: pixelSize * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        throw AppIconError.contextCreation
    }

    let canvas = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(canvas)
    context.interpolationQuality = .high
    context.draw(sourceImage, in: canvas)

    guard let flattenedImage = context.makeImage() else {
        throw AppIconError.imageCreation
    }

    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw AppIconError.destinationCreation(outputPath)
    }

    CGImageDestinationAddImage(destination, flattenedImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw AppIconError.pngEncoding
    }
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw AppIconError.usage
    }
    try prepareAppIcon(
        sourcePath: CommandLine.arguments[1],
        outputPath: CommandLine.arguments[2]
    )
} catch {
    let message = "prepare-mobile-app-icon: \(error.localizedDescription)\n"
    FileHandle.standardError.write(Data(message.utf8))
    exit(EXIT_FAILURE)
}
