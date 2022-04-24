/// A half-open range of positions in a source file.
public struct SourceRange: Hashable {

  /// The source file containing the locations.
  public let source: SourceFile

  /// The start index of the range.
  public let lowerBound: SourceFile.Position

  /// The end index of the range.
  public let upperBound: SourceFile.Position

  /// Creates a range in `source` from `lowerBound` to `upperBound`.
  ///
  /// - Requires: `lowerBound <= upperBound`
  public init(in source: SourceFile, from lowerBound: String.Index, to upperBound: String.Index) {
    precondition(lowerBound <= upperBound)
    self.source = source
    self.lowerBound = lowerBound
    self.upperBound = upperBound
  }

  /// Returns the first source location in this range.
  public func first() -> SourceLocation? {
    lowerBound < upperBound
      ? SourceLocation(source: source, index: lowerBound)
      : nil
  }

  /// Returns the last source location in this range.
  public func last() -> SourceLocation? {
    lowerBound < upperBound
      ? source.index(before: SourceLocation(source: source, index: upperBound))
      : nil
  }

}
