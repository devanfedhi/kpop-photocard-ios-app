//
//  TabBarViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 14/5/2024.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        

    }


}
