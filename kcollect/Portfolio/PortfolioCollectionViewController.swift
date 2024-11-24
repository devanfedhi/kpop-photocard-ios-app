//
//  PortfolioCollectionViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 3/5/2024.
//

import UIKit

// This class displays all of a users photocards in a single portfolio (collection view).
class PortfolioCollectionViewController: UICollectionViewController, DatabaseListener, UISearchResultsUpdating {
    
    let info =   [[
                    "Portfolio",
                    """
                    This page displays all of your photocards in a centralised location.
                    """
                ],[
                    "Adding a photocard to your portfolio",
                    """
                    Want to add a photocard to your portfolio? Simply click the '+' button on the top right of the screen.
                    
                    In order to add a photocard to your portfolio, you need to select the group, idol and album of the photocard, as well as a photo of the photocard, which you can either take or choose from your camera roll.
                    
                    When searching for the photocard's group, idol or album in the add photocard page, you may swipe down to search from the list of currently available idol data.
                    """
                ],[
                    "Managing and searching through your portfolio",
                    """
                    Once a photocard has been added to your portfolio, you can select it on the portfolio page to favourite the photocard and change the photo. If you want to edit the group, idol or album information, delete the photocard and add a new photocard. Note that any deleted photocards will also delete any current sale listings for that photocard.
                    
                    If your portfolio is getting a bit long, simply swipe down to search. You can search by idol name, group name or album name, for your convenience.
                    """
                ]]
    
    
    
    var listenerType: ListenerType = .userPhotocard
    
    let CELL_IMAGE = "imageCell"
    
    let SCOPE_IDOL = 0
    let SCOPE_GROUP = 1
    let SCOPE_ALBUM = 2

    var photocardsList = [Photocard]()
    
    var filteredPhotocards = [Photocard]()

    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        databaseController?.setupUserPhotocardListener()
//        collectionView.backgroundColor = .systemBackground
        collectionView.setCollectionViewLayout(generateLayout(), animated: false)
        
// Do any additional setup after loading the view.

//        Initialise a UISearchController
        let searchController = UISearchController(searchResultsController: nil)
        
//        Delegation using UISearchResultsUpdating as current class
        searchController.searchResultsUpdater = self
        
//        Makes it so the entire background (essentially the entire screen except the search) but uninteractable
        searchController.obscuresBackgroundDuringPresentation = false
        
//        Placeholder text to make it more understandable for user
        searchController.searchBar.placeholder = "Search Portfolio"
        
        
//        Tell navigationItem that its search controller is the one we just created. This adds search bar to the controller. Search bar initially hidden, swiping down will reveal it
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented
        definesPresentationContext = true

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
//        return photocardsList.count
        return filteredPhotocards.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_IMAGE, for: indexPath) as! PhotocardCollectionViewCell
        cell.backgroundColor = .secondarySystemFill
    
        cell.imageView.image = filteredPhotocards[indexPath.row].image
        cell.photocardLabel.text = filteredPhotocards[indexPath.row].idolName
        return cell
    }
    
    func generateLayout() -> UICollectionViewLayout {
        // Define item size with desired aspect ratio
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0))
        
        // Create item
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        // Define group size
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1/1.75)) // Adjust height dimension to desired height
        
        // Create group
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        // Create section
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 2 // Spacing between groups
        
        // Create layout with section
        return UICollectionViewCompositionalLayout(section: section)
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
    
    // Whenever we segue to a new page, we may need to send some data stored on this page
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHelp" {
            let destination = segue.destination as! HelpTableViewController
            
            destination.info = info
            
        } else if segue.identifier == "showAddPhotocardSegue" {
            databaseController?.setupUserPhotocardListener()
            
                // In this case, we need to send over the photocard of the cell that was selected to the photocard details page
        } else if segue.identifier == "showPhotocardDetails" {
            if let cell = sender as? UICollectionViewCell, let indexPath = collectionView.indexPath(for: cell) {
                let destination = segue.destination as! PhotocardDetailsTableViewController
                
                let photocard = self.filteredPhotocards[indexPath.row]
                
                destination.photocard = photocard
                destination.image = photocard.image
                destination.favourite = photocard.favourite

            }

            // In this case, we need to send over the photocard of the cell that was selected to the create sale listing page
        } else if segue.identifier == "showAddSaleSegue" {
            if let cell = sender as? UICollectionViewCell, let indexPath = collectionView.indexPath(for: cell) {
                let destination = segue.destination as! CreateSaleListingTableViewController
                
                let photocard = self.filteredPhotocards[indexPath.row]
                
                destination.photocard = photocard
                
            }

        }
    }

    // MARK: Search Controller methods

    // Called whenever a search has been made, and if so, apply the appropriate filters
    func updateSearchResults(for searchController: UISearchController) {
        
//        Check there is search text to be accessed
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
//        Ensures scope bar only visible once search button is clicked
        searchController.searchBar.showsScopeBar = true
        
        // Users can search based on idol name, group name or album name
        searchController.searchBar.scopeButtonTitles = ["Idol","Group","Album"]
        
    
        // Check that there is a search term, by checking if string length > 0. If it is, then apply a filter, otherwise, just return the whole list of photocards
        if searchText.count > 0 {
            
            switch searchController.searchBar.selectedScopeButtonIndex {
            case SCOPE_IDOL:
                filteredPhotocards = photocardsList.filter { (photocard: Photocard) -> Bool in
                    return photocard.idolName?.lowercased().contains(searchText) ?? false
                }
            case SCOPE_GROUP:
                filteredPhotocards = photocardsList.filter { (photocard: Photocard) -> Bool in
                    return photocard.groupName?.lowercased().contains(searchText) ?? false
                }
            case SCOPE_ALBUM:
                filteredPhotocards = photocardsList.filter { (photocard: Photocard) -> Bool in
                    return photocard.albumName?.lowercased().contains(searchText) ?? false
                }
            default:
                return
            }
            
        } else {
            searchController.searchBar.showsScopeBar = false
            filteredPhotocards = photocardsList
        }
        
        
        //        Reload table once new list of albums have been obtained
        collectionView.reloadData()
    }
    
    // MARK: Used Listeners
    
    // Called whenever there is an update to the photocards a user owns
    func onUserPhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {
        self.photocardsList = allPhotocards
        self.filteredPhotocards = allPhotocards
        collectionView.reloadData()
    }
    
    // MARK: Unused Listeners
    
    func onBiasIdolSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onBiasGroupSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?) {}
    
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?) {}
    
    func onAlbumChange(change: DatabaseChange, allAlbums: [String]) {}
    
    
    
}


