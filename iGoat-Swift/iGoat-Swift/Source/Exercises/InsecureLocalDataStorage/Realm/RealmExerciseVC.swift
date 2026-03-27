
import UIKit
import Realm

class RCreditInfo: RLMObject {
    @objc dynamic var name:String?
    @objc dynamic var cardNumber:String?
    @objc dynamic var cvv:String?
}

class RealmExerciseVC: UIViewController {
    
    @IBOutlet weak var creditNameTextField: UITextField!
    @IBOutlet weak var creditNumberTextField: UITextField!
    @IBOutlet weak var creditCVVTextField: UITextField!
    
    let RealmCardName = "John Doe";
    let RealmCardNumber = "4444 5555 8888 1111";
    let RealmCardCVV = "911";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try saveData()
        } catch {
            print("Error writing data")
        }
    }

    func saveData() throws {
        // Do not persist sensitive credit card data to disk.
        // Keep the sample credit card data only in memory via constants.
        return
    }
    
    @IBAction func verifyItemPressed() {
        let isVerified = verifyName(name: creditNameTextField.text!, number: creditNumberTextField.text!, cvv: creditCVVTextField.text!)
        let message = isVerified ? "Success" : "Failed"
        UIAlertController.showAlertWith(title: "iGoat", message: message)
    }
    
    func verifyName(name:String, number:String, cvv:String) -> Bool {
        // Compare against in-memory sample data instead of reading sensitive data from local storage.
        let storedName = RealmCardName
        let storedNumber = RealmCardNumber.replacingOccurrences(of: " ", with: "")
        let storedCVV = RealmCardCVV

        return name == storedName &&
            number.replacingOccurrences(of: " ", with: "") == storedNumber &&
            cvv == storedCVV
    }
}
