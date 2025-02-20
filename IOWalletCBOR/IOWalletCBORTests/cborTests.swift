//
//  cborTests.swift
//  cborTests
//
//  Created by Antonio on 02/12/24.
//

import XCTest
internal import SwiftCBOR

@testable import IOWalletCBOR
import CryptoKit

final class cborTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func generatePrivateKey(keyTag: String) throws -> SecKey? {
        
        var error: Unmanaged<CFError>?
        
        // Key ACL
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
//            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccessibleAlways,
            .privateKeyUsage, // signing and verification
            &error
        ) else {
            throw error!.takeRetainedValue() as Error
        }
        
        // Key Attributes
        let attributes: NSMutableDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: false,
                kSecAttrApplicationTag: keyTag.data(using: .utf8)!,
                kSecAttrAccessControl: access
            ]
        ]
        
        
        guard let key = SecKeyCreateRandomKey(attributes, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        return key
    }
    
    
    func testSignAndVerifySecKey() {
        guard let secPrivateKey = try? generatePrivateKey(keyTag: "testSecKey") else {
            XCTFail("secPrivateKey creation failed")
            return
        }
        
        guard let privateKey = CoseKeyPrivate(crv: .p256, secKey: secPrivateKey) else {
            return
        }
        
        guard let data = "helloworld".data(using: .utf8) else {
            return
        }
        
        let signed = CborCose.sign(data: data, privateKey: privateKey)
        
        let isValid = CborCose.verify(data: signed, publicKey: privateKey.key)
        
        XCTAssert(isValid == true)
        
    }
    
    func testVerifyAndroidLeadingZeroesJWK() {
        
        let androidPublicKeyJwk = """
        {
        "kty": "EC",
        "crv": "P-256",
        "y": "AO4+pA5yIuxHLJqJogiLT90o+gwZnND2qEQjEfMZ+Tta",
        "x": "AP06ubTkmvo+U1HeiZ35xKHaox++EX6ViRkGnKHclVJB"
        }
        """
        
        let androidSignedDataStr = "hEOhASagU1RoaXMgaXMgYSB0ZXN0IGRhdGFYQDfXLpQpsSZyBJE+0AvBs27tuqIuNEeuRYQACPSLFGT9X18d8RrLkBS0f/AYKbFpW+zd6CmFQ8ry9xkZOT1lkbg="
        
        guard let androidSignedData = Data(base64Encoded: androidSignedDataStr) else {
            XCTFail("androidSignedData decoding failed")
            return
        }
        
        guard let androidCoseKey = CoseKey(jwk: androidPublicKeyJwk) else {
            XCTFail("androidCoseKeyJwk decoding failed")
            return
        }
        
        let isValid = CborCose.verify(data: androidSignedData, publicKey: androidCoseKey)
        
        XCTAssert(isValid == true)
    }
    
    
    func testSignAndVerifyWithJwk() {
        guard let privateKey = CborCose.createSecurePrivateKey(curve: .p256, forceSecureEnclave: false) else {
            XCTFail("privateKey creation failed")
            return
        }
        
        guard let data = "helloworld".data(using: .utf8) else {
            return
        }
        
        let signed = CborCose.sign(data: data, privateKey: privateKey)
        
        let isValid = CborCose.verify(data: signed, publicKey: privateKey.key)
        
        XCTAssert(isValid == true)
        
        guard let jwk = privateKey.key.toJWK() else {
            XCTFail("public key jwk encoding failed")
            return
        }
        
        guard let publicKeyFromJwk = CoseKey(jwk: jwk) else {
            XCTFail("public key jwk decoding failed")
            return
        }
        
        let isValid2 = CborCose.verify(data: signed, publicKey: publicKeyFromJwk)
        
        XCTAssert(isValid2 == true)
        
    }
    
    func testAndroidVerify() {
        let androidPublicKeyStr = "BIVhg5qcO06jsqyuNS32bxjoIiUaIZhRuqdjmWD+X6PNxBzlUJV6m0smNE5wgclxdS62K5ReHUhI5RDmZn2aJvU="
        
        let androidSignedDataStr = "hEOhASZBoERDaWFvWEAslPFPzSVxkxRpcGiYfQf8AsV9xrt8vgGD2eT0Fe6TqryDmzWZgFcLDrYRMn4HcYbe6toVrMOHsBIU5SrKO8ep"
        
        guard let androidSignedData = Data(base64Encoded: androidSignedDataStr) else {
            XCTFail("androidSignedData decoding failed")
            return
        }
        
        guard let androidPublicKey = Data(base64Encoded: androidPublicKeyStr) else {
            XCTFail("androidPublicKey decoding failed")
            return
        }
        
        let androidCoseKey = CoseKey(crv: .p256, x963Representation: androidPublicKey)
   
        let isValid = CborCose.verify(data: androidSignedData, publicKey: androidCoseKey)
        
        XCTAssert(isValid == true)
       
    }
    
    func testJWKPublicCoseKey() {
        let jwk = """
{
  "crv": "P-256",
  "kty": "EC",
  "x": "d2SM2WRV0lOKlMQJGcN76P+mAyau4vhVLlhgzAxyWp4=",
  "y": "FiQJMW6agCMNC9i79ePkQqvtvsaOVaQwZkkcmbsQ/gQ="
}
"""
        
        guard let coseKey = CoseKey(jwk: jwk) else {
            XCTFail("coseKey from jwk decoding failed")
            return
        }
        
        guard let coseKeyJwk = coseKey.toJWK() else {
            XCTFail("coseKey to jwk encoding failed")
            return
        }
    }
    
    func testCoseKeyPrivateNormalEncoding() {
        guard let deviceKey = CborCose.createSecurePrivateKey(curve: .p384, forceSecureEnclave: false) else {
            XCTFail("coseKey creation failed")
            return
        }
        
        let encodedDeviceKey = deviceKey.encode()
        
        guard let decodedDeviceKey = CoseKeyPrivate(data: encodedDeviceKey) else {
            XCTFail("coseKey decoding failed")
            return
        }
        
        XCTAssert(decodedDeviceKey.secureEnclaveKeyID == nil)
        
        XCTAssert(decodedDeviceKey.getx963Representation() == deviceKey.getx963Representation())
        
        let dataToSignString = "this is test data"
        
        let dataToSign = dataToSignString.data(using: .utf8)!
        
        let coseObject = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: deviceKey, alg: .es384)
        
        let isValid = try? coseObject.validateCoseSign1(publicKey_x963: decodedDeviceKey.key.getx963Representation())
        
        let coseObject1 = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: decodedDeviceKey, alg: .es384)
        
        let isValid1 = try? coseObject1.validateCoseSign1(publicKey_x963: deviceKey.key.getx963Representation())
        
        XCTAssert(isValid == true)
        XCTAssert(isValid1 == true)
        
    }
    
    func testCoseKeyPrivateSecureEnclaveEncoding() {
        guard let deviceKey = CborCose.createSecurePrivateKey() else {
            XCTFail("coseKey creation failed")
            return
        }
        
        let encodedDeviceKey = deviceKey.encode()
        
        guard let decodedDeviceKey = CoseKeyPrivate(data: encodedDeviceKey) else {
            XCTFail("coseKey decoding failed")
            return
        }
        
        XCTAssert(decodedDeviceKey.secureEnclaveKeyID != nil)
        
        XCTAssert(decodedDeviceKey.secureEnclaveKeyID == deviceKey.secureEnclaveKeyID)
        
        let dataToSignString = "this is test data"
        
        let dataToSign = dataToSignString.data(using: .utf8)!
        
        let coseObject = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: deviceKey, alg: .es256)
        
        let isValid = try? coseObject.validateCoseSign1(publicKey_x963: decodedDeviceKey.key.getx963Representation())
        
        let coseObject1 = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: decodedDeviceKey, alg: .es256)
        
        let isValid1 = try? coseObject1.validateCoseSign1(publicKey_x963: deviceKey.key.getx963Representation())
        
        XCTAssert(isValid == true)
        XCTAssert(isValid1 == true)
        
    }
    
    func testSignData() {
        let dataToSignString = "this is test data"
        
        let dataToSign = dataToSignString.data(using: .utf8)!
        
        let privateKey = CoseKeyPrivate(crv: .p256)
        let publicKey = privateKey.key
        
        let coseObject = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: privateKey, alg: .es256)
        
        let coseEncoded = coseObject.encode(options: CBOROptions())
        
        guard let coseDecodedCbor = try? CBOR.decode(coseEncoded) else {
            XCTFail("cbor decoding failed")
            return
        }
        
        guard let coseDecoded = Cose(type: .sign1, cbor: coseDecodedCbor) else {
            XCTFail("cose init failed")
            return
        }
        
        guard let isValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: publicKey.getx963Representation()) else {
            XCTFail("validateCoseSign1 failed with exception")
            return
        }
        
        XCTAssert(isValidSignature)
    }
    
    func testSignedData() {
        
        
        let payloadToVerify = "this is test data"
        
        let coseObjectBase64 = "hEOhASagUXRoaXMgaXMgdGVzdCBkYXRhWECWHFXxcZPkyupozacO5KTeBDcbXFYX6HaFynTZ85qXdtGGd9bhtgBq1vcjYdK0QHP+DmG15108cm497i83ScSf"
        
        let validPublicKey1Base64 = "pCABAQIhWCBGNvJAmcQpm4EhDvWYsxWzT7Lm7N0R7X6kAswyi5yqVCJYIIZVRZ4ujdrKimOlytyhpqlOJu2PlOtOhJSSkbzUNJx+"
        let notValidPublicKey1Base64 = "pCABAQIhWCA2hqj0DAvEr7gRsTRLXu7Y8nBlpCIgoDNXtnMmZg8wVSJYIHse1ypD88D0cmS/R6R0f83bE/9GetTg9aPDozHTdvfB"
        
        guard let validPublicKeyData = Data(base64Encoded: validPublicKey1Base64) else {
            XCTFail("base64 decoding failed")
            return
        }
        
        guard let notValidPublicKeyData = Data(base64Encoded: notValidPublicKey1Base64) else {
            XCTFail("base64 decoding failed")
            return
        }
        
        guard let coseDecodedData = Data(base64Encoded: coseObjectBase64) else {
            XCTFail("base64 decoding failed")
            return
        }
        
        guard let coseDecodedCbor = try? CBOR.decode(coseDecodedData.bytes) else {
            XCTFail("cbor decoding failed")
            return
        }
        
        guard let coseDecoded = Cose(type: .sign1, cbor: coseDecodedCbor) else {
            XCTFail("cose init failed")
            return
        }
        
        guard let validPublicKey = CoseKey(data: validPublicKeyData.bytes) else {
            XCTFail("CoseKey CBOR decoding failed")
            return
        }
        
        guard let notValidPublicKey = CoseKey(data: notValidPublicKeyData.bytes) else {
            XCTFail("CoseKey CBOR decoding failed")
            return
        }
        
        guard let isValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: validPublicKey.getx963Representation()) else {
            XCTFail("validateCoseSign1 failed with exception")
            return
        }
        
        guard let isNotValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: notValidPublicKey.getx963Representation()) else {
            XCTFail("validateCoseSign1 failed with exception")
            return
        }
        
        XCTAssert(isValidSignature)
        XCTAssert(!isNotValidSignature)
        
        guard let rawPayload = coseDecoded.payload.asBytes() else {
            XCTFail("cose payload not decodable")
            return
        }
        
        guard let stringPayload = String(data: Data(rawPayload), encoding: .utf8) else {
            XCTFail("cose payload not utf8 string")
            return
        }
        
        XCTAssert(stringPayload == payloadToVerify)
    }
    
    func testCoseSign() {
        let payloadToSignString = "this is test data"
        guard let payloadToSign = payloadToSignString.data(using: .utf8) else {
            XCTFail("failed to utf8encode string")
            return
        }
        
        guard let privateKey = CborCose.createSecurePrivateKey() else {
            XCTFail("failed to create private key")
            return
        }
        
        
        let signedPayload = CborCose.sign(data: payloadToSign, privateKey: privateKey)
        
        let publicKey = privateKey.key
        
        let verified = CborCose.verify(data: signedPayload, publicKey: publicKey)
        
        XCTAssert(verified)
    }
    
    func testDecodeCBORDocuments() {
        guard let jsonString = CborCose.decodeCBOR(data: Data(base64Encoded: cborTests.documents)!) else {
            XCTFail("fail to decode")
            return
        }
        
        print(jsonString)
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) else {
            XCTFail("fail to decode")
            return
        }
        
        print(json)
    }
    
    func testDecodeCBOR() {
        guard let jsonString = CborCose.decodeCBOR(data: Data(base64Encoded: cborTests.document1)!) else {
            XCTFail("fail to decode")
            return
        }
        
        print(jsonString)
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) else {
            XCTFail("fail to decode")
            return
        }
        
        guard let jsonMap = json as? Dictionary<String, AnyHashable> else {
            XCTFail("fail to decode")
            return
        }
        
        guard let documents = jsonMap["documents"] as? Array<AnyHashable> else {
            XCTFail("fail to decode")
            return
        }
        
        guard let documentMap = documents[0] as? Dictionary<String, AnyHashable> else {
            XCTFail("fail to decode")
            return
        }
        
        guard let docType = documentMap["docType"] as? String else {
            XCTFail("fail to decode")
            return
        }
        
        XCTAssertEqual(docType, "eu.europa.ec.eudi.pid.1")
        
        guard let issuerSigned = documentMap["issuerSigned"] as? Dictionary<String, AnyHashable> else {
            XCTFail("fail to decode")
            return
        }
        
        guard let nameSpaces = issuerSigned["nameSpaces"] as? Dictionary<String, AnyHashable> else {
            XCTFail("fail to decode")
            return
        }
        
        guard let nameSpace = nameSpaces["eu.europa.ec.eudi.pid.1"] as? Array<AnyHashable> else {
            XCTFail("fail to decode")
            //XCTFail("")
            
            return
        }
        
        nameSpace.forEach({
            item in
            
            if let element = item as? Dictionary<String, AnyHashable> {
                if let birth_date = element["birth_date"] as? String {
                    XCTAssertEqual(birth_date, "2001-09-11")
                }
                else if let family_name = element["family_name"] as? String {
                    XCTAssertEqual(family_name, "Doe")
                }
                else if let expiry_date = element["expiry_date"] as? String {
                    XCTAssertEqual(expiry_date, "2025-01-09")
                }
                else if let issuing_authority = element["issuing_authority"] as? String {
                    XCTAssertEqual(issuing_authority, "Test PID issuer")
                }
                else if let issuing_country = element["issuing_country"] as? String {
                    XCTAssertEqual(issuing_country, "FC")
                }
                else if let issuance_date = element["issuance_date"] as? String {
                    XCTAssertEqual(issuance_date, "2024-10-11")
                }
                else if let given_name = element["given_name"] as? String {
                    XCTAssertEqual(given_name, "John")
                }
                else if let age_over_18 = element["age_over_18"] as? String {
                    XCTAssertEqual(age_over_18, "true")
                }
                else {
                    print("not testable \(element)")
                }
            }
        })
    }
    
    
    static let document1 = "omdkb2NUeXBld2V1LmV1cm9wYS5lYy5ldWRpLnBpZC4xbGlzc3VlclNpZ25lZKJqbmFtZVNwYWNlc6F3ZXUuZXVyb3BhLmVjLmV1ZGkucGlkLjGI2BhYbKRmcmFuZG9tWCACJT7HnW2qHxQnDiCkAxgSV2nhQ/a7NUAjlk4w+gPqp2hkaWdlc3RJRABsZWxlbWVudFZhbHVl2QPsajIwMDEtMDktMTFxZWxlbWVudElkZW50aWZpZXJqYmlydGhfZGF0ZdgYWGOkZnJhbmRvbVggzG7W7/1FwVnoSNIeYTvUAn+MvkL1REs01SYu1rpdrg9oZGlnZXN0SUQBbGVsZW1lbnRWYWx1ZWNEb2VxZWxlbWVudElkZW50aWZpZXJrZmFtaWx5X25hbWXYGFhtpGZyYW5kb21YIB36oKwS28mdoNXNXSX5uRfOxY9XOmzC0IgKqvTWbdsPaGRpZ2VzdElEAmxlbGVtZW50VmFsdWXZA+xqMjAyNS0wMS0wOXFlbGVtZW50SWRlbnRpZmllcmtleHBpcnlfZGF0ZdgYWHWkZnJhbmRvbVgg2uiHuXqxdbVioHbuNoIrIFVz0kaEENfUORn3nM0+moNoZGlnZXN0SUQDbGVsZW1lbnRWYWx1ZW9UZXN0IFBJRCBpc3N1ZXJxZWxlbWVudElkZW50aWZpZXJxaXNzdWluZ19hdXRob3JpdHnYGFhmpGZyYW5kb21YIHCgPuKd9fd1dFvG67Fk+c1pPhcDOINlgvlWO+GUXKnYaGRpZ2VzdElEBGxlbGVtZW50VmFsdWViRkNxZWxlbWVudElkZW50aWZpZXJvaXNzdWluZ19jb3VudHJ52BhYb6RmcmFuZG9tWCApNlGYNvu6gqBQ14P3nBQWlUioJ4YJtR2k50hZslFJzGhkaWdlc3RJRAVsZWxlbWVudFZhbHVl2QPsajIwMjQtMTAtMTFxZWxlbWVudElkZW50aWZpZXJtaXNzdWFuY2VfZGF0ZdgYWGOkZnJhbmRvbVggmexRsVFw6dkH/ESmIoQK68OIrgVkf9PvYj7qLYi8H7VoZGlnZXN0SUQGbGVsZW1lbnRWYWx1ZWRKb2hucWVsZW1lbnRJZGVudGlmaWVyamdpdmVuX25hbWXYGFhgpGZyYW5kb21YIFfQK4O5cz2qWEcJIsg5SHl7syHMA/PVPPr+EK2gWrPzaGRpZ2VzdElEB2xlbGVtZW50VmFsdWX1cWVsZW1lbnRJZGVudGlmaWVya2FnZV9vdmVyXzE4amlzc3VlckF1dGiEQ6EBJqEYIVkC6DCCAuQwggJqoAMCAQICFHIybfZjCJp7UA+MPyamhcvCwtLKMAoGCCqGSM49BAMCMFwxHjAcBgNVBAMMFVBJRCBJc3N1ZXIgQ0EgLSBVVCAwMTEtMCsGA1UECgwkRVVESSBXYWxsZXQgUmVmZXJlbmNlIEltcGxlbWVudGF0aW9uMQswCQYDVQQGEwJVVDAeFw0yMzA5MDIxNzQyNTFaFw0yNDExMjUxNzQyNTBaMFQxFjAUBgNVBAMMDVBJRCBEUyAtIDAwMDExLTArBgNVBAoMJEVVREkgV2FsbGV0IFJlZmVyZW5jZSBJbXBsZW1lbnRhdGlvbjELMAkGA1UEBhMCVVQwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARJBHzUHC0bpmqOtZBhZbDmk94bHOWvem1civd+0j3esn8q8L1MCColNqQkCPadXjJAYsmXS3D4+HB9scOshixYo4IBEDCCAQwwHwYDVR0jBBgwFoAUs2y4kRcc16QaZjGHQuGLwEDMlRswFgYDVR0lAQH/BAwwCgYIK4ECAgAAAQIwQwYDVR0fBDwwOjA4oDagNIYyaHR0cHM6Ly9wcmVwcm9kLnBraS5ldWRpdy5kZXYvY3JsL3BpZF9DQV9VVF8wMS5jcmwwHQYDVR0OBBYEFIHv9JxcgwpQpka+91B4WlM+P9ibMA4GA1UdDwEB/wQEAwIHgDBdBgNVHRIEVjBUhlJodHRwczovL2dpdGh1Yi5jb20vZXUtZGlnaXRhbC1pZGVudGl0eS13YWxsZXQvYXJjaGl0ZWN0dXJlLWFuZC1yZWZlcmVuY2UtZnJhbWV3b3JrMAoGCCqGSM49BAMCA2gAMGUCMEX62qLvLZVT67SIRNhkGtAqnjqOSit32uL0HnlfLy2QmwPygQmUa04tkoOtf8GhhQIxAJueTu1QEJ9fDrcALM+Ys/7kEUB+Ze4w+wEEvtZzguqD3h9cxIjmEBdkATInQ0BNClkCWdgYWQJUpmdkb2NUeXBld2V1LmV1cm9wYS5lYy5ldWRpLnBpZC4xZ3ZlcnNpb25jMS4wbHZhbGlkaXR5SW5mb6Nmc2lnbmVkwHQyMDI0LTEwLTExVDA3OjAxOjExWml2YWxpZEZyb23AdDIwMjQtMTAtMTFUMDc6MDE6MTFaanZhbGlkVW50aWzAdDIwMjUtMDEtMDlUMDA6MDA6MDBabHZhbHVlRGlnZXN0c6F3ZXUuZXVyb3BhLmVjLmV1ZGkucGlkLjGoAFggP/S3X7mU2I2VQbYGFhhxkystiLRCyytuJMrwWvn2bQYBWCCnIp1mnq6fobjEuEXDbYf+9aEuuRvLKDZs4jXbEGz2ewJYIBw281OtY/W84LFUhigipj+ecxQcf35dHQuYtrPcFclLA1ggDEi+ZN8LGmQr4CVkutmOSltScOUrQ2GyEVpmqizUYbAEWCBtnHyW56yG+iRZRHMULCE7ZqpjVCogJF3vASq5QcwY2gVYIP2fleM2AeI5OAf5pbzcl/SInsXjM2+8braXnuwpKMf+BlggR9ChujVabtyFNKeHhOKTIEPx1TpCxhNJbOKzUdFjUZgHWCC2/CPwUZERXNEwNgmUK1wQA61ry6/RyxIL1QaAEiamr21kZXZpY2VLZXlJbmZvoWlkZXZpY2VLZXmkAQIgASFYIHXTLljzrh3IHJv87tVhcgBgiB/uM33z93pA+EUq09LkIlggFHek+dxXQYCdIlHxmXReh1l8NMlwyecXZLYOSVuoyNNvZGlnZXN0QWxnb3JpdGhtZ1NIQS0yNTZYQG5aGiJyce8+/I6P/T62uEsS1016GEDrkJ7CgHLrxcK22vierU5OlTMnZ0GRZ0Lav479zl+C/IH1EgsdroUdH48="
    
    
    static let documents: String = "o2d2ZXJzaW9uYzEuMGlkb2N1bWVudHOCo2dkb2NUeXBldW9yZy5pc28uMTgwMTMuNS4xLm1ETGxpc3N1ZXJTaWduZWSiam5hbWVTcGFjZXOhcW9yZy5pc28uMTgwMTMuNS4xmCXYGFiJpGZyYW5kb21YQO+PZJ2pSdMYLRgStZVYYV3vA/m3hbSIl8pZ9VIZkzypmzZk8L6JTsmt4fvwMhRNjKgqJt7AWLPFcpVNt/J5DkxoZGlnZXN0SUQObGVsZW1lbnRWYWx1ZWlBTkRFUlNTT05xZWxlbWVudElkZW50aWZpZXJrZmFtaWx5X25hbWXYGFiDpGZyYW5kb21YQL88tMU5lfQVkqkx9S+SzuShWsz/pArAYh7t2oIf3RYcpzI9EiwWlmHzT61z0iu8FCMLj6rqZWIAOC29cxhBc7doZGlnZXN0SUQYJmxlbGVtZW50VmFsdWVjSkFOcWVsZW1lbnRJZGVudGlmaWVyamdpdmVuX25hbWXYGFiNpGZyYW5kb21YQLwyVgt3jL4xuewpH0JWgXYyGO2H9jTb069uyqcHUOJGK0kkIbDiQEw4iF2XgD+21anb3Tu2Z4tDVCFQx0rXkkhoZGlnZXN0SUQYQmxlbGVtZW50VmFsdWXZA+xqMTk4NS0wMy0zMHFlbGVtZW50SWRlbnRpZmllcmpiaXJ0aF9kYXRl2BhYlKRmcmFuZG9tWEDtdx/Ufjs5WY4xRHCMKhETvUWq7iWVrBqJU+V+qqUrzBBhgowTjMdZlZdo5duCvgv6XvknQBBYcHPynF5KASO1aGRpZ2VzdElED2xlbGVtZW50VmFsdWXAdDIwMDktMDEtMDFUMDA6MDA6MDBacWVsZW1lbnRJZGVudGlmaWVyamlzc3VlX2RhdGXYGFiVpGZyYW5kb21YQL5fa8i7gO9vjZiFjhzTG3q9SXaRzhI/cO3hTE3SHYBnrg9ohytv0/z8DEF9zB+uHqCa69FmOR/9VUZL5uaaWUpoZGlnZXN0SUQKbGVsZW1lbnRWYWx1ZcB0MjA1MC0wMy0zMFQwMDowMDowMFpxZWxlbWVudElkZW50aWZpZXJrZXhwaXJ5X2RhdGXYGFiGpGZyYW5kb21YQEsnaEBD4ZiGg192S0AvbCey9LXhfDUBvl6pOcay7NnS+brmvGCMYdeFwHqRB+G+JNz0ix01iux5L38L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ZnJhbmRvbVhAXK6vXu8gK0c+KpL1E+LDIwvNRRBzOFgJ+RMB2Dmi8Ibp8SaQq65AtBsl6ylJg5R6Uo5hlUf8DA5Uemgx0bgJM2hkaWdlc3RJRBRsZWxlbWVudFZhbHVlZTY0MTMzcWVsZW1lbnRJZGVudGlmaWVydHJlc2lkZW50X3Bvc3RhbF9jb2Rl2BhYiKRmcmFuZG9tWEBV4XqHlThf4qv8lpFIgdFFH1Bb7N1ixC8Pl9huaYw/0lXR1adnLKhEbS7xCleItu2XtPewEs9FKn3oGSzKAkGSaGRpZ2VzdElEGFJsZWxlbWVudFZhbHVlYlNFcWVsZW1lbnRJZGVudGlmaWVycHJlc2lkZW50X2NvdW50cnnYGFiepGZyYW5kb21YQHRlfXrF+og7TIuNh8jDKv8T2sHrzSzDJxCaENH7U4S8QRIEefPY4uYixrT/3kss2VFLBMUP+XGUyIvU20i6LuZoZGlnZXN0SUQYOWxlbGVtZW50VmFsdWVpQU5ERVJTU09OcWVsZW1lbnRJZGVudGlmaWVyeB5mYW1pbHlfbmFtZV9uYXRpb25hbF9jaGFyYWN0ZXLYGFiXpGZyYW5kb21YQJR2feigXw2qIpNWPpf7f3jEqIzgyQzD1TF5MZsN3USZj5XOJMBVKoEvIQDKmnwE/rn4cOBkR44OprdABIZsHsFoZGlnZXN0SUQYYmxlbGVtZW50VmFsdWVjSkFOcWVsZW1lbnRJZGVudGlmaWVyeB1naXZlbl9uYW1lX25hdGlvbmFsX2NoYXJhY3RlctgYWICkZnJhbmRvbVhAUi1b+LZuPFuwuuPMxrzT4fKrf8+qoDOo7upVhuY7fbCpKkXoRUlZiA4oyTmmngYcmKbAtEVS33nq+a8MEAuHwmhkaWdlc3RJRBFsZWxlbWVudFZhbHVl9XFlbGVtZW50SWRlbnRpZmllcmthZ2Vfb3Zlcl8xNdgYWICkZnJhbmRvbVhApXrqocQZYTMdwoAloN6gUIZOfifYsZOJOfra3M6uMQBRIp+QroeHhNx74zYMKSAW2HtXN3FzN7+wa9KixkImOWhkaWdlc3RJRAxsZWxlbWVudFZhbHVl9XFlbGVtZW50SWRlbnRpZmllcmthZ2Vfb3Zlcl8xONgYWIGkZnJhbmRvbVhAlfLJnc4gfOXQ2Yg7P/IMhFsO1H1u/6/T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N/zIgfeY7U3ipqh6aGRpZ2VzdElEGCJsZWxlbWVudFZhbHVlGQfBcWVsZW1lbnRJZGVudGlmaWVybmFnZV9iaXJ0aF95ZWFy2BhYkKRmcmFuZG9tWEDc/EbFJMZ90N2+V9ukhHsDNzr4POEGMhb7OAxEsNZQWqEwcwgbXX8RjYAjdvPFeTG4Je4B1sg1/vP8VBwCAGd9aGRpZ2VzdElEGDJsZWxlbWVudFZhbHVlaUFOREVSU1NPTnFlbGVtZW50SWRlbnRpZmllcnFmYW1pbHlfbmFtZV9iaXJ0aNgYWIikZnJhbmRvbVhAvx4lLSshvNRVEzJjW48qIwmieGSHz70wrzcHZMzPvCA6bCd4RoV7vRH1UEYaOPzLxnDrDV73LlmnzeRfmDtuKGhkaWdlc3RJRAhsZWxlbWVudFZhbHVlY0pBTnFlbGVtZW50SWRlbnRpZmllcnBnaXZlbl9uYW1lX2JpcnRo2BhYh6RmcmFuZG9tWEAsYnLtPPIIo3tbaFw5lkzN4yTigJvTIxuFVH6QOOzTBcq+AjtrYwfRHkR/FTfQ0Ss0wlkdxoOWSyTUP1gHOX54aGRpZ2VzdElEGC9sZWxlbWVudFZhbHVlZlNXRURFTnFlbGVtZW50SWRlbnRpZmllcmtiaXJ0aF9wbGFjZdgYWISkZnJhbmRvbVhAvvr8ThBVWI/rzvZ4X6C3PLFCGotmKlVzs7CUoPhktQZvT2u/rCPKoqN1Bfc8JgZx2G6Y4vD88iwfDBGB7G8eNWhkaWdlc3RJRAVsZWxlbWVudFZhbHVlYlNFcWVsZW1lbnRJZGVudGlmaWVybWJpcnRoX2NvdW50cnnYGFiDpGZyYW5kb21YQLEkk72bIxjGHvrfS8FM9VlwGeDjc73mzh6cqcK9tYriGR809035EsaxER875bMLQfnLRzqxiPeePT/0UqqISGVoZGlnZXN0SUQYKWxlbGVtZW50VmFsdWViU0VxZWxlbWVudElkZW50aWZpZXJrYmlydGhfc3RhdGXYGFiLpGZyYW5kb21YQNgZgbaxnJYhnxYO+pVqbARftZScBwcmwBT3nJr5FlgcFF8P6GjyFQo5RLqEHc+/rnUtmxPVyw7L1ZTdfeYEhX5oZGlnZXN0SUQYH2xlbGVtZW50VmFsdWVrS0FUUklORUhPTE1xZWxlbWVudElkZW50aWZpZXJqYmlydGhfY2l0edgYWJWkZnJhbmRvbVhAXZYl7jg+LTcRqpTyILQKibrKjSf7f4PjwzI464RIIDJjAUc6P6Xo7Oc81hQuQkw2xavkoP6MvXH8KK+hBsf9nWhkaWdlc3RJRBghbGVsZW1lbnRWYWx1ZW9GT1JUVU5BR0FUQU4gMTVxZWxlbWVudElkZW50aWZpZXJwcmVzaWRlbnRfYWRkcmVzc9gYWIikZnJhbmRvbVhA98ZRjkKeUbSHAQh8vZsGTP4CI1m71eNCiXtgBHt+UVV8mpo9wiHPpIMLCCVhM4cHYIcy3BYwU4cz4TgggjPw6mhkaWdlc3RJRBgjbGVsZW1lbnRWYWx1ZWJTRXFlbGVtZW50SWRlbnRpZmllcnByZXNpZGVudF9jb3VudHJ52BhYhqRmcmFuZG9tWEDE1FZZL9532T+me2wrCk4ePPBrfef22j8CZ7aQE6+Ji4Ie92hql1ANoNMp5jp5ENwhstHR/KyRfDx2Bbuik7KHaGRpZ2VzdElEGC5sZWxlbWVudFZhbHVlYlNFcWVsZW1lbnRJZGVudGlmaWVybnJlc2lkZW50X3N0YXRl2BhYjqRmcmFuZG9tWED7H0oqs0vpOF1fTcGw++ueIoUUvsEYc/JMoELZPf/s9qYntYZNYK7DCW/OwYAq7NuUdyWsrmEmYZs/6k9julHSaGRpZ2VzdElEGB5sZWxlbWVudFZhbHVla0tBVFJJTkVIT0xNcWVsZW1lbnRJZGVudGlmaWVybXJlc2lkZW50X2NpdHnYGFiOpGZyYW5kb21YQIynYVrsWwjwecKl5ZWI+bWkcXZFMoRRCXRLvdUqOHgALDa5R+ZcKl+XclgzveMro09xIF/H55wmvd/LGnuUthxoZGlnZXN0SUQCbGVsZW1lbnRWYWx1ZWU2NDEzM3FlbGVtZW50SWRlbnRpZmllcnRyZXNpZGVudF9wb3N0YWxfY29kZdgYWJGkZnJhbmRvbVhA2BmBtrGcliGfFg76lWpsBF+1lJwHBybAFPecmvkWWBwUXw/oaPIVCjlEuoQdz7+udS2bE9XLDsvVlN195gSFfmhkaWdlc3RJRBgkbGVsZW1lbnRWYWx1ZWxGT1JUVU5BR0FUQU5xZWxlbWVudElkZW50aWZpZXJvcmVzaWRlbnRfc3RyZWV02BhYjaRmcmFuZG9tWEBz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"
    
}
