//
//  RegisterViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 3/5/2024.
//

import UIKit
import FirebaseAuth

// This class is for the register screen
class RegisterViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?

    //    Ensure the email and pass entered is valid.
    @IBAction func registerButton(_ sender: Any) {
        guard let email = validateEmail() else {
            displayMessage(title: "Error", message: "Please enter a valid email")
            return
        }
        
        guard let pass = validatePass() else {
            displayMessage(title: "Error", message: "Please enter a valid password")
            return
        }
        
        guard let name = validateName() else {
            displayMessage(title: "Error", message: "Please enter a valid name, less than 10 characters and only containing letters and numbers")
            return
        }
        
        // If email and pass is valid, attempt creating a new account
        authRegister(email: email, pass: pass, name: name)
        
    }
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //        When view loads ensure email and pass are empty
        emailField.text = ""
        passField.text = ""
        
        passField.textContentType = .init(rawValue: "")
    
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // If a user is currently logged in, then we can immediately segue to the home screen
        Auth.auth().addStateDidChangeListener{ auth,user in
            if let user = user{
                self.performSegue(withIdentifier: "showHomeSegue2", sender: nil)
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
    
    // Name validation using regex symbols
    func validateName() -> String? {
        let nameRegex = "^[a-zA-Z0-9]*$"
        let name = nameField.text ?? ""
        
        let nameTest = NSPredicate(format:"SELF MATCHES %@", nameRegex)
        
        if nameTest.evaluate(with: name) && !name.isEmpty && name.count < 10 {
            return name
        } else {
            return nil
        }
    }

    // MARK: View Controller Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        When view loads ensure email and pass are empty
        emailField.text = ""
        passField.text = ""
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(self)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // We attempt a register to firebase
    func authRegister(email: String, pass: String, name: String)  {
        Task {

            do {
                let registerAttempt = try await Auth.auth().createUser(withEmail: email, password: pass)
                
                //                If successfull, tell database controller of the new user
                databaseController?.currentUser = registerAttempt.user
                
                databaseController?.setupHomeBiasListener()

                databaseController?.setupUser(name: name)
                    
                databaseController?.userLoggedIn = true
                
                
            } catch {
                
                //                This must mean login failed
                databaseController?.currentUser = nil
                
                databaseController?.userLoggedIn = false
        
                displayMessage(title: "Error", message: "Firebase Authentication Failed with Error:\(String(describing: error))")

            }
        }
    }

}
