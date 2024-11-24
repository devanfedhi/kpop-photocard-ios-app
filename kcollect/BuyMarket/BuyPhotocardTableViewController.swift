//
//  SellPhotocardTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 9/5/2024.
//

import UIKit


// This view controller will display all of the market listings for the current user to be, excluding sale listings that are their own
class BuyPhotocardTableViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating, LocationUserSelectedDelegate, SortOrderSelected, FilterChangedDelegate {
    
    /*
    Reference: https://www.youtube.com/watch?v=ETS4jI0EaY4&ab_channel=SwiftfulThinking
    
    To implement the filter feature, I used this video tutorial to help me learn how to filter snapshot data from Firebase, including how to set-up a component key to handle filters with multiple conditions
    */
    
    let info =   [[
                    "Buy Market",
                    """
                    On this page, you can search through all the current photocard market listings!
                    
                    """
                ],[
                    "Filtering and Sorting",
                    """
                    To make your search more convenient, you can select the 'Filter' button on the top right of the screen to apply some filters to the photocard that you want, such as the price, condition and date listed. Note that in all of these filters, the maximum price must be larger than the minimum price, the best condition must be better than the worst condition, the latest date must be later than the earliest date. Tap save to apply the filters.
                    
                    Once a filter has been applied, you can sort the listings that are currently on your market. You may sort by price, condition, location or date. Note that any applied filters will automatically wipe out any sorting that you may have applied. As such, please apply the sort after you apply the filter.
                    
                    If there are still too many market listings on your screen, you can continue to filter it down by searching by group, idol and album by swiping down.
                    """
                ],[
                    "Viewing more details of a market listing",
                    """
                    To make a purchase, or see more details for the market listing, tap on the photocard. On this page, as well as the buy market page, you can select the user of the sale listing to view the user's profile or select the location to see the location of the market listing.
                    
                    If the location is selected, you can also optionally enable location services. Once enabled, either when prompted or in your device's settings, you can tap on the navigation button on the top right of the map. This will calculate the approximate distance between you and the sale listing and draw a line between these two points.
                    
                    If the user is selected, you can see the user's biases if they have been set as well as see their favourite photocards, if they have any. You can tap on the photocard to see more details of their favourite photocard
                    """
                ],[
                    "Making a purchase",
                    """
                    To make a purchase, tap on the photocard as you did to view more details of the market listing. Simply tap 'Purchase' on the top right of the screen to make the purchase. This will automatically remove the market listing on the system, remove the photocard from the other user's portfolio as well as add that photocard to your own portfolio.
                    """
                ]]
    

    weak var databaseController: DatabaseProtocol?
    
    var filterPriceLo = Float(0)
    var filterPriceHi = Float(10000)
    
    var filterConditionLo = 0
    var filterConditionHi = 3
    
    var filterDateLo = Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1))!
    var filterDateHi = Calendar.current.date(from: DateComponents(year: 2070, month: 1, day: 1))!
    
    let SCOPE_IDOL = 0
    let SCOPE_GROUP = 1
    let SCOPE_ALBUM = 2
    
    var listenerType: ListenerType = .buyMarket
    
    let SECTION_SALELISTING = 0
    
    let CELL_SALELISTING = "cellSaleListing"
    
    var saleListingList = [SaleListing]()
    var filteredSaleListingList = [SaleListing]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Each buy listing is a predetermined height
        tableView.rowHeight = CGFloat(350)
        
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
    
//    Creates the content for each sale listing
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let saleCell = tableView.dequeueReusableCell(withIdentifier: CELL_SALELISTING, for: indexPath) as! BuySaleListingTableViewCell
        
        let saleListing = self.filteredSaleListingList[indexPath.row]
        
//        We need to tell the cell the relevant sale listing as well as its image
        saleCell.saleListing = saleListing
        
        saleCell.tableView.reloadData()
        
        saleCell.photocardImage.image = saleListing.photocard.image
        
//        Delegation is required so that the cell can tell this view controller if a specific sale listing has been selected, and if it has, this view controller can segue to the buy screen
        saleCell.delegate = self
    
        return saleCell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !self.saleListingList.isEmpty {
            return "ⓘ Tap a photocard to show purchase details. "
        }
        return "No photocards currently on the buy market..."
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if !self.saleListingList.isEmpty {
            return "ⓘ Try filtering and sorting results"
        }
        
        return nil
    }
    
    // MARK: View Controller Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
//        We need to setup the buy market with the appropriate filters whenever this screen appears. Initally, the filters will be maxed out (all market listings displayed) but these filters may be changed later on
        databaseController?.setupBuyMarketListener(priceLo: filterPriceLo, priceHi: filterPriceHi, conditionLo: filterConditionLo, conditionHi: filterConditionHi, dateLo: filterDateLo, dateHi: filterDateHi)
        
        tableView.reloadData()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
   
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHelp" {
            let destination = segue.destination as! HelpTableViewController
            
            destination.info = info
            
//            Whenever we segue to the buy sale listing screen, we need to inform it of the actual sale listing. This is done by getting the sender (which is the table view cell of the sale listing) and getting the sale listing from that, and seting it as a property inside the buy sale listing table view controller
        } else if segue.identifier == "showBuySaleSegue" {
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                let destination = segue.destination as! BuySaleListingTableViewController
                
                let saleListing = self.filteredSaleListingList[indexPath.row]
            
                destination.saleListing = saleListing
            }

//            When we segue to the map screen, we need to inform it of the location to display. Again, this is obtained by the sender of the segue
        } else if segue.identifier == "showMap" {
            if let location = sender as? LocationAnnotation {
                let destination = segue.destination as! MapViewOnlyController
                
                destination.location = location
            }
            
//            All of the sorting of the sale listing will actually be done in the sort view controller. As such, we need to provie the sort screen the entire sale listing list
        } else if segue.identifier == "showSortSegue" {
            let destination = segue.destination as! BuySortTableViewController
            
            destination.saleListingList = self.saleListingList
        
            destination.delegate = self
            
// When we want to go to the filter screen, we need delegation so that it can inform the current view controller of the changed filters
        } else if segue.identifier == "showFilterSegue" {
            let destination = segue.destination as! BuyFilterTableViewController
            
            destination.delegate = self
            
//             We also tell filter screen the current filter settings. This makes it so that it does not reset every time the user selects the filter screen
            destination.priceLower = self.filterPriceLo
            destination.priceUpper = self.filterPriceHi
            destination.conditionLower = self.filterConditionLo
            destination.conditionUpper = self.filterConditionHi
            destination.dateLower = self.filterDateLo
            destination.dateUpper = self.filterDateHi
            
//            Whenever the the user cell is selected, we want it to show the profile of another user. To do this, we inform them of the user of the sale listing, which is obtained from the sender of the segue
            
            
        } else if segue.identifier == "showExternalProfile" {
            if let user = sender as? User {
                let destination = segue.destination as! ExternalProfileTableViewController
                
                destination.user = user
                
//                We then fetch the data for that user from firebase
                databaseController?.setupExternalProfileListener(user.userUID)
                
            }
            
        }
    }
    
//    MARK: Search Controller Methods
    
    
    
    // Called whenever a search has been made, and if so, apply the appropriate filters
        func updateSearchResults(for searchController: UISearchController) {
            
    //        Check there is search text to be accessed
            guard let searchText = searchController.searchBar.text?.lowercased() else {
                return
            }
            
    //        Ensures scope bar only visible once search button is clicked
            searchController.searchBar.showsScopeBar = true
            searchController.searchBar.scopeButtonTitles = ["Idol","Group","Album"]
            
        
            //Check that there is a search term, by checking if string length > 0. If it is, then apply a filter, otherwise, just return the whole list of sale listings
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
            
            
            //        Reload table once new list of albums have been obtained
            tableView.reloadData()
        }
    
    // MARK: Delegation Methods
    
//    When the user cell has been selected, we want to show the profile of that user and send the selected user across
    func userSelected(_ user: User) {
        self.performSegue(withIdentifier: "showExternalProfile", sender: user)
    }
    
//    Called by the filter view controller which tells the current view controller of the new filter settings
    func filterChanged(priceLo: Float, priceHi: Float, conditionLo: Int, conditionHi: Int, dateLo: Date, dateHi: Date) {
        self.filterPriceLo = priceLo
        self.filterPriceHi = priceHi
        self.filterConditionLo = conditionLo
        self.filterConditionHi = conditionHi
        self.filterDateLo = dateLo
        self.filterDateHi = dateHi
    }

//  Called when the location cell of a sale listing has been selected, which will tell the current view controller to segue to the map screen, sending across the location of that sale listing
    func locationSelected(_ location: LocationAnnotation) {
        self.performSegue(withIdentifier: "showMap", sender: location)
    }
    
    // MARK: Used Listeners
    
//    Called whenever there is an update to the sale listings, generally called when we obtain new sale data from firebase
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing]) {

        self.saleListingList = allSaleListings
        self.filteredSaleListingList = allSaleListings
        tableView.reloadData()
  
    }
    
    // MARK: Unused Listeners
    
    func onBiasIdolSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onBiasGroupSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onAlbumChange(change: DatabaseChange, allAlbums: [String]) {}
    
    func onUserPhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?) {}
    
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?) {}
    
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
}
