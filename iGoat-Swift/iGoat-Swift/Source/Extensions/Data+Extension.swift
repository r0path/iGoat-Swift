import Foundation
import CommonCrypto
import Security

extension Data{
    func aes(operation: Int = kCCEncrypt, keyData: Data, ivData: Data? = nil) -> Data {
        let blockSize = kCCBlockSizeAES128
        let iv: Data
        var inputData: Data

        if operation == kCCEncrypt {
            if let providedIv = ivData {
                iv = providedIv
            } else {
                var ivBytes = Data(count: blockSize)
                let result = ivBytes.withUnsafeMutableBytes { ptr -> Int32 in
                    guard let base = ptr.baseAddress else { return -1 }
                    return SecRandomCopyBytes(kSecRandomDefault, blockSize, base)
                }
                if result != errSecSuccess {
                    iv = Data(repeating: 0, count: blockSize)
                } else {
                    iv = ivBytes
                }
            }
            inputData = self
        } else {
            // decrypt: if no IV provided, expect it to be prepended to the ciphertext
            if let providedIv = ivData {
                iv = providedIv
                inputData = self
            } else {
                guard self.count > blockSize else { return Data() }
                iv = self.subdata(in: 0..<blockSize)
                inputData = self.subdata(in: blockSize..<self.count)
            }
        }

        let dataLength = inputData.count
        let cryptLength  = size_t(dataLength + kCCBlockSizeAES128)
        var cryptData = Data(count:cryptLength)

        let keyLength = size_t(keyData.count)
        let options = CCOptions(kCCOptionPKCS7Padding)

        var numBytesEncrypted :size_t = 0

        let cryptStatus = cryptData.withUnsafeMutableBytes {cryptBytes in
            inputData.withUnsafeBytes {dataBytes in
                iv.withUnsafeBytes {ivBytes in
                    keyData.withUnsafeBytes {keyBytes in
                        CCCrypt(CCOperation(operation),
                                CCAlgorithm(kCCAlgorithmAES),
                                options,
                                keyBytes.baseAddress, keyLength,
                                ivBytes.baseAddress,
                                dataBytes.baseAddress, dataLength,
                                cryptBytes.baseAddress, cryptLength,
                                &numBytesEncrypted)
                    }
                }
            }
        }

        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
            if operation == kCCEncrypt {
                // prepend IV to ciphertext so it can be used for decryption
                var output = Data()
                output.append(iv)
                output.append(cryptData)
                return output
            }
        } else {
            print("Error: \(cryptStatus)")
            return Data()
        }
        return cryptData
    }
}
