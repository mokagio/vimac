import Testing
@testable import Vimac

@Suite("Scroll keys")
struct ScrollKeysTests {
    @Test("4, 6, or 8 distinct sequences are accepted", arguments: [
        "h,j,k,l",
        "h,j,k,l,d,u",
        "h,j,k,l,d,u,G,gg",
    ])
    func accepted(value: String) {
        #expect(ScrollKeys.problem(with: value) == nil)
    }

    @Test("Any other count is rejected", arguments: ["h", "h,j", "h,j,k,l,d", "h,j,k,l,d,u,G"])
    func wrongCount(value: String) {
        #expect(ScrollKeys.problem(with: value) == .wrongCount(value.components(separatedBy: ",").count))
    }

    @Test("A missing sequence is rejected, even though the count works out")
    func emptySequence() {
        #expect(ScrollKeys.problem(with: "h,,k,l") == .emptySequence)
    }

    @Test("Repeated sequences are named")
    func duplicates() {
        #expect(ScrollKeys.problem(with: "h,j,k,j") == .duplicateSequences(["j"]))
    }

    // MARK: - Binding generation

    private func keys(_ config: ScrollKeyConfig, for direction: ScrollDirection) -> Set<String> {
        Set(config.bindings.filter { $0.direction == direction }.map { String($0.keys) })
    }

    @Test("Four sequences give the four directions plus uppercase half-page bindings")
    func fourSequences() {
        let config = ScrollKeys.config(from: "a,b,c,d")

        #expect(config.bindings.count == 8)
        #expect(keys(config, for: .left) == ["a"])
        #expect(keys(config, for: .down) == ["b"])
        #expect(keys(config, for: .up) == ["c"])
        #expect(keys(config, for: .right) == ["d"])
        #expect(keys(config, for: .halfLeft) == ["A"])
        #expect(keys(config, for: .halfDown) == ["B"])
        #expect(keys(config, for: .halfUp) == ["C"])
        #expect(keys(config, for: .halfRight) == ["D"])
    }

    @Test("Six sequences add explicit half-page bindings alongside the uppercase ones")
    func sixSequences() {
        let config = ScrollKeys.config(from: "a,b,c,d,e,f")

        #expect(config.bindings.count == 10)
        #expect(keys(config, for: .halfDown) == ["B", "e"])
        #expect(keys(config, for: .halfUp) == ["C", "f"])
    }

    @Test("Eight sequences add jump-to-bottom and jump-to-top")
    func eightSequences() {
        let config = ScrollKeys.config(from: "a,b,c,d,e,f,g,hh")

        #expect(config.bindings.count == 12)
        #expect(keys(config, for: .bottom) == ["g"])
        #expect(keys(config, for: .top) == ["hh"])
    }

    @Test("An unusable value produces the default bindings rather than nonsense")
    func invalidFallsBackToDefault() {
        let config = ScrollKeys.config(from: "x,y")

        #expect(config.bindings.count == 12)
        #expect(keys(config, for: .left) == ["h"])
        #expect(keys(config, for: .bottom) == ["G"])
        #expect(keys(config, for: .top) == ["gg"])
    }

    @Test("Roles are assigned to sequences in reading order")
    func roleAssignments() {
        let assignments = ScrollKeys.roleAssignments(in: "a,b,c,d,e,f,g,hh")

        #expect(assignments.map(\.role) == ScrollKeys.roleNames)
        #expect(assignments.map(\.sequence) == ["a", "b", "c", "d", "e", "f", "g", "hh"])
    }

    @Test("Four sequences take only the first four roles")
    func partialRoleAssignments() {
        let assignments = ScrollKeys.roleAssignments(in: "a,b,c,d")

        #expect(assignments.map(\.role) == ["left", "down", "up", "right"])
    }
}

@Suite("Scroll sensitivity")
struct ScrollSensitivityTests {
    @Test("The whole 0 to 100 range is allowed", arguments: [0, 20, 100])
    func inRange(value: Int) {
        #expect(ScrollSensitivity.isValid(value))
    }

    @Test("Outside the range is not", arguments: [-1, 101])
    func outOfRange(value: Int) {
        #expect(!ScrollSensitivity.isValid(value))
    }
}
