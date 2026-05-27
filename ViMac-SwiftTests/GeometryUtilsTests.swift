//
//  GeometryUtilsTests.swift
//  VimacTests
//

import XCTest
@testable import Vimac

class GeometryUtilsTests: XCTestCase {

    func test_center_of_origin_rect() {
        let center = GeometryUtils.center(NSRect(x: 0, y: 0, width: 100, height: 50))
        XCTAssertEqual(center, NSPoint(x: 50, y: 25))
    }

    func test_center_of_offset_rect() {
        let center = GeometryUtils.center(NSRect(x: 10, y: 20, width: 100, height: 50))
        XCTAssertEqual(center, NSPoint(x: 60, y: 45))
    }

    func test_corner_top_right_with_offset_within_bounds() {
        let rect = NSRect(x: 0, y: 0, width: 100, height: 50)
        let p = GeometryUtils.corner(rect, top: true, right: true, offset: 10)
        XCTAssertEqual(p, NSPoint(x: 90, y: 40))
    }

    func test_corner_bottom_left_with_offset_within_bounds() {
        let rect = NSRect(x: 0, y: 0, width: 100, height: 50)
        let p = GeometryUtils.corner(rect, top: false, right: false, offset: 5)
        XCTAssertEqual(p, NSPoint(x: 5, y: 5))
    }

    func test_corner_offset_collapses_to_zero_when_larger_than_dimension() {
        let rect = NSRect(x: 0, y: 0, width: 10, height: 8)
        let topRight = GeometryUtils.corner(rect, top: true, right: true, offset: 20)
        // x offset of 20 > width 10 → clamps to 0, so x = maxX - 0 = 10
        XCTAssertEqual(topRight.x, 10)
        // y offset of 20 > height 8 → clamps to 0, so y = maxY - 0 = 8
        XCTAssertEqual(topRight.y, 8)
    }

    func test_corner_axes_clamp_independently() {
        // Wide-but-short rect: offset fits horizontally but not vertically.
        let rect = NSRect(x: 0, y: 0, width: 100, height: 5)
        let bottomLeft = GeometryUtils.corner(rect, top: false, right: false, offset: 10)
        XCTAssertEqual(bottomLeft.x, 10) // applied
        XCTAssertEqual(bottomLeft.y, 0)  // clamped
    }

    func test_change_origin_translates_point() {
        let p = GeometryUtils.changeOrigin(
            NSPoint(x: 10, y: 20),
            fromOrigin: NSPoint(x: 0, y: 0),
            toOrigin: NSPoint(x: 5, y: 5)
        )
        XCTAssertEqual(p, NSPoint(x: 5, y: 15))
    }

    func test_change_origin_is_idempotent_when_origins_match() {
        let p = GeometryUtils.changeOrigin(
            NSPoint(x: 7, y: 9),
            fromOrigin: NSPoint(x: 3, y: 3),
            toOrigin: NSPoint(x: 3, y: 3)
        )
        XCTAssertEqual(p, NSPoint(x: 7, y: 9))
    }
}
