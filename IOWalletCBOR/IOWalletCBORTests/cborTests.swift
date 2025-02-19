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
    
}
