//
//  UIViewController+displayMessage.swift
//  LAB03
//
//  Created by Devan Fedhi on 10/3/2024.
//

import UIKit


// Provides view controllers a displayMessage() function, that allows it to display a message.
extension UIViewController {
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
}

