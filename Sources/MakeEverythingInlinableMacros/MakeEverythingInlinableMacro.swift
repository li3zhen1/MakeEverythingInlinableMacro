import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

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

public struct MakeEverythingInlinableMacro: MemberAttributeMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
    
    
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
            for modifier in syntax.modifiers {
                switch modifier.name.tokenKind {
                case .keyword(.package): fallthrough
                case .keyword(.internal): return .usableFromInline
                    
                case .keyword(.public): fallthrough
                case .keyword(.fileprivate): fallthrough
                case .keyword(.private): return nil
                    
                default:
                    break
                }
            }
            return .usableFromInline
        }
        
        static func makeFromFunctionDeclOrAccessors(_ syntax: some HasAccessLevelModifier) -> Self? {
            for modifier in syntax.modifiers {
                switch modifier.name.tokenKind {
                case .keyword(.package): fallthrough
                case .keyword(.internal): fallthrough
                case .keyword(.public): return .inlinable
                    
                case .keyword(.fileprivate): fallthrough
                case .keyword(.private): return nil
                    
                default:
                    break
                }
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
                .makeEverythingInliable,
                .makeFromStoredPropertyOrType(structDecl),
            ]
        }
        
        return resultAttribute.compactMap { $0?.makeAttributeSyntax() }
    }
}

@main
struct MakeEverythingInlinablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        MakeEverythingInlinableMacro.self,
    ]
}
