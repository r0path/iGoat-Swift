
import UIKit

class NSUserDefaultsStorageExerciseVC: UIViewController {
    @IBOutlet weak var textfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storeInDefaults()
    }

    func storeInDefaults() {
        // Store the PIN securely in the Keychain instead of UserDefaults
        let keychainItem = KeychainPasswordItem(service: "iGoat.PinService", account: "PIN")
        try? keychainItem.savePassword("53cr3tP")
    }
    
    @IBAction func verifyItemPressed() {
        if textfield.text?.isEmpty == true || textfield.text == "" {
            UIAlertController.showAlertWith(title: "Error", message: "Enter details!")
        } else if
            let pin = try? KeychainPasswordItem(service: "iGoat.PinService", account: "PIN").readPassword(),
            pin == textfield.text {
            textfield.text = ""
            UIAlertController.showAlertWith(title: "Success",
                                                message: "Congrats! You're on right track.")
        } else {
            UIAlertController.showAlertWith(title: "Invalid!", message: "Try harder!!")
        }
    }
}
