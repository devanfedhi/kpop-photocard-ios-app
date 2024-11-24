//
//  LoginViewController.swift
//  LAB03
//
//  Created by Devan Fedhi on 7/4/2024.
//

import UIKit
import FirebaseAuth


// This class is for the login screen
class LoginViewController: UIViewController {
    
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    weak var databaseController: DatabaseProtocol?
    
    
    //    Ensure the email and pass entered is valid.
    @IBAction func loginButton(_ sender: Any) {
        guard let email = validateEmail() else {
            displayMessage(title: "Error", message: "Please enter a valid email")
            return
        }
        
        guard let pass = validatePass() else {
            displayMessage(title: "Error", message: "Please enter a valid password")
            return
        }
        
        // If email and pass is valid, attempt a login
        authLogin(email: email, pass: pass)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
//      When view loads ensure email and pass are empty
        emailField.text = ""
        passField.text = ""
        
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // If a user is currently logged in, then we can immediately segue to the home screen
        Auth.auth().addStateDidChangeListener{ auth,user in
            if let user = user{
                print("SHOWING HOME FROM LOGIN")
                self.performSegue(withIdentifier: "showHomeSegue", sender: nil)
            }
        }
        
    }
    
    // MARK: Miscellaneous Methods
//    Email validation using regex symbols
    func validateEmail() -> String? {
        guard let email = emailField.text, email.isEmpty == false else {
            return nil
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if emailPredicate.evaluate(with: email) {
            return email
        }
        
        return nil
        
    }
    
//    Password validation
    func validatePass() -> String? {
        guard let pass = passField.text, pass.isEmpty == false else {
            return nil
        }
        
        return pass
    }

    // MARK: View Controller Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // When view loads ensure email and pass are empty
        emailField.text = ""
        passField.text = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Auth.auth().removeStateDidChangeListener(self)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // We attempt a login to firebase
    func authLogin(email: String, pass: String) {
        Task {
            do {
                
                let loginAttempt = try await Auth.auth().signIn(withEmail: email, password: pass)
                
//                If successfull, tell database controller of the new user
                databaseController?.currentUser = loginAttempt.user
            
                databaseController?.userLoggedIn = true
            
                
                self.databaseController?.setupHomeBiasListener()
                
                
            }
            catch {
                //                This must mean login failed
                databaseController?.currentUser = nil

                databaseController?.userLoggedIn = false
                
                displayMessage(title: "Error", message: "Login Failed. Invalid Username Or Password.")
                
            }
        }
    }
    
    

}
