import Core
import Utils
import Foundation

/// A collection of basic blocks representing a lowered function.
public struct Function {

  /// A collection of blocks with stable identities.
  public typealias Blocks = DoublyLinkedList<Block>

  /// The profile of a IR function input.
  public typealias Input = (convention: AccessEffect, type: LoweredType)

  /// The mangled name of the function.
  public let name: String

  /// The debug name of the function, if any.
  public let debugName: String?

  /// The position in source code at which the function is anchored.
  public let anchor: SourcePosition

  /// The linkage of the function.
  public let linkage: Linkage

  /// The types of the function's parameters.
  public let inputs: [Input]

  /// The type of the function's output.
  public let output: LoweredType

  /// The blocks in the function.
  public private(set) var blocks: Blocks

  /// The entry of the function.
  public var entry: Block? { blocks.first }

  /// Accesses the basic block at `address`.
  ///
  /// - Requires: `address` must be a valid address in `self`.
  public subscript(_ address: Blocks.Address) -> Block {
    get { blocks[address] }
    _modify { yield &blocks[address] }
  }

  /// Appends to `self` a basic block accepting given `parameters` and returns its address.
  ///
  /// The new block will become the function's entry if `self` contains no block before
  /// `appendBlock` is called.
  mutating func appendBlock(taking parameters: [LoweredType]) -> Blocks.Address {
    blocks.append(Block(inputs: parameters))
  }

  /// Returns the control flow graph of `self`.
  func cfg() -> ControlFlowGraph {
    var result = ControlFlowGraph()

    for source in blocks.indices {
      switch blocks[source.address].instructions.last {
      case let s as BranchInstruction:
        result.define(source.address, predecessorOf: s.target.address)
      case let s as CondBranchInstruction:
        result.define(source.address, predecessorOf: s.targetIfTrue.address)
        result.define(source.address, predecessorOf: s.targetIfFalse.address)
      case let s as StaticBranchInstruction:
        result.define(source.address, predecessorOf: s.targetIfTrue.address)
        result.define(source.address, predecessorOf: s.targetIfFalse.address)
      default:
        break
      }
    }

    return result
  }

}

extension Function: CustomStringConvertible {

  public var description: String { "@\(name)" }

}

extension Function {

  /// The global identity of an IR function.
  public struct ID: Hashable {

    /// The value of a function IR identity.
    private enum Value: Hashable {

      /// The identity of a lowered Val function or method variant.
      case lowered(AnyNodeID)

      /// The identity of a requirement synthesized for some type.
      ///
      /// The payload is a pair (D, U) where D is the declaration of a requirement and T is a type
      /// conforming to the trait defining D.
      case synthesized(AnyNodeID, for: AnyType)

    }

    /// The value of this identity.
    private let value: Value

    /// Creates the identity of the lowered form of `f`.
    public init(_ f: FunctionDecl.ID) {
      self.value = .lowered(AnyNodeID(f))
    }

    /// Creates the identity of synthesized requirement `r` for type `t`.
    public init(synthesized r: MethodImpl.ID, for t: AnyType) {
      self.value = .synthesized(AnyNodeID(r), for: t)
    }

  }

}

extension Function.ID: CustomStringConvertible {

  public var description: String {
    switch value {
    case .lowered(let id):
      return "\(id).lowered"
    case .synthesized(let r, let t):
      return "\"synthesized \(r) for \(t)\""
    }
  }

}
