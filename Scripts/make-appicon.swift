#!/usr/bin/env swift
//
// Generates the 1024x1024 app icon into the asset catalog.
//
//   swift Scripts/make-appicon.swift App/Daystar/Assets.xcassets/AppIcon.appiconset/icon-1024.png
//
// Drawn in code rather than checked in as a binary so the icon stays reviewable in diffs and
// the build has no dependency on an external image editor.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side = 1024
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "App/Daystar/Assets.xcassets/AppIcon.appiconset/icon-1024.png"

guard let context = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("make-appicon: could not create bitmap context\n".utf8))
    exit(1)
}

let size = CGFloat(side)
let center = CGPoint(x: size / 2, y: size / 2)

func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// Deep sky backdrop, brightest at the horizon behind the sun.
let skyColors = [
    color(0.07, 0.09, 0.20),
    color(0.24, 0.13, 0.32),
    color(0.62, 0.24, 0.28)
] as CFArray
if let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: skyColors, locations: [0.0, 0.55, 1.0]) {
    context.drawLinearGradient(
        sky,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: 0, y: 0),
        options: []
    )
}

// Corona: a soft glow that falls off well before the icon edge.
let coronaColors = [
    color(1.00, 0.85, 0.42, 0.85),
    color(1.00, 0.60, 0.20, 0.35),
    color(1.00, 0.45, 0.15, 0.0)
] as CFArray
if let corona = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: coronaColors, locations: [0.0, 0.45, 1.0]) {
    context.drawRadialGradient(
        corona,
        startCenter: center, startRadius: size * 0.10,
        endCenter: center, endRadius: size * 0.46,
        options: []
    )
}

// Rays, tapering outward from the disc.
context.saveGState()
let rayCount = 12
let innerRadius = size * 0.30
let outerRadius = size * 0.44
for index in 0..<rayCount {
    let angle = (Double(index) / Double(rayCount)) * 2 * .pi + .pi / Double(rayCount)
    let halfWidth = 0.020 * .pi
    let path = CGMutablePath()
    path.move(to: CGPoint(
        x: center.x + cos(angle - halfWidth) * innerRadius,
        y: center.y + sin(angle - halfWidth) * innerRadius
    ))
    path.addLine(to: CGPoint(
        x: center.x + cos(angle + halfWidth) * innerRadius,
        y: center.y + sin(angle + halfWidth) * innerRadius
    ))
    path.addLine(to: CGPoint(x: center.x + cos(angle) * outerRadius, y: center.y + sin(angle) * outerRadius))
    path.closeSubpath()
    context.addPath(path)
    context.setFillColor(color(1.00, 0.86, 0.48, 0.9))
    context.fillPath()
}
context.restoreGState()

// Solar disc.
let discColors = [
    color(1.00, 0.98, 0.86),
    color(1.00, 0.83, 0.34),
    color(0.99, 0.60, 0.18)
] as CFArray
if let disc = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: discColors, locations: [0.0, 0.55, 1.0]) {
    context.saveGState()
    context.addEllipse(in: CGRect(
        x: center.x - size * 0.26,
        y: center.y - size * 0.26,
        width: size * 0.52,
        height: size * 0.52
    ))
    context.clip()
    context.drawRadialGradient(
        disc,
        startCenter: CGPoint(x: center.x - size * 0.06, y: center.y + size * 0.08), startRadius: 0,
        endCenter: center, endRadius: size * 0.30,
        options: [.drawsAfterEndLocation]
    )
    context.restoreGState()
}

guard let image = context.makeImage() else {
    FileHandle.standardError.write(Data("make-appicon: could not render image\n".utf8))
    exit(1)
}

let url = URL(fileURLWithPath: outputPath)
try? FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    FileHandle.standardError.write(Data("make-appicon: could not open \(outputPath) for writing\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("make-appicon: could not write \(outputPath)\n".utf8))
    exit(1)
}

print("make-appicon: wrote \(outputPath) (\(side)x\(side))")
