//
//  HelpTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 31/5/2024.
//

import UIKit

// This class is to display to the user any helpful information for a given set of pages (tab on a tab bar)
class HelpTableViewController: UITableViewController {
    
    var info: [[String]] = [[]]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Height needs to be adjustable since length of text varies
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0

    }

    // MARK: Table View Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return info.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "helpCell", for: indexPath) as! AcknowledgementsTableViewCell
        
        if info.count == 0 {
            return cell
        }

        cell.libraryLabel.text = self.info[indexPath.row][0]
        cell.libraryText.text = self.info[indexPath.row][1]
        
        // The title and text needs to "wrap" around if it is too long
        cell.libraryLabel?.numberOfLines = 0
        cell.libraryLabel?.lineBreakMode = .byWordWrapping
        
        cell.libraryText?.numberOfLines = 0
        cell.libraryText?.lineBreakMode = .byWordWrapping


        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}
