//
//  ElementTreeTests.swift
//  VimacTests
//

import ApplicationServices
import Testing
@testable import Vimac

// Behavioural coverage for `ElementTree`: what `query()` considers hintable and
// what `insert()` accepts. The tests drive the tree through its public API and
// assert the resulting selection, never the private classification methods — so
// the hintability rules can be refactored as long as the observable selection
// holds.
@Suite("Element tree")
struct ElementTreeTests {
    // Each node needs a distinct `AXUIElement` to key on. A real `AXUIElement`
    // is an opaque reference; `AXUIElementCreateApplication` with a unique (and
    // entirely fictional) pid yields a distinct, hashable value we use purely as
    // a tree key — no Accessibility permission or live process is involved.
    private final class PidSequence {
        private var next: pid_t = 1000

        func take() -> pid_t {
            defer { next += 1 }
            return next
        }
    }

    private let pids = PidSequence()

    private func element(role: String, actions: [String] = []) -> Element {
        Element(
            rawElement: AXUIElementCreateApplication(pids.take()),
            frame: .zero,
            actions: actions,
            role: role
        )
    }

    private func rawElements(of elements: [Element]?) -> Set<AXUIElement> {
        Set((elements ?? []).map { $0.rawElement })
    }

    // MARK: - Hintability, observed through query()

    @Test("A window root is not hintable")
    func windowRoot() {
        let tree = ElementTree()
        let window = element(role: "AXWindow", actions: ["AXPress"])
        #expect(tree.insert(window, parentId: nil))

        #expect(tree.query()?.count == 0)
    }

    @Test("A scroll area is not hintable")
    func scrollArea() {
        let tree = ElementTree()
        let scrollArea = element(role: "AXScrollArea", actions: ["AXPress"])
        #expect(tree.insert(scrollArea, parentId: nil))

        #expect(tree.query()?.count == 0)
    }

    @Test("An element offering an action is hintable")
    func elementWithAction() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let button = element(role: "AXButton", actions: ["AXPress"])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(button, parentId: window.rawElement))

        #expect(rawElements(of: tree.query()) == [button.rawElement])
    }

    @Test("An element offering only ignored actions is not hintable")
    func elementWithOnlyIgnoredActions() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        // AXShowMenu/AXScrollToVisible/AXShowDefaultUI/AXShowAlternateUI are
        // ignored, so an element offering only those is not actionable.
        let decorative = element(role: "AXGroup", actions: ["AXShowMenu", "AXScrollToVisible"])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(decorative, parentId: window.rawElement))

        #expect(tree.query()?.count == 0)
    }

    @Test("One action that is not ignored is enough to be hintable")
    func elementWithOneMeaningfulAction() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let menuButton = element(role: "AXButton", actions: ["AXShowMenu", "AXPress"])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(menuButton, parentId: window.rawElement))

        #expect(rawElements(of: tree.query()) == [menuButton.rawElement])
    }

    @Test("An element with no actions is not hintable")
    func elementWithoutActions() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let group = element(role: "AXGroup", actions: [])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(group, parentId: window.rawElement))

        #expect(tree.query()?.count == 0)
    }

    @Test("A row with nothing hintable inside it is hintable itself")
    func rowWithoutHintableChildren() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let row = element(role: "AXRow", actions: [])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(row, parentId: window.rawElement))

        #expect(rawElements(of: tree.query()) == [row.rawElement])
    }

    @Test("A row holding something hintable yields the child, not the row")
    func rowWithHintableChild() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let row = element(role: "AXRow", actions: [])
        let button = element(role: "AXButton", actions: ["AXPress"])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(row, parentId: window.rawElement))
        #expect(tree.insert(button, parentId: row.rawElement))

        #expect(rawElements(of: tree.query()) == [button.rawElement])
    }

    @Test("Hintable elements are found however deeply they are nested")
    func deeplyNestedDescendant() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let outer = element(role: "AXGroup", actions: [])
        let inner = element(role: "AXGroup", actions: [])
        let button = element(role: "AXButton", actions: ["AXPress"])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(outer, parentId: window.rawElement))
        #expect(tree.insert(inner, parentId: outer.rawElement))
        #expect(tree.insert(button, parentId: inner.rawElement))

        #expect(rawElements(of: tree.query()) == [button.rawElement])
    }

    @Test("Every hintable sibling is returned")
    func hintableSiblings() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let first = element(role: "AXButton", actions: ["AXPress"])
        let second = element(role: "AXButton", actions: ["AXPress"])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(first, parentId: window.rawElement))
        #expect(tree.insert(second, parentId: window.rawElement))

        #expect(rawElements(of: tree.query()) == [first.rawElement, second.rawElement])
    }

    @Test("An empty tree has nothing to query")
    func emptyTree() {
        #expect(ElementTree().query() == nil)
    }

    // MARK: - insert() contract

    @Test("The first root is accepted")
    func firstRoot() {
        #expect(ElementTree().insert(element(role: "AXWindow"), parentId: nil))
    }

    @Test("A second root is rejected")
    func secondRoot() {
        let tree = ElementTree()

        #expect(tree.insert(element(role: "AXWindow"), parentId: nil))
        #expect(!tree.insert(element(role: "AXWindow"), parentId: nil))
    }

    @Test("Inserting the same element twice is rejected")
    func duplicateElement() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let button = element(role: "AXButton", actions: ["AXPress"])
        #expect(tree.insert(window, parentId: nil))
        #expect(tree.insert(button, parentId: window.rawElement))

        #expect(!tree.insert(button, parentId: window.rawElement))
    }

    @Test("A child of an unknown parent is rejected")
    func unknownParent() {
        let tree = ElementTree()
        let window = element(role: "AXWindow")
        let orphanParent = element(role: "AXGroup")
        let child = element(role: "AXButton", actions: ["AXPress"])
        #expect(tree.insert(window, parentId: nil))

        #expect(!tree.insert(child, parentId: orphanParent.rawElement))
    }
}
