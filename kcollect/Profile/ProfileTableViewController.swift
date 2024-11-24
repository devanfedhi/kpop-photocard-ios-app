//
//  ProfileTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit

// This class is for the profile of the current user
class ProfileTableViewController: UITableViewController, GroupChangeDelegate, IdolChangeDelegate, DatabaseListener, PhotocardSelectedDelegate {
    
    let info =   [[
                    "Profile",
                    """
                    This page displays your personalised profile!
                    
                    You can also navigate to the settings screen if you want to sign out or view the third party libraries used for the app. You can also reset your bias idol or group to none on the settings page.
                    """
                ],[
                    "Bias selection",
                    """
                    On this page, you can set a bias (favourite group and idol), showing off to other users what you admire. Any biases that are selected will modify what you see on the home page! The home page will try to display any market listings for your relevant bias idol and group, if they have been set. If no biases have been set, it will simply display some other hot market listings you may enjoy.
                    """
                ],[
                    "Favourite photocards",
                    """
                    Any favourited photocards will also be displayed on this page. There is no limit on how many photocards you can display, so feel free to showcase to all your friends your most favourite photocards. You can make changes to any favourited photocards directly on the profile page by selecting the photocard. You can also view your entire portfolio on this page, just in case you want to quickly select which photocards to favourite!
                    """
                ]]



    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .profile
    
    let SECTION_USER = 0
    let SECTION_FAVIDOL = 1
    let SECTION_FAVGROUP = 2
    let SECTION_FAVPHOTOCARDS = 3
    
    let CELL_USER = "userCell"
    let CELL_FAVIDOL = "favIdolCell"
    let CELL_FAVGROUP = "favGroupCell"
    let CELL_FAVPHOTOCARDS = "favPhotocardsCell"
    
    var favouriteIdol: String?
    
    var favouriteGroup: String?
    
    var allFavouritePhotocard = [Photocard]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // We need to set up the profile, that is, fetch the bias idol/group of the current user. We also need to make the API call again as this data will be used when a user makes a bias selection
        databaseController?.setupProfileSettingsListener()
        databaseController?.startSearch()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 45
        tableView.reloadData()

    }

    // MARK: View Controller Methods
    
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHelp" {
            let destination = segue.destination as! HelpTableViewController
            
            destination.info = info
            
            // Delegation is required when segueing to the two table view controllers  below since this view controller needs to know any updates for the group/idol selected
        } else if segue.identifier == "showGroupSelect" {
            let destination = segue.destination as! GroupTableViewController
                        
            destination.delegate = self

        } else if segue.identifier == "showIdolSelect" {
            let destination = segue.destination as! IdolTableViewController
                        
            destination.delegate = self

            destination.showAllIdols = true
            
//        This segue occurs whenever a favourite photocard is selected. If it is, we need to tell the photocard details table view controller which photocard has been selected
        } else if segue.identifier == "showPhotocardDetails" {
            if let photocard = sender as? Photocard {
                let destination = segue.destination as! PhotocardDetailsTableViewController
                
                destination.photocard = photocard
                destination.image = photocard.image
                destination.favourite = photocard.favourite

            }

        }
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        tableView.reloadData()
        
        // This will ask firebase to fetch all of the users favourited photocards to be displayed on the profile
        databaseController?.setupFavouritePhotocardsListener()

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
   
    }
    
    // MARK: Table View Methods
    
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
    
    // Create the content for the cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_USER {
            // For the user cell, we simply just use their email address, stored in the User
            let userCell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath)
            
            var content = userCell.defaultContentConfiguration()

            content.text = databaseController?.currentUser?.email
            
            userCell.contentConfiguration = content
            
            userCell.backgroundColor = UIColor(named: "CellBackground")
            
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
            
            // The last cell is the favourite photocard cell, which will hold a collection view of all of the favourite photocards
            
            // Delegation is needed so that this controller knows when a specific photocard is selected by the user.
            
            // During this step, we also tell the cell all the favourite photocards to be displayed
        } else {
            let favouritePhotocardsCell = tableView.dequeueReusableCell(withIdentifier: CELL_FAVPHOTOCARDS, for: indexPath) as! FavouritePhotocardsTableViewCell
            favouritePhotocardsCell.allFavouritePhotocard = self.allFavouritePhotocard
            
            favouritePhotocardsCell.delegate = self
            
            return favouritePhotocardsCell
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
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
                return "ⓘ Tap on the right arrow to favourite some photocards"
            }
            
            return "ⓘ Tap to see your favourite photocard!"
            
            
        } else if section == SECTION_FAVGROUP {
            return "ⓘ Tap to change your bias"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == SECTION_USER {
            return nil
        }
        return indexPath
    }
    
    // MARK: Delegation Methods
    
    // This will tell the current view controller if the favourite group of the user has changed, and if so, handle it appropriately
    func changedToGroup(_ group: Group) {
        
        databaseController?.addFavGroup(group)
        onFavGroupChange(change: .update, group: GroupSingle(name: group.name))

    }
    
    
    // This will tell the current view controller if the favourite idol of the user has changed, and if so, handle it appropriately
    func changedToIdol(_ idol: Idol) {
        
        databaseController?.addFavIdol(idol)
        onFavIdolChange(change: .update, idol: IdolSingleGroup(name: idol.name, group: idol.group.name))
    }
    
    // This will tell the current view controller which favourite photocard was selected and perform the segue to the photocard details screen
    func photocardSelected(_ photocard: Photocard) {
        self.performSegue(withIdentifier: "showPhotocardDetails", sender: photocard)
    }

    // MARK: Used Listeners
    
    // Any updates to the users favourite photocards will call this method and tell this view controller the users favourite photocards (so far)
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {
        self.allFavouritePhotocard = allPhotocards
        tableView.reloadData()
    }
    
    // Any changed to the users favourite group will call this method and change the favourite group as displayed on this screen
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?) {
        
        if let group = group {
            favouriteGroup = group.name
        } else {
            favouriteGroup = "N/A"
        }
    
        
        tableView.reloadData()
    }
    
    // Any changed to the users favourite idol will call this method and change the favourite idol as displayed on this screen
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?) {
        
        if let idol = idol {
            favouriteIdol = "\(idol.name) (\(idol.group))"
        } else {
            favouriteIdol = "N/A"
        }
        
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
