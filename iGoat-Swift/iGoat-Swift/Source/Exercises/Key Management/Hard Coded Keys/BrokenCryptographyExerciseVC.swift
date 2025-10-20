import UIKit
import Security

func pathDocumentDirectory(fileName: String) -> String {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                            .userDomainMask, true)[0]
    return documentsPath + "/\(fileName)"
}

func getOrCreateKey() -> Data {
    let service = "com.owasp.iGoat.encryptionKey"
    let account = "encryptionKey"
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess, let existing = item as? Data {
        return existing
    }

    var keyData = Data(count: 32)
    let result = keyData.withUnsafeMutableBytes { ptr -> Int32 in
        guard let baseAddress = ptr.baseAddress else { return -1 }
        return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
    }
    if result != errSecSuccess {
        // fallback: use UUID repeated/padded to reach 32 bytes
        var fallback = Data(UUID().uuidString.utf8)
        while fallback.count < 32 {
            fallback.append(fallback)
        }
        return fallback.subdata(in: 0..<32)
    }

    let addQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecValueData as String: keyData
    ]
    SecItemAdd(addQuery as CFDictionary, nil)
    return keyData
}

class BrokenCryptographyExerciseVC: UIViewController {
    // Do not hardcode keys. Obtain from Keychain-backed generator.
    var encryptionKey: Data {
        return getOrCreateKey()
    }
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func showItemPressed() {
        
         UIAlertController.showAlertWith(title: "BrokenCryptography", message: "Try Harder!")
 
       /* let encryptedFilePath = pathDocumentDirectory(fileName: "encrypted")
        let encryptedFilePathURL = URL(fileURLWithPath: encryptedFilePath)
        guard let encryptedData = try? Data(contentsOf: encryptedFilePathURL)  else {
            return
        }
        
        let encryptionKeyData = encryptionKey
        let decryptedData = encryptedData.aes(operation: kCCDecrypt, keyData: encryptionKeyData!)
        let decryptedPassword = String(data: decryptedData, encoding: .utf8) ?? ""
        print(decryptedPassword)
        UIAlertController.showAlertWith(title: "BrokenCryptography", message: decryptedPassword) */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let password = "b@nkP@ssword123"
        passwordTextField.text = password
        let data = password.data(using: .utf8)
        print(data!)
        
        let encryptionKeyData = encryptionKey
        let encryptedData = data?.aes(operation: kCCEncrypt, keyData: encryptionKeyData!)
        let url = URL(fileURLWithPath: pathDocumentDirectory(fileName: "encrypted"))
        try? encryptedData?.write(to: url, options: .atomic)
    }
}
