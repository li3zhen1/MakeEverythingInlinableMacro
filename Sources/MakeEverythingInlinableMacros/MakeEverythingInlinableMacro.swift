import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension VariableDeclSyntax {
    var containsAccessor: Bool {
        for binding in self.bindings {
            if binding.accessorBlock != nil {
                return true
            }
        }
        return false
    }
}

protocol HasAccessLevelModifier {
    var modifiers: DeclModifierListSyntax { get }
}

extension FunctionDeclSyntax: HasAccessLevelModifier { }
extension TypeAliasDeclSyntax: HasAccessLevelModifier { }
extension VariableDeclSyntax: HasAccessLevelModifier { }
extension StructDeclSyntax: HasAccessLevelModifier { }

enum AccessLevelModifier: Int, Comparable {

    case `private`
    case `fileprivate`

    case `internal`
    case `package`

    case `public`


    static func < (lhs: AccessLevelModifier, rhs: AccessLevelModifier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static func makeCanonical(from modifiers: DeclModifierListSyntax) -> AccessLevelModifier {
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public): return .public
            case .keyword(.package): return .package
            case .keyword(.internal): return .internal
            case .keyword(.fileprivate): return .fileprivate
            case .keyword(.private): return .private
            default: break
            }
        }
        return .internal
    }
}

public struct MakeEverythingInlinableMacro: MemberAttributeMacro {
    
    enum AddedAttribute {
        case inlinable
        case usableFromInline
        case makeEverythingInliable
        
        func makeAttributeSyntax() -> SwiftSyntax.AttributeSyntax {
            switch self {
            case .inlinable:
                return .init(stringLiteral: "@inlinable")
            case .usableFromInline:
                return .init(stringLiteral: "@usableFromInline")
            case .makeEverythingInliable:
                return .init(stringLiteral: "@MakeEverythingInlinable")
            }
        }
        
        static func makeFromStoredPropertyOrType(_ syntax: some HasAccessLevelModifier) -> Self? {
            // FIXME: - init accessor is always <= internal
            let accessLevel = AccessLevelModifier.makeCanonical(from: syntax.modifiers)
            if accessLevel <= .fileprivate || accessLevel == .public {
                return nil
            }
            return .usableFromInline
        }
        
        static func makeFromFunctionDeclOrAccessors(_ syntax: some HasAccessLevelModifier) -> Self? {
            let accessLevel = AccessLevelModifier.makeCanonical(from: syntax.modifiers)
            if accessLevel <= .fileprivate {
                return nil
            }
            return .inlinable
        }
    }
    
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        
        var resultAttribute: [AddedAttribute?] = []
        
        if let variableDecl = member.as(VariableDeclSyntax.self) {
            if variableDecl.containsAccessor {
                resultAttribute = [.makeFromFunctionDeclOrAccessors(variableDecl)]
            } else {
                resultAttribute = [.makeFromStoredPropertyOrType(variableDecl)]
            }
        } else if let funcDecl = member.as(FunctionDeclSyntax.self) {
            resultAttribute = [.makeFromFunctionDeclOrAccessors(funcDecl)]
        } else if let typealiasDecl = member.as(TypeAliasDeclSyntax.self) {
            resultAttribute = [.makeFromStoredPropertyOrType(typealiasDecl)]
        } else if let structDecl = member.as(StructDeclSyntax.self) {
            resultAttribute = [
//                .makeEverythingInliable // recursive expansion
                .makeFromStoredPropertyOrType(structDecl),
            ]
        }
        
        return resultAttribute.compactMap { $0?.makeAttributeSyntax() }
    }
}

@main
struct MakeEverythingInlinablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MakeEverythingInlinableMacro.self,
    ]
}
