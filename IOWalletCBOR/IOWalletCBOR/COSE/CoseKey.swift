//
//  CoseKey.swift
//  cbor
//
//  Created by Antonio Caparello on 13/02/25.
//


public class CoseKey {
    
    internal let coseKey: CoseKeyImpl
    
    private init(_ coseKey: CoseKeyImpl) {
        self.coseKey = coseKey
    }
    
    public var crv: ECCurveName {
        return coseKey.crv
    }
    
    public var kty: ECCurveType {
        return coseKey.kty
    }
    
    public var x: [UInt8] {
        return coseKey.x
    }
    
    public var y: [UInt8] {
        return coseKey.y
    }
    
    
}

extension CoseKey {
    public convenience init(x: [UInt8], y: [UInt8], crv: ECCurveName = .p256) {
        self.init(CoseKeyImpl(x: x, y: y, crv: crv))
    }
    
    public convenience init(crv: ECCurveName, x963Representation: Data) {
        self.init(CoseKeyImpl(crv: crv, x963Representation: x963Representation))
    }
    
    public convenience init?(jwk: String) {
        guard let coseKey = CoseKeyImpl(jwk: jwk) else {
            return nil
        }
        self.init(coseKey)
    }
    
    public func getx963Representation() -> Data {
        return coseKey.getx963Representation()
    }
    
    public func toJWK() -> String? {
        return coseKey.toJWK()
    }
}
