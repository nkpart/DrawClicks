//
//  DrawClicksApp.swift
//  Shared
//
//  Created by Nick Partridge on 20/10/21.
//

import SwiftUI
import HotKey
import Foundation
import SwiftImage

fileprivate func publishPixel(_ pixel: RGBA<UInt8>) -> Bool {
    let fpixel = pixel.map { CGFloat($0) }
    // Treat the image content as a vector, if the magnitude
    // is less than 1, we publish this pixel
    let magnitude = sqrt(pow(fpixel.red / 255, 2) + pow(fpixel.green / 255, 2) + pow(fpixel.blue / 255,2))
    return magnitude < 1
}

func doThing(sourceImage: NSImage, scaleFactor: CGFloat) {
    print("doThing: \(scaleFactor)")
    let bigger = scaleFactor
    let source = CGEventSource.init(stateID: .hidSystemState)!
    let mouseStart = NSEvent.mouseLocation


    // Grr. Gotta flip the mouse y, which is weird because we are later using that y to generate
    // a click with the mouse? Why aren't they the same space?
    let screenRect = NSScreen.main!.frame
    let height = screenRect.size.height
    let position = CGPoint(x: mouseStart.x , y: height - mouseStart.y)

    let image = SwiftImage.Image<RGBA<UInt8>>(nsImage: sourceImage)
    for x in image.xRange {
        for y in image.yRange {
            let pixel = image.pixelAt(x: x, y: y)!
            if (publishPixel(pixel)) {
                doTap(source, CGPoint(x: position.x + CGFloat(x)*bigger, y: position.y + CGFloat(y)*bigger))
            }
        }
    }
}

func doTap(_ source: CGEventSource, _ position: CGPoint) {
    let eventDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: position , mouseButton: .left)
    let eventUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: position , mouseButton: .left)
    // Sleep a bit before every tap because it looks cool and we probably need to
    usleep(1000)
    eventDown?.post(tap: .cghidEventTap)
    // TODO: some drawing tools needed a sleep here too
    eventUp?.post(tap: .cghidEventTap)
}

@main
struct DrawClicksApp: App {
    var hotkeys: Array<HotKey> = []

    init() {
        let hotKey = HotKey(key: .one, modifiers: [.command, .option])
        hotKey.keyDownHandler = {
            if let i = pasteboardImage() {
                // TODO: Maybe sleep before starting the drawing?
                // Some drawing tools don't like the modifiers from activating the
                // hotkey applying to the clicks.
                doThing(sourceImage: i, scaleFactor: 1.0)
            }
        }
        let hotKey2 = HotKey(key: .two, modifiers: [.command, .option])
        hotKey2.keyDownHandler = {
            if let i = pasteboardImage() {
                doThing(sourceImage: i, scaleFactor: 2.0)
            }
        }
        let hotKey3 = HotKey(key: .zero, modifiers: [.command, .option])
        hotKey3.keyDownHandler = {
            if let i = pasteboardImage() {
                doThing(sourceImage: i, scaleFactor: 0.5)
            }
        }

        self.hotkeys.append(hotKey)
        self.hotkeys.append(hotKey2)
        self.hotkeys.append(hotKey3)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func pasteboardImage() -> NSImage? {
    let pb = NSPasteboard.general
    let type = NSPasteboard.PasteboardType.tiff
    guard let imgData = pb.data(forType: type) else { return nil }
    return NSImage(data: imgData)
}
