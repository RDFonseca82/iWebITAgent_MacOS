#!/usr/bin/env swift

import AppKit
import Darwin
import Foundation

enum AppIconError: LocalizedError {
    case usage
    case unreadableSource(String)
    case bitmapCreation
    case contextCreation
    case pngEncoding

    var errorDescription: String? {
        switch self {
        case .usage:
            return "Usage: prepare-mobile-app-icon.swift SOURCE_PNG OUTPUT_PNG"
        case let .unreadableSource(path):
            return "Could not read source app icon: \(path)"
        case .bitmapCreation:
            return "Could not create an opaque 1024x1024 RGB bitmap."
        case .contextCreation:
            return "Could not create the bitmap graphics context."
        case .pngEncoding:
            return "Could not encode the opaque app icon as PNG."
        }
    }
}

func prepareAppIcon(sourcePath: String, outputPath: String) throws {
    guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
        throw AppIconError.unreadableSource(sourcePath)
    }

    let pixelSize = 1024
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw AppIconError.bitmapCreation
    }

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw AppIconError.contextCreation
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let canvas = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    NSColor.white.setFill()
    NSBezierPath(rect: canvas).fill()
    sourceImage.draw(
        in: canvas,
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw AppIconError.pngEncoding
    }

    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try pngData.write(to: outputURL, options: .atomic)
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
