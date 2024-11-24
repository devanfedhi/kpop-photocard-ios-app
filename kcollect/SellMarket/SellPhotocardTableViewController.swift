//
//  SellPhotocardTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 9/5/2024.
//

import UIKit


// This view controller will display all of the photocards the current users currently has on sale on the market
class SellPhotocardTableViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating {
    
    let info =   [[
                    "Sell Market",
                    """
                    This page displays all of your current photocard sale listings on the market. 
                    """
                ],[
                    "Making a sale",
                    """
                    Want to sell one of your photocards? Simply tap the '+' button on the top right of the screen. You will be navigated to the portfolio page so that you can select which photocard you want to sell. Simply tap on the photocard to create the sale listing. If there are too many photocards in your portfolio, you can swipe down to search your entire portfolio by group, idol or album.
                    
                    Once a photocard has been selected, you need to define a price, location and condition of the photocard. The price has to be between $0 and $10000. When selecting a location, you can either search (by swiping down), holding down on any location of the map, or optionally, enable location services so that you can automatically navigate to your current (approximate) location.
                    
                    Once all of these criteria has been, you can select save to create the sale listing. If you selected a photocard that already had a sale listing, the new sale listing will overwrite the old sale listing.
                    """
                ],[
                    "Modifying a sale and searching through your sale listings",
                    """
                    You can modify the price, location and condition of any of your current sale listings by selecting the sale listing on the sell market page, making the changes and then selecting 'Save' on the top right corner. You can also delete a sale listing on this page by clicking on the red trash icon on the rop right corner.
                    
                    You can also search by group, idol and album on the sell market page in order to search through all your current market listings.
                    
                    Swiping left on any cell will also delete the sale listing.
                    """
                    ]]
    
    
    weak var databaseController: DatabaseProtocol?
    
    let SCOPE_IDOL = 0
    let SCOPE_GROUP = 1
    let SCOPE_ALBUM = 2
    
    var listenerType: ListenerType = .userSales
    
    let SECTION_SALELISTING = 0
    
    let CELL_SALELISTING = "cellSaleListing"
    
    var saleListingList = [SaleListing]()
    var filteredSaleListingList = [SaleListing]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        databaseController?.setupUserSaleListingListener()
        
        tableView.reloadData()
        
        // The height of each row is pre-defined, since the photocard image and the nested tableview is also pre-defined height
        tableView.rowHeight = CGFloat(300)

        // Initialise the search controller and add it to the navigation item
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Market"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        self.view.backgroundColor = UIColor(named: "Background")
    }

    // MARK: Table View Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredSaleListingList.count
    }
    
    // Create the content for each each sale listing cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let saleCell = tableView.dequeueReusableCell(withIdentifier: CELL_SALELISTING, for: indexPath) as! SaleListingTableViewCell
        
        let saleListing = self.filteredSaleListingList[indexPath.row]
        
        // Tell the cell which sale listing it is associated to, as well as the image of that sale listing
        
        saleCell.saleListing = saleListing
        
        saleCell.tableView.reloadData()
        
        saleCell.photocardImage.image = saleListing.photocard.image
        
        return saleCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Sale listings can also be deleted by swiping on the sale listing cell
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == SECTION_SALELISTING {
            let saleListing = self.filteredSaleListingList[indexPath.row]
            self.databaseController?.deleteSaleListing(saleListing)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "ⓘ Tap + to create a new sale listing"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if !self.saleListingList.isEmpty {
            return "ⓘ Tap a photocard to show or edit sale details"
        }
        return nil
        
    }
    
    // MARK: View Controller Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHelp" {
            let destination = segue.destination as! HelpTableViewController
            
            destination.info = info
            
            // Whenever the user wants to edit a sale listing, we need to let the sale listing view controller know what sale listing, photocard and sale listing details it is associated with.
            
        } else if segue.identifier == "showAddSaleSegue" {
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                let destination = segue.destination as! CreateSaleListingTableViewController
                
                let saleListing = self.filteredSaleListingList[indexPath.row]
                
                destination.saleListing = saleListing
                
                destination.photocard = saleListing.photocard
                
                destination.photocardPrice = saleListing.price
                destination.photocardLocation = saleListing.location
                destination.photocardCondition = saleListing.condition
                
                destination.navigationItem.title = "Edit Sale Listing"
                
                // We also want to display the trash button so that users can choose to delete the sale listing if they wish
                destination.trashButton.isHidden = false
                
            }

        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
   
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
        
    
        // Check that there is a search term, by checking if string length > 0. If it is, then apply a filter, otherwise, just return the whole list of sale listings
        if searchText.count > 0 {
            
            switch searchController.searchBar.selectedScopeButtonIndex {
            case SCOPE_IDOL:
                filteredSaleListingList = saleListingList.filter { (saleListing: SaleListing) -> Bool in
                    return saleListing.photocard.idolName?.lowercased().contains(searchText) ?? false
                }
            case SCOPE_GROUP:
                filteredSaleListingList = saleListingList.filter { (saleListing: SaleListing) -> Bool in
                    return saleListing.photocard.groupName?.lowercased().contains(searchText) ?? false
                }
            case SCOPE_ALBUM:
                filteredSaleListingList = saleListingList.filter { (saleListing: SaleListing) -> Bool in
                    return saleListing.photocard.albumName?.lowercased().contains(searchText) ?? false
                }
            default:
                return
            }
            
        } else {
            searchController.searchBar.showsScopeBar = false
            filteredSaleListingList = saleListingList
        }
        
        
        //        Reload table once new list of sale listings have been obtained
        tableView.reloadData()
    }
    
    // MARK: Used Listeners
    
    // Whenever we obtain new sale listings to display on this page, we call this method to inform this view controller of the new updated sale listings. These updates are generally the result of fetch calls from Firebase, called in the database controller
    func onUserSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {
        self.saleListingList = allSaleListings
        self.filteredSaleListingList = allSaleListings
        tableView.reloadData()
    }
    
    // MARK: Unused Listeners
    
    func onBiasIdolSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onBiasGroupSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onAlbumChange(change: DatabaseChange, allAlbums: [String]) {}
    
    func onUserPhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?) {}
    
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?) {}
    
    

}
