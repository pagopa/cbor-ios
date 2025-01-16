# cbor-ios

### CBOR COSE

The library offers a specific set of functions to handle objects in CBOR format. It also supports the creation and verification of COSE signatures.

#### CoseKeyPrivate

```swift
//In order to initialize a CoseKeyPrivate instance with an existing SecureEnclave key you must supply the public key and the dataRepresentation of the privateKey

if let secureEnclavePrivateKey = try? SecureEnclave.P256.KeyAgreement.PrivateKey() {

    let privateKey = CoseKeyPrivate(
        publicKeyx963Data: secureEnclavePrivateKey
            .publicKey
            .x963Representation, 
        secureEnclaveKeyID: secureEnclavePrivateKey
            .dataRepresentation)
}
```

#### CborCose.createSecurePrivateKey

```swift
//  Create a secure private key
//  - Parameters:
//      - curve: Elliptic Curve Name
//      - forceSecureEnclave: A boolean indicating if secure enclave must be used
//  - Returns: A CoseKeyPrivate object if creation succeeds

let privateKey = CborCose.createSecurePrivateKey()
```



#### CborCose.sign

```swift
//  Sign data using provided privateKey
//  - Parameters:
//      - data: Data to sign
//      - privateKey: CoseKeyPrivate instance representing the private key choosen to sign data
//  - Returns: COSE-Sign1 structure with payload data included encoded as Data

let signedPayload = CborCose.sign(data: payloadToSign, privateKey: privateKey)
```

#### CborCose.verify

```swift
//  Verify data using provided publicKey
//  - Parameters:
//      - data: Encoded COSE-Sign1 structure to verify
//      - publicKey: CoseKey instance representing the public key choosen to verify data

let verified = CborCose.verify(data: signedPayload, publicKey: publicKey)
print(verified)
```

#### CborCose.decodeCBOR

```swift
//  Decode CBOR encoded data to json object string
//  - Parameters:
//      - data: CBOR encoded data to decode
//      - documents: wrap decoded object in a "documents" array (Optional and set as true to mimic android)
//  - Returns: String encoded json object

let jsonString = CborCose.decodeCBOR(data: data)
print(jsonString)
```

#### CborCose.jsonFromCBOR

```swift
//  Decode CBOR encoded data to json object
//  - Parameters:
//      - data: CBOR encoded data to decode
//  - Returns: JSON Object

let json = CborCose.jsonFromCBOR(data: data)
print(json)
```