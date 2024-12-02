//
//  Data+.swift
//  cbor
//
//  Created by Antonio on 02/12/24.
//



extension Data {
    
    // Extension to convert Data into an array of UInt8 (bytes)
    public var bytes: Array<UInt8> {
        return Array(self)
    }
    
}
