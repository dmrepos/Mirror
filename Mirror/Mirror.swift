//
//  File.swift
//  Mirror
//
//  Created by Kostiantyn Koval on 05/07/15.
//
//

import Foundation

public struct MirrorItem {
  public let name: String
  public let type: Any.Type
  public let value: Any

//  init(_ tup: (String, Swift.Mirror)) {
//    self.name = tup.0
//    self.type = tup.1.valueType
//    self.value = tup.1.value
//  }
}

extension MirrorItem : CustomStringConvertible {
  public var description: String {
    return "\(name): \(type) = \(value)"
  }
}

//MARK: -

public struct Mirror<T> {

  fileprivate let mirror: Swift.Mirror
  let instance: T

  public init (_ x: T) {
    instance = x
    mirror = Swift.Mirror(reflecting: x)
  }

  //MARK: - Type Info

  /// Instance type full name, include Module
  public var name: String {
    return "\(type(of: instance))"
  }

  /// Instance type short name, just a type name, without Module
  public var shortName: String {
    let name = "\(type(of: instance))"
    return name.sortNameStyle
  }

}

// MARK: - Type detection
extension Mirror {

//  public var isClass: Bool {
//    return mirror.objectIdentifier != nil
//  }
//
//  public var isStruct: Bool {
//    return mirror. == nil
//  }

  public var isOptional: Bool {
    return name.hasPrefix("Optional<")
  }

  public var isArray: Bool {
    return name.hasPrefix("Array<")
  }

  public var isDictionary: Bool {
    return name.hasPrefix("Dictionary<")
  }

  public var isSet: Bool {
    return name.hasPrefix("Set<")
  }
}

extension Mirror {

  /// Type properties count
  public var childrenCount: Int {
    return Int(mirror.children.count)
  }

  public var memorySize: Int {
    return MemoryLayout.size(ofValue: instance)
  }
}

//MARK: - Children Inpection
extension Mirror {

  /// Properties Names
  public var names: [String] {
    return map { $0.name }
  }

  /// Properties Values
  public var values: [Any] {
    return map { $0.value }
  }

  /// Properties Types
  public var types: [Any.Type] {
    return map { $0.type }
  }

  /// Short style for type names
  public var typesShortName: [String] {
    return map {
      let conv = "\($0.type)".sortNameStyle
      return conv //.pathExtension
    }
  }

  /// Mirror types for every children property
  public var children: [MirrorItem] {
    return map { $0 }
  }
}

//MARK: - Quering
extension Mirror {

  /// Returns a property value for a property name
  public subscript (key: String) -> Any? {
    let res = findFirst(self) { $0.name == key }
    return res.map { $0.value }
  }

  /// Returns a property value for a property name with a Genereci type
  /// No casting needed
  public func get<U>(_ key: String) -> U? {
    let res = findFirst(self) { $0.name == key }
    return res.flatMap { $0.value as? U }
  }
}

// MARK: - Converting
extension Mirror {

  /// Convert to a dicitonary with [PropertyName : PropertyValue] notation
  public var toDictionary: [String : Any] {

    var result: [String : Any] = [ : ]
    for item in self {
      result[item.name] = item.value
    }

    return result
  }

  /// Convert to NSDictionary.
  /// Useful for saving it to Plist
  public var toNSDictionary: NSDictionary {

    var result: [String : AnyObject] = [ : ]
    for item in self {
      result[item.name] = item.value as? AnyObject
    }

    return result as NSDictionary
  }
}

// MARK: - CollectionType
extension Mirror : Collection, Sequence {
    public func index(after i: Int) -> Int {
        return 1
    }
    

  public func makeIterator() -> IndexingIterator<[MirrorItem]> {
    return children.makeIterator()
  }

  public var startIndex: Int {
    return 0
  }

  public var endIndex: Int {
    return Int(mirror.children.count)
  }

  public subscript (i: Int) -> MirrorItem {
    let index = mirror.children.index(mirror.children.startIndex, offsetBy: Int64(i))
    let child = mirror.children[index]
    return MirrorItem(name: child.label ?? "", type: type(of: (child.value) as AnyObject), value: child.value)
//    return MirrorItem(mirror[i])
  }
}

// MARK: - Mirror helpers
extension String {

  func contains(_ x: String) -> Bool {
    return self.range(of: x) != nil
  }

  func convertOptionals() -> String {
    var x = self
    while let start = x.range(of: "Optional<") {
      if let end = x.range(of: ">", range: start.lowerBound..<x.endIndex) {
        let subtypeRange = start.upperBound..<end.lowerBound
        let subType = x[subtypeRange]
        x.replaceSubrange(end, with: "?")
        let string = String(subType)
        x.replaceSubrange(subtypeRange, with: string.sortNameStyle)
      }
      x.removeSubrange(start)
    }
    return x
  }

  func convertArray() -> String {
    var x = self
    while let start = x.range(of: "Array<") {
      if let end = x.range(of: ">", range: start.lowerBound..<x.endIndex) {
        let subtypeRange = start.upperBound..<end.lowerBound
        let arrayType = x[subtypeRange]
        x.replaceSubrange(end, with: "]")
        let string = String(arrayType)
        x.replaceSubrange(subtypeRange, with: string.sortNameStyle)

      }
      x.replaceSubrange(start, with:"[")
    }
    return x
  }

  func removeTypeModuleName() -> String {
    var x = self
    if let range = self.range(of: ".") {
      x = self.substring(from: range.upperBound)
    }
    return x
  }

  var sortNameStyle: String {
    return self
      .removeTypeModuleName()
      .convertOptionals()
      .convertArray()
  }

}
