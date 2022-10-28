//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary {
  /// Returns a new dictionary containing the keys of this dictionary with the
  /// values transformed by the given closure.
  ///
  /// - Parameter transform: A closure that transforms a value. `transform`
  ///   accepts each value of the dictionary as its parameter and returns a
  ///   transformed value of the same or of a different type.
  /// - Returns: A dictionary containing the keys and transformed values of
  ///   this dictionary.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func mapValues<T>(
    _ transform: (Value) throws -> T
  ) rethrows -> PersistentDictionary<Key, T> {
    let transformed = try _root.mapValues { try transform($0.value) }
    return PersistentDictionary<Key, T>(_new: transformed)
  }

  /// Returns a new dictionary containing only the key-value pairs that have
  /// non-`nil` values as the result of transformation by the given closure.
  ///
  /// Use this method to receive a dictionary with non-optional values when
  /// your transformation produces optional values.
  ///
  /// In this example, note the difference in the result of using `mapValues`
  /// and `compactMapValues` with a transformation that returns an optional
  /// `Int` value.
  ///
  ///     let data: PersistentDictionary = ["a": "1", "b": "three", "c": "///4///"]
  ///
  ///     let m: [String: Int?] = data.mapValues { str in Int(str) }
  ///     // ["a": Optional(1), "b": nil, "c": nil]
  ///
  ///     let c: [String: Int] = data.compactMapValues { str in Int(str) }
  ///     // ["a": 1]
  ///
  /// - Parameter transform: A closure that transforms a value. `transform`
  ///   accepts each value of the dictionary as its parameter and returns an
  ///   optional transformed value of the same or of a different type.
  ///
  /// - Returns: A dictionary containing the keys and non-`nil` transformed
  ///   values of this dictionary.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func compactMapValues<T>(
    _ transform: (Value) throws -> T?
  ) rethrows -> PersistentDictionary<Key, T> {
    let result = try _root.compactMapValues(.top, transform)
    return PersistentDictionary<Key, T>(_new: result.finalize(.top))
  }
}
