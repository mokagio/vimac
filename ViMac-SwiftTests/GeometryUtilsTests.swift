//
//  GeometryUtilsTests.swift
//  VimacTests
//

import Cocoa
import Testing
@testable import Vimac

@Suite("Geometry utils")
struct GeometryUtilsTests {
    @Test("The centre of a rect at the origin is half its size")
    func centerOfOriginRect() {
        #expect(GeometryUtils.center(NSRect(x: 0, y: 0, width: 100, height: 50)) == NSPoint(x: 50, y: 25))
    }

    @Test("The centre of an offset rect moves with it")
    func centerOfOffsetRect() {
        #expect(GeometryUtils.center(NSRect(x: 10, y: 20, width: 100, height: 50)) == NSPoint(x: 60, y: 45))
    }

    @Test("An offset that fits is applied inwards from the top right")
    func topRightCorner() {
        let rect = NSRect(x: 0, y: 0, width: 100, height: 50)

        #expect(GeometryUtils.corner(rect, top: true, right: true, offset: 10) == NSPoint(x: 90, y: 40))
    }

    @Test("An offset that fits is applied inwards from the bottom left")
    func bottomLeftCorner() {
        let rect = NSRect(x: 0, y: 0, width: 100, height: 50)

        #expect(GeometryUtils.corner(rect, top: false, right: false, offset: 5) == NSPoint(x: 5, y: 5))
    }

    @Test("An offset larger than the rect collapses to zero")
    func offsetLargerThanRect() {
        let rect = NSRect(x: 0, y: 0, width: 10, height: 8)

        let topRight = GeometryUtils.corner(rect, top: true, right: true, offset: 20)

        #expect(topRight == NSPoint(x: 10, y: 8))
    }

    @Test("Each axis clamps its offset on its own")
    func axesClampIndependently() {
        // Wide-but-short rect: offset fits horizontally but not vertically.
        let rect = NSRect(x: 0, y: 0, width: 100, height: 5)

        let bottomLeft = GeometryUtils.corner(rect, top: false, right: false, offset: 10)

        #expect(bottomLeft == NSPoint(x: 10, y: 0))
    }

    @Test("Changing origin translates the point by the difference")
    func changeOrigin() {
        let point = GeometryUtils.changeOrigin(
            NSPoint(x: 10, y: 20),
            fromOrigin: NSPoint(x: 0, y: 0),
            toOrigin: NSPoint(x: 5, y: 5)
        )

        #expect(point == NSPoint(x: 5, y: 15))
    }

    @Test("Changing to the same origin leaves the point alone")
    func changeOriginToItself() {
        let point = GeometryUtils.changeOrigin(
            NSPoint(x: 7, y: 9),
            fromOrigin: NSPoint(x: 3, y: 3),
            toOrigin: NSPoint(x: 3, y: 3)
        )

        #expect(point == NSPoint(x: 7, y: 9))
    }
}
