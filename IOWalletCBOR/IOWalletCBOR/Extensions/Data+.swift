//
//  Data+.swift
//  cbor
//
//  Created by Antonio on 02/12/24.
//

import Foundation

extension Data {
    
    // Extension to convert Data into an array of UInt8 (bytes)
    public var bytes: Array<UInt8> {
        return Array(self)
    }

    public init?(base64UrlEncoded input: String) {
        var base64 = input
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        self.init(base64Encoded: base64)
    }

    public func base64UrlEncodedString() -> String {
        var result = self.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
    
}
