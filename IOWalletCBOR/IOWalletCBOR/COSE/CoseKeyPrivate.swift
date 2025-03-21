//
//  CoseKeyPrivate.swift
//  cbor
//
//  Created by Antonio Caparello on 13/02/25.
//

internal import SwiftCBOR

import Foundation

public class CoseKeyPrivate {
    
    internal let coseKeyPrivate: CoseKeyPrivateImpl
    
    internal init(_ coseKeyPrivate: CoseKeyPrivateImpl) {
        self.coseKeyPrivate = coseKeyPrivate
    }
    
}

extension CoseKeyPrivate {
    public convenience init(privateKeyx963Data: Data, crv: ECCurveName = .p256) {
        self.init(CoseKeyPrivateImpl(privateKeyx963Data: privateKeyx963Data, crv: crv))
    }
    
    public convenience init(crv: ECCurveName) {
        self.init(CoseKeyPrivateImpl(crv: crv))
    }
   
    public convenience init?(crv: ECCurveName, keyTag: String) {
        let getQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        self.init(crv: crv, secKey: (item as! SecKey))
      
    }
    
    public convenience init?(crv: ECCurveName, secKey: SecKey) {
        guard let coseKeyPrivate = CoseKeyPrivateImpl(crv: crv, secKey: secKey) else {
            return nil
        }
        self.init(coseKeyPrivate)
    }
    
    public convenience init(publicKeyx963Data: Data, secureEnclaveKeyID: Data) {
        self.init(CoseKeyPrivateImpl(publicKeyx963Data: publicKeyx963Data, secureEnclaveKeyID: secureEnclaveKeyID))
    }
    
    public convenience init(x: [UInt8], y: [UInt8], d: [UInt8], crv: ECCurveName = .p256) {
        self.init(CoseKeyPrivateImpl(x: x, y: y, d: d, crv: crv))
    }
    
    public convenience init?(data: [UInt8]) {
        guard let coseKeyPrivate = CoseKeyPrivateImpl(data: data) else {
            return nil
        }
        self.init(coseKeyPrivate)
    }
    
    public convenience init?(base64: String) {
        guard let coseKeyPrivate = CoseKeyPrivateImpl(base64: base64) else {
            return nil
        }
        self.init(coseKeyPrivate)
    }
    
    public func getx963Representation() -> Data {
        self.coseKeyPrivate.getx963Representation()
    }
    
    public func base64Encoded() -> String {
        return self.coseKeyPrivate.base64Encoded(options: CBOROptions())
    }
    
    public var key: CoseKey {
        return CoseKey(self.coseKeyPrivate.key)
    }
    
    public var secureEnclaveKeyID: Data? {
        return self.coseKeyPrivate.secureEnclaveKeyID
    }
    
    public func encode() -> [UInt8] {
        return self.coseKeyPrivate.encode(options: CBOROptions())
    }
    
    
    
    
}
