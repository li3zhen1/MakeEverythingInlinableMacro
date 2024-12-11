import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MakeEverythingInlinableMacros)
import MakeEverythingInlinableMacros

let testMacros: [String: Macro.Type] = [
    "MakeEverythingInlinable": MakeEverythingInlinableMacro.self
]
#endif

final class MakeEverythingInlinableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(MakeEverythingInlinableMacros)
        assertMacroExpansion(
            """
            @usableFromInline
            @MakeEverythingInlinable 
            struct Foo {
                private var foo: Int
                var bar: Int
                public var baz: Int {
                    bar + 1
                }
            }
            """,
            expandedSource: """
            @usableFromInline
            
            struct Foo {
                private var foo: Int
                @usableFromInline
                var bar: Int
                @inlinable
                public var baz: Int {
                    bar + 1
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
