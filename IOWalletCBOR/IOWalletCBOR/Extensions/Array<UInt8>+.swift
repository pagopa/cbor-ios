//
//  Array<UInt8>+.swift
//  cbor
//
//  Created by Antonio on 11/02/25.
//
import Foundation

extension Array<UInt8> {
    
    // Extension to convert an array of UInt8 (bytes) into a Data
    public var data: Data {
        return Data(self)
    }
    
}
