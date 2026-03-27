import UIKit

class CrossSiteScriptingExerciseVC: UIViewController {
    @IBOutlet weak var webview: UIWebView!
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func loadItemPressed() {
        let userInput = textField.text ?? ""
        let escapedInput = userInput
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
        let webText = "Welcome to XSS Exercise !!! \n Here is UIWebView ! \(escapedInput)"
        webview.loadHTMLString(webText, baseURL: nil)
    }
}
