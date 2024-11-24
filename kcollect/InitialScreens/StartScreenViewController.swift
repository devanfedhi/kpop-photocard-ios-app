//
//  StartScreenViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 3/5/2024.
//

import UIKit
import FirebaseAuth

// The starting screen for the application
class StartScreenViewController: UIViewController {
    
    @IBOutlet weak var logo: UIImageView!
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Checks if the display is dark mode/light mode
        checkUserInterfaceStyle()
        
    }
    
    // Whenever app makes a switch from dark mode to light mode, we need to update the image
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            checkUserInterfaceStyle()
        }
    }
    
    // Image changes depending on if app is currently on dark mode or light mode
    func checkUserInterfaceStyle() {
        if traitCollection.userInterfaceStyle == .dark {
            logo.image = UIImage(named: "BlackLogo")
        } else {
            logo.image = UIImage(named: "WhiteLogo")
        }
    }
    
    // Check if the user is already logged onto Firebase. If it has, then we can immediately navigate to the home screen (also update our database controller of the logged in user)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let user = Auth.auth().currentUser {
            databaseController?.currentUser = user
            databaseController?.userLoggedIn = true
            self.performSegue(withIdentifier: "showHomeSegue3", sender: nil)
        } 
        navigationController?.setNavigationBarHidden(false, animated: animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    

    
    

}
