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

extension _Node {
  @inlinable
  internal static func _collisionNode(
    _ hash: _Hash,
    _ item1: Element,
    _ inserter2: (UnsafeMutablePointer<Element>) -> Void
  ) -> _Node {
    let node = _Node.allocateCollision(count: 2, hash) { items in
      items.initializeElement(at: 1, to: item1)
      inserter2(items.baseAddress.unsafelyUnwrapped)
    }.node
    node._invariantCheck()
    return node
  }

  @inlinable
  internal static func _regularNode(
    _ item1: Element,
    _ bucket1: _Bucket,
    _ inserter2: (UnsafeMutablePointer<Element>) -> Void,
    _ bucket2: _Bucket
  ) -> (node: _Node, slot1: _Slot, slot2: _Slot) {
    assert(bucket1 != bucket2)
    let r = _Node.allocate(
      itemMap: _Bitmap(bucket1, bucket2),
      childMap: .empty,
      count: 2
    ) { children, items in
      assert(items.count == 2 && children.count == 0)
      let i1 = bucket1 < bucket2 ? 1 : 0
      let i2 = 1 &- i1
      items.initializeElement(at: i1, to: item1)
      inserter2(items.baseAddress.unsafelyUnwrapped + i2)
      return (_Slot(i2), _Slot(i1)) // Note: swapped
    }
    r.node._invariantCheck()
    return (r.node, r.result.0, r.result.1)
  }

  @inlinable
  internal static func _regularNode(
    _ child: _Node, _ bucket: _Bucket
  ) -> _Node {
    let r = _Node.allocate(
      itemMap: .empty,
      childMap: _Bitmap(bucket),
      count: child.count
    ) { children, items in
      assert(items.count == 0 && children.count == 1)
      children.initializeElement(at: 0, to: child)
    }
    r.node._invariantCheck()
    return r.node
  }

  @inlinable
  internal static func _regularNode(
    _ inserter: (UnsafeMutablePointer<Element>) -> Void,
    _ itemBucket: _Bucket,
    _ child: _Node,
    _ childBucket: _Bucket
  ) -> _Node {
    assert(itemBucket != childBucket)
    let r = _Node.allocate(
      itemMap: _Bitmap(itemBucket),
      childMap: _Bitmap(childBucket),
      count: child.count &+ 1
    ) { children, items in
      assert(items.count == 1 && children.count == 1)
      inserter(items.baseAddress.unsafelyUnwrapped)
      children.initializeElement(at: 0, to: child)
    }
    r.node._invariantCheck()
    return r.node
  }
}

extension _Node {
  @inlinable
  internal static func build(
    level: _Level,
    item1: Element,
    _ hash1: _Hash,
    item2 inserter2: (UnsafeMutablePointer<Element>) -> Void,
    _ hash2: _Hash
  ) -> (top: _Node, leaf: _UnmanagedNode, slot1: _Slot, slot2: _Slot) {
    if hash1 == hash2 {
      let top = _collisionNode(hash1, item1, inserter2)
      return (top, top.unmanaged, _Slot(0), _Slot(1))
    }
    let r = _build(
      level: level, item1: item1, hash1, item2: inserter2, hash2)
    return (r.top, r.leaf, r.slot1, r.slot2)
  }

  @inlinable
  internal static func _build(
    level: _Level,
    item1: Element,
    _ hash1: _Hash,
    item2 inserter2: (UnsafeMutablePointer<Element>) -> Void,
    _ hash2: _Hash
  ) -> (top: _Node, leaf: _UnmanagedNode, slot1: _Slot, slot2: _Slot) {
    assert(hash1 != hash2)
    let b1 = hash1[level]
    let b2 = hash2[level]
    guard b1 == b2 else {
      let r = _regularNode(item1, b1, inserter2, b2)
      return (r.node, r.node.unmanaged, r.slot1, r.slot2)
    }
    let r = _build(
      level: level.descend(),
      item1: item1, hash1,
      item2: inserter2, hash2)
    return (_regularNode(r.top, b1), r.leaf, r.slot1, r.slot2)
  }

  @inlinable
  internal static func build(
    level: _Level,
    item1 inserter1: (UnsafeMutablePointer<Element>) -> Void,
    _ hash1: _Hash,
    child2: _Node,
    _ hash2: _Hash
  ) -> (top: _Node, leaf: _UnmanagedNode, slot1: _Slot, slot2: _Slot) {
    assert(child2.isCollisionNode)
    assert(hash1 != hash2)
    let b1 = hash1[level]
    let b2 = hash2[level]
    if b1 == b2 {
      let node = build(
        level: level.descend(),
        item1: inserter1, hash1,
        child2: child2, hash2)
      return (_regularNode(node.top, b1), node.leaf, node.slot1, node.slot2)
    }
    let node = _regularNode(inserter1, hash1[level], child2, hash2[level])
    return (node, node.unmanaged, .zero, .zero)
  }
}
