//
//  WebkitCacheExerciseVC.swift
//  iGoat-Swift
//
//  Copyright © 2018 OWASP. All rights reserved.
//

import UIKit

let cipher:[UInt8] = [
    0xCF, 0x05, 0xCF, 0x7E, 0x09, 0x4D, 0x72, 0x5B,
    0x1D, 0x1E, 0xB5, 0x3F, 0xF0, 0x6F, 0x06, 0xF1];

let salt = "0123456789";

let sha2:[UInt8] = [
    0x7E, 0x32, 0xA7, 0x29, 0xB1, 0x22, 0x6E, 0xD1,
    0x27, 0x0F, 0x28, 0x2A, 0x8C, 0x63, 0x05, 0x4D,
    0x09, 0xB2, 0x6B, 0xC9, 0xEC, 0x53, 0xEA, 0x69,
    0x77, 0x1C, 0xE3, 0x81, 0x58, 0xDF, 0xAD, 0xE8];


class WebkitCacheExerciseVC: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var responseLabel: UILabel!
    
    let demoEndpoint = "http://localhost:8081/webkit.php"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        hitRequest()
    }

    func hitRequest() {
        guard let url = URL(string: demoEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/x-www-form-urlencoded",
                            forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/xhtml+xml,application/xml",
                            forHTTPHeaderField: "Accept")
        urlRequest.cachePolicy = .returnCacheDataElseLoad
        urlRequest.httpBody = "token=key".data(using: .utf8)
        urlRequest.httpMethod = "POST"
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        SVProgressHUD.show()
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            DispatchQueue.main.async { [weak self] in
                SVProgressHUD.dismiss()
                if let response = response as? HTTPURLResponse, response.statusCode == 200, let _ = data {
                    self?.responseLabel.text = "\(cipher)"
                } else {
                    UIAlertController.showAlertWith(title: "Error", message: "Operation could not be completed")
                }
            }
        })
        task.resume()
    }
    
    @IBAction func verify() {
        let enteredStr = textField.text ?? ""
        if let passcode = decrypt(key: enteredStr) {
            UIAlertController.showAlertWith(title: "Success", message: "Passcode: \(passcode)")
            return
        }
        UIAlertController.showAlertWith(title: "Fail", message: "Try Again!!")
    }
    
    func decrypt(key: String) -> String? {
        //textfield and salt
        let saltData = salt.data(using: .utf8)!
        guard let pbkdfData = pbkdf2(password: key, salt: saltData, keyByteCount: 32) else {return nil}

        let cipherData = NSData(bytes: cipher, length: cipher.count) as Data
        guard let decrypted = aesCBCDecrypt(data: cipherData, keyData: pbkdfData) else {return nil}
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        decrypted.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(decrypted.count), &hash)
        }
        
        if (hash == sha2) {
            return String(data: decrypted, encoding: .utf8)
        }
        return nil
    }
    
    func pbkdf2(password: String, salt: Data, keyByteCount: Int, rounds: Int = 1000) -> Data? {
        // Convert password to bytes and derive into a single mutable buffer.
        let passwordData = password.data(using: .utf8)!
        var derivedKeyData = Data(repeating: 0, count: keyByteCount)

        let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    // CCKeyDerivationPBKDF expects a pointer to the password bytes (as C char *)
                    // and a pointer to the salt bytes. Use the derivedKeyData buffer for output.
                    let passwordPtr = passwordBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                    let saltPtr = saltBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    let derivedKeyPtr = derivedKeyBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)

                    return CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordPtr, passwordData.count,
                        saltPtr, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(rounds),
                        derivedKeyPtr, derivedKeyData.count)
                }
            }
        }

        if (derivationStatus != 0) {
            print("Error: \(derivationStatus)")
            return nil;
        }

        return derivedKeyData
    }

    // The iv is prefixed to the encrypted data. If no IV is present the function
    // falls back to passing nil to CCCrypt to preserve previous behavior for the
    // exercise fixtures.
    func aesCBCDecrypt(data:Data, keyData:Data) -> Data? {
        let keyLength = keyData.count
        let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]
        if (validKeyLengths.contains(keyLength) == false) {
            print("Invalid key length")
            return nil
        }

        let ivSize = kCCBlockSizeAES128

        // Extract IV if present (prefixed to ciphertext)
        var ivData: Data? = nil
        var ciphertext = data
        if data.count > ivSize {
            ivData = data.subdata(in: 0..<ivSize)
            ciphertext = data.subdata(in: ivSize..<data.count)
        }

        // Allocate output buffer sized to ciphertext + one block for padding
        let clearLength = ciphertext.count + ivSize
        var clearData = Data(count: clearLength)

        var numBytesDecrypted: size_t = 0
        let options = CCOptions(kCCOptionPKCS7Padding)

        let cryptStatus = clearData.withUnsafeMutableBytes { cryptBytes in
            ciphertext.withUnsafeBytes { cipherBytes in
                keyData.withUnsafeBytes { keyBytes in
                    // If we have an IV, call CCCrypt with the IV pointer, otherwise pass nil
                    if let iv = ivData {
                        return iv.withUnsafeBytes { ivBytes in
                            CCCrypt(CCOperation(kCCDecrypt),
                                    CCAlgorithm(kCCAlgorithmAES128),
                                    options,
                                    keyBytes.baseAddress, keyLength,
                                    ivBytes.baseAddress,
                                    cipherBytes.baseAddress, ciphertext.count,
                                    cryptBytes.baseAddress, clearLength,
                                    &numBytesDecrypted)
                        }
                    } else {
                        return CCCrypt(CCOperation(kCCDecrypt),
                                        CCAlgorithm(kCCAlgorithmAES128),
                                        options,
                                        keyBytes.baseAddress, keyLength,
                                        nil,
                                        cipherBytes.baseAddress, ciphertext.count,
                                        cryptBytes.baseAddress, clearLength,
                                        &numBytesDecrypted)
                    }
                }
            }
        }

        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            clearData.count = numBytesDecrypted
        } else {
            print("Decryption failed")
            return nil
        }

        return clearData
    }
}
