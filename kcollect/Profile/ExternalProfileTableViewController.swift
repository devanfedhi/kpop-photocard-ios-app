//
//  ExternalProfileTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit

// This class is for the external profile of the a user that isn't the current user
class ExternalProfileTableViewController: UITableViewController, DatabaseListener, PhotocardSelectedDelegate {
    
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .externalProfile
    
    let SECTION_USER = 0
    let SECTION_FAVIDOL = 1
    let SECTION_FAVGROUP = 2
    let SECTION_FAVPHOTOCARDS = 3
    
    let CELL_USER = "userCell"
    let CELL_FAVIDOL = "favIdolCell"
    let CELL_FAVGROUP = "favGroupCell"
    let CELL_FAVPHOTOCARDS = "favPhotocardsCell"
    
    var user: User?
    
    var favouriteIdol: String?
    
    var favouriteGroup: String?
    
    var allFavouritePhotocard = [Photocard]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 45
        
        tableView.reloadData()
        
        self.view.backgroundColor = UIColor(named: "Background")
    }
    
    
    // MARK: View Controller Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
   
    }
    
    // When segueing to photocard details, we need to let it know the photocard that was selected
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotocardDetails" {
            if let photocard = sender as? Photocard {
                let destination = segue.destination as! ExternalPhotocardDetailsTableViewController
                destination.photocard = photocard
            }
        }
    }
    
    // MARK: Table View Controller Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_USER:
            return 1
        case SECTION_FAVIDOL:
            return 1
        case SECTION_FAVGROUP:
            return 1
        case SECTION_FAVPHOTOCARDS:
            return 1
        default:
            return 0
        }
    }
    
    // Create the content for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // For the user cell, we simply just use their email address, stored in the User
        if indexPath.section == SECTION_USER {

            let userCell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath)
            
            var content = userCell.defaultContentConfiguration()
            
            content.text = user?.userName ?? ""
            
            userCell.contentConfiguration = content
            
            return userCell
            
            // favouriteIdol and favouriteGroup still store the favourite idol and group of the user. This was found during setup
        } else if indexPath.section == SECTION_FAVIDOL {
            
            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_FAVIDOL, for: indexPath)
    
            
            idolCell.textLabel?.text = "Favourite Idol:"
            
            if let idol = favouriteIdol {
                idolCell.detailTextLabel?.text = idol
            } else {
                idolCell.detailTextLabel?.text = "N/A"
            }
            
            return idolCell
            
        } else if indexPath.section == SECTION_FAVGROUP {
            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_FAVGROUP, for: indexPath)
    
            groupCell.textLabel?.text = "Favourite Group:"
            
            if let group = favouriteGroup {
                groupCell.detailTextLabel?.text = group
            } else {
                groupCell.detailTextLabel?.text = "N/A"
            }
            
            return groupCell
            
        } else {
            // The last cell is the favourite photocard cell, which will hold a collection view of all of the favourite photocards
            
            // Delegation is needed so that this controller knows when a specific photocard is selected by the user.
            
            // During this step, we also tell the cell all the favourite photocards to be displayed
            let favouritePhotocardsCell = tableView.dequeueReusableCell(withIdentifier: CELL_FAVPHOTOCARDS, for: indexPath) as! FavouritePhotocardsTableViewCell
            favouritePhotocardsCell.allFavouritePhotocard = self.allFavouritePhotocard
            
            favouritePhotocardsCell.delegate = self
            
            return favouritePhotocardsCell
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    // Photocard cell is a pre-defined height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == SECTION_FAVPHOTOCARDS {
            return 230
        } else {
            return -1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        
        if section == SECTION_FAVPHOTOCARDS {
            return "Favourite Photocards"
            
        } else if section == SECTION_FAVIDOL {
            return "Your Biases"
        }
        
        return nil

    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_FAVPHOTOCARDS {
            if self.allFavouritePhotocard.count == 0 {
                return "ⓘ This user has no favourite photocards..."
            }
            
            return "ⓘ Tap a photocard to see more details"
        }
        
        return nil
    }
    
    
    
    // MARK: Delegation Methods

    // This will tell the current view controller a specific photocard was selected and hence, allow it to perform a segue to photocard details with the photocard as its sender
    func photocardSelected(_ photocard: Photocard) {
        self.performSegue(withIdentifier: "showPhotocardDetails", sender: photocard)
    }
    
    // MARK: Used Listeners
    
    // Any updates to the users favourite photocards will call this method and tell this view controller the users favourite photocards (so far)
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {
        self.allFavouritePhotocard = allPhotocards
        tableView.reloadData()
    }
    
    // When the user's favourite group is fetched from Firebase, this method will update this view controller on which group it is
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?) {
        
        guard let group = group else {
            return
        }
        favouriteGroup = group.name
        tableView.reloadData()
    }
    
    // When the user's favourite idol is fetched from Firebase, this method will update this view controller on which idol it is
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?) {
        
        guard let idol = idol else {
            return
        }
        
        favouriteIdol = "\(idol.name) (\(idol.group))"
        tableView.reloadData()
    }
    
    // MARK: Unused Listeners
    
    func onBiasIdolSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onBiasGroupSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onAlbumChange(change: DatabaseChange, allAlbums: [String]) {}
    
    func onUserPhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
}
