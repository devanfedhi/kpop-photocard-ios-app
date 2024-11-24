//
//  SettingsTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 29/5/2024.
//

import UIKit

// This class is for the settings screen
class SettingsTableViewController: UITableViewController, SettingsDelegate {
    
    
    
    weak var databaseController: DatabaseProtocol?
    
    let SECTION_ACKNOWLEDGEMENTS = 0
    let SECTION_CLEAR_BIAS_IDOL = 1
    let SECTION_CLEAR_BIAS_GROUP = 2
    
    let CELL_ACKNOWLEDGEMENTS = "acknowledgementsCell"
    let CELL_CLEAR_BIAS_IDOL = "biasIdolCell"
    let CELL_CLEAR_BIAS_GROUP = "biasGroupCell"

    // This button action attempts a logout from Firebase. It will also change the view controller at the initial start screen
    @IBAction func signOut(_ sender: Any) {
        databaseController?.authLogout()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginNavController = storyboard.instantiateViewController(identifier: "initialNavigationController")
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        self.view.backgroundColor = UIColor(named: "Background")


    }

    // MARK: Table View Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    // Creates the content for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_ACKNOWLEDGEMENTS {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ACKNOWLEDGEMENTS, for: indexPath)

            cell.textLabel?.text = "Acknowledgements"

            return cell
            
            // Delegation is needed for the two cells below as the cell needs to tell the curent view controller when the button is selected
        } else if indexPath.section == SECTION_CLEAR_BIAS_IDOL {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CLEAR_BIAS_IDOL, for: indexPath) as! DeleteIdolTableViewCell
            
            cell.delegate = self

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CLEAR_BIAS_GROUP, for: indexPath) as! DeleteGroupTableViewCell

            cell.delegate = self

            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_ACKNOWLEDGEMENTS {
            return "Third Party Libraries"
        } else if section == SECTION_CLEAR_BIAS_IDOL {
            return "Data Control"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_ACKNOWLEDGEMENTS {
            return "ⓘ Tap to view details of third party libraries used"
        } else if section == SECTION_CLEAR_BIAS_GROUP {
            return "WARNING: Clears your bias selection"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == SECTION_CLEAR_BIAS_IDOL {
            return nil
        } else if indexPath.section == SECTION_CLEAR_BIAS_GROUP {
            return nil
        }
        return indexPath
    }
    

    // MARK: Delegation Methods
    
    // This tells the current view controller that a user wants to reset their idol bias, which then tells firebase to begin the reset procerss
    func deleteBiasIdol() {
        databaseController?.clearBiasIdol()
        navigationController?.popViewController(animated: true)
    }
    
    // This tells the current view controller that a user wants to reset their group bias, which then tells firebase to begin the reset procerss
    func deleteBiasGroup() {
        databaseController?.clearBiasGroup()
        navigationController?.popViewController(animated: true)
    }
}
