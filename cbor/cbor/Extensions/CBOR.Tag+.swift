//
//  CBOR.Tag+.swift
//  cbor
//
//  Created by Antonio on 02/12/24.
//



internal import SwiftCBOR

/// COSE Message Identification
extension CBOR.Tag {
    /// Tagged COSE Sign1 Structure
    static let coseSign1Item = CBOR.Tag(rawValue: 18)
    /// Tagged COSE Mac0 Structure
    static let coseMac0Item = CBOR.Tag(rawValue: 17)
    
    /// Tagged Date, Tag 1004 is specified in RFC 8943
    static let fullDateItem = CBOR.Tag(rawValue: 1004)
}
