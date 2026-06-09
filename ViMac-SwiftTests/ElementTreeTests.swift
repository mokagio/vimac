//
//  ElementTreeTests.swift
//  VimacTests
//

import XCTest
import ApplicationServices
@testable import Vimac

// Behavioural coverage for `ElementTree`: what `query()` considers hintable and
// what `insert()` accepts. The tests drive the tree through its public API and
// assert the resulting selection, never the private classification methods — so
// the hintability rules can be refactored as long as the observable selection
// holds.
class ElementTreeTests: XCTestCase {

    // Each node needs a distinct `AXUIElement` to key on. A real `AXUIElement`
    // is an opaque reference; `AXUIElementCreateApplication` with a unique (and
    // entirely fictional) pid yields a distinct, hashable value we use purely as
    // a tree key — no Accessibility permission or live process is involved.
    private var nextPid: pid_t = 1000
    private func element(role: String, actions: [String] = []) -> Element {
        defer { nextPid += 1 }
        return Element(
            rawElement: AXUIElementCreateApplication(nextPid),
            frame: .zero,
            actions: actions,
            role: role
        )
    }

    private func rawElements(of elements: [Element]?) -> Set<AXUIElement> {
        Set((elements ?? []).map { $0.rawElement })
    }

    // MARK: - Hintability, observed through query()

    func test_window_root_is_not_hintable() {
        let tree = ElementTree()
        let window = element(role: "AXWindow", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))

        XCTAssertEqual(tree.query()?.count, 0)
    }

    func test_scroll_area_is_not_hintable() {
        let tree = ElementTree()
        let scrollArea = element(role: "AXScrollArea", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(scrollArea, parentId: nil))

        XCTAssertEqual(tree.query()?.count, 0)
    }

    func test_element_with_an_action_is_hintable() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let button = element(role: "AXButton", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(button, parentId: window.rawElement))

        XCTAssertEqual(rawElements(of: tree.query()), [button.rawElement])
    }

    func test_element_with_only_ignored_actions_is_not_hintable() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        // AXShowMenu/AXScrollToVisible/AXShowDefaultUI/AXShowAlternateUI are
        // ignored, so an element offering only those is not actionable.
        let decorative = element(role: "AXGroup", actions: ["AXShowMenu", "AXScrollToVisible"])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(decorative, parentId: window.rawElement))

        XCTAssertEqual(tree.query()?.count, 0)
    }

    func test_element_with_a_non_ignored_action_among_ignored_ones_is_hintable() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let menuButton = element(role: "AXButton", actions: ["AXShowMenu", "AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(menuButton, parentId: window.rawElement))

        XCTAssertEqual(rawElements(of: tree.query()), [menuButton.rawElement])
    }

    func test_non_row_element_without_actions_is_not_hintable() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let group = element(role: "AXGroup", actions: [])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(group, parentId: window.rawElement))

        XCTAssertEqual(tree.query()?.count, 0)
    }

    func test_row_without_hintable_children_is_hintable() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let row = element(role: "AXRow", actions: [])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(row, parentId: window.rawElement))

        XCTAssertEqual(rawElements(of: tree.query()), [row.rawElement])
    }

    func test_row_with_a_hintable_child_yields_the_child_not_the_row() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let row = element(role: "AXRow", actions: [])
        let button = element(role: "AXButton", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(row, parentId: window.rawElement))
        XCTAssertTrue(tree.insert(button, parentId: row.rawElement))

        // The row has a hintable descendant, so it stops being hintable itself;
        // only the button is selected.
        XCTAssertEqual(rawElements(of: tree.query()), [button.rawElement])
    }

    func test_query_traverses_deeply_nested_descendants() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let outer = element(role: "AXGroup", actions: [])
        let inner = element(role: "AXGroup", actions: [])
        let button = element(role: "AXButton", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(outer, parentId: window.rawElement))
        XCTAssertTrue(tree.insert(inner, parentId: outer.rawElement))
        XCTAssertTrue(tree.insert(button, parentId: inner.rawElement))

        XCTAssertEqual(rawElements(of: tree.query()), [button.rawElement])
    }

    func test_query_returns_every_hintable_sibling() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let first = element(role: "AXButton", actions: ["AXPress"])
        let second = element(role: "AXButton", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(first, parentId: window.rawElement))
        XCTAssertTrue(tree.insert(second, parentId: window.rawElement))

        XCTAssertEqual(rawElements(of: tree.query()), [first.rawElement, second.rawElement])
    }

    func test_query_on_empty_tree_is_nil() {
        XCTAssertNil(ElementTree().query())
    }

    // MARK: - insert() contract

    func test_first_root_is_accepted() {
        XCTAssertTrue(ElementTree().insert(element(role: "AXWindow"), parentId: nil))
    }

    func test_second_root_is_rejected() {
        let tree = ElementTree()
        XCTAssertTrue(tree.insert(element(role: "AXWindow"), parentId: nil))
        XCTAssertFalse(tree.insert(element(role: "AXWindow"), parentId: nil))
    }

    func test_inserting_the_same_element_twice_is_rejected() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let button = element(role: "AXButton", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))
        XCTAssertTrue(tree.insert(button, parentId: window.rawElement))
        XCTAssertFalse(tree.insert(button, parentId: window.rawElement))
    }

    func test_inserting_a_child_under_an_unknown_parent_is_rejected() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let orphanParent = element(role: "AXGroup")
        let child = element(role: "AXButton", actions: ["AXPress"])
        XCTAssertTrue(tree.insert(window, parentId: nil))

        XCTAssertFalse(tree.insert(child, parentId: orphanParent.rawElement))
    }
}
