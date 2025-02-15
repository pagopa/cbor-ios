//
//  CBOR+.swift
//  cbor
//
//  Created by Antonio on 02/12/24.
//



internal import SwiftCBOR
internal import OrderedCollections
// Extension to add utility functions for unwrapping and converting CBOR values
extension CBOR {
    
    // Function to unwrap the CBOR value and return its underlying data as a Swift type
    func unwrap() -> Any? {
        switch self {
            case .simple(let value): return value
            case .boolean(let value): return value
            case .byteString(let value): return value
            case .date(let value): return value
            case .double(let value): return value
            case .float(let value): return value
            case .half(let value): return value
            case .tagged(let tag, let cbor): return (tag, cbor) // Return tag and nested CBOR value
            case .array(let array): return array
            case .map(let map): return map
            case .utf8String(let value): return value
            case .negativeInt(let value): return value
            case .unsignedInt(let value): return value
            default: return nil
        }
    }
    
    // Function to attempt to unwrap the CBOR value as UInt64
    func asUInt64() -> UInt64? {
        return self.unwrap() as? UInt64
    }
    
    // Function to attempt to unwrap the CBOR value as a list of CBOR items (array)
    func asList() -> [CBOR]? {
        return self.unwrap() as? [CBOR]
    }
    
    // Function to attempt to unwrap the CBOR value as an array of UInt8 (bytes)
    func asBytes() -> [UInt8]? {
        return self.unwrap() as? [UInt8]
    }
    
    // Function to attempt to unwrap the CBOR value as a map (OrderedDictionary)
    func asMap() -> OrderedDictionary<CBOR, CBOR>? {
        return self.unwrap() as? OrderedDictionary<CBOR, CBOR>
    }
    
    func toCose() -> (CBOR.Tag, [CBOR])? {
        guard let rawCose =  self.unwrap() as? (CBOR.Tag, CBOR),
              let cosePayload = rawCose.1.asList() else {
            return nil
        }
        return (rawCose.0, cosePayload)
    }
    
    
    
    func decodeBytestring() -> CBOR? {
        guard let bytestring = self.asBytes(),
              let decoded = try? CBORDecoder(input: bytestring).decodeItem() else {
            return nil
        }
        return decoded
    }
}
