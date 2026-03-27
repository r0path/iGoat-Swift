import UIKit
import SQLite3

class SQLInjectionExerciseVC: UIViewController {
    @IBOutlet weak var searchField: UITextField!
    
    @IBAction func search() {
        let dbPath = URL(fileURLWithPath: Bundle.main.resourcePath ?? "").appendingPathComponent("articles.sqlite").absoluteString
        var db: OpaquePointer?
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            UIAlertController.showAlertWith(title: "Snap!", message: "Error opening articles database.")
            return
        }
        
        var searchStr = "%"
        if let text = searchField.text, !text.isEmpty {
            searchStr = "%\(text)%"
        }

        let query = "SELECT title FROM article WHERE title LIKE ? AND premium=0"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            // Bind the user-controlled search string as a parameter to avoid SQL injection
            let searchCString = (searchStr as NSString).utf8String
            let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(stmt, 1, searchCString, -1, SQLITE_TRANSIENT)
        } else {
            // Preparing the statement failed; clean up and return
            sqlite3_finalize(stmt)
            sqlite3_close(db)
            UIAlertController.showAlertWith(title: "Snap!", message: "Error preparing articles query.")
            return
        }
        var articleTitles = [String]()
        while sqlite3_step(stmt) == SQLITE_ROW {
            let title = String(cString: sqlite3_column_text(stmt, 0))
            articleTitles.append(title)
        }
        sqlite3_finalize(stmt)
        sqlite3_close(db)
        
        let sqlInjectionArticlesVC = SQLInjectionArticlesVC(nibName: "SQLInjectionArticlesVC", bundle: nil)
        sqlInjectionArticlesVC.articles = articleTitles
        navigationController?.pushViewController(sqlInjectionArticlesVC, animated: true)
    }
}
