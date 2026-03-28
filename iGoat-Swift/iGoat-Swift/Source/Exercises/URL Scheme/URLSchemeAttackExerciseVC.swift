
import UIKit

class URLSchemeAttackExerciseVC: UIViewController {
    @IBOutlet weak var mobileNumberTxtField: UITextField!
    @IBOutlet weak var messageTxtField: UITextField!

    @IBAction func sendMessageItemPressed() {
        let mobileNoText = mobileNumberTxtField.text ?? ""
        let messageText = messageTxtField.text ?? ""
        
        var url: URL? = nil
        if var components = URLComponents(string: "iGoat://") {
            components.queryItems = [
                URLQueryItem(name: "contactNumber", value: mobileNoText),
                URLQueryItem(name: "message", value: messageText)
            ]
            url = components.url
        }

        let app = UIApplication.shared
        if let url = url,
            app.canOpenURL(url) == true
        {
            if #available(iOS 10.0, *) {
                app.open(url, options: [:], completionHandler: nil)
            } else {
                app.openURL(url)
            }
        }
    }
}
