import AppKit
@testable import KeydexInfrastructure
import KeydexDomain
import Testing

@Suite("Converting AppKit modifier flags")
struct ModifierFlagsTests {
    @Test("Each AppKit flag maps to its modifier")
    func mapping() {
        #expect(ModifierSet([.command, .shift] as NSEvent.ModifierFlags) == [.command, .shift])
        #expect(ModifierSet([.control, .option, .function] as NSEvent.ModifierFlags) == [.control, .option, .function])
    }

    @Test("Caps Lock does not count: ⌘ with Caps Lock on is still ⌘ alone")
    func capsLockIgnored() {
        #expect(ModifierSet([.command, .capsLock] as NSEvent.ModifierFlags) == .command)
    }
}
