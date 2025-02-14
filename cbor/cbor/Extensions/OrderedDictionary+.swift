//
//  OrderedDictionary+.swift
//  cbor
//
//  Created by Antonio on 02/12/24.
//



internal import SwiftCBOR
internal import OrderedCollections

extension OrderedDictionary where Key == CBOR {
    subscript<Index: RawRepresentable>(index: Index) -> Value? where Index.RawValue == Int {
    self[CBOR(integerLiteral: index.rawValue)]
  }
}
