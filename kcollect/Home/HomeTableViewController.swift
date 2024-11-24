//
//  HomeTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 31/5/2024.
//

import UIKit

// This class is for the home page.
class HomeTableViewController: UITableViewController, DatabaseListener, SaleListingSelectedDelegate {
    
    /*
    Reference: https://www.youtube.com/watch?v=oX7PVj-wiGI&ab_channel=SwiftCourse
    
    To implement the scrolling feature, I followed this tutorial from Youtube. However, I had to make some changes such that it can suit my app, for example, modifying the photocard cell size, having it be on a table view controller rather than a view controller, as well implementing manual scrolling that auto adjusts to the page.
    */
    
    
    let info =   [[
                    "Welcome to K-Collect",
                    """
                    K-Collect is a K-POP photocard management tool, aimed to ease the management of photocards for K-POP lovers like you!
                    
                    For any photocards you collect, this app allows you to store all the photocards that you own in a centralised place so that you will never lose track of the photocards you own. See the 'Portfolio' page.
                    
                    Interested in selling some unwanted photocards, or buying wanted photocards? The market feature of K-Collect makes this a breeze. Simply list your photocard on the market and wait for a prospective buyer. See the 'Sell' and 'Buy' page.
                    
                    Personalise your profile by setting a bias, for both idol and group. Furthermore, display some of your favourite photocards for others to see! See the 'Profile' page.
                    
                    Select the info button located on the top left corner of every main screen to see more detailed information (just like the button you just pressed).
                    """
                ], [
                    "Home Page",
                    """
                    This page displays some featured market listings for both group and idol based on the bias you have selected on your profile. Interested in purchasing the displayed photocards? Simply click on the photocard and you will be redirected to the buy screen!
                    
                    If you have not selected a bias yet, don't worry, we will display some other hot market listings that you may be interested in.
                    
                    If there are no current market listing for the bias group or idol you have set, there will be no market listings displayed.
                    """
                ]]

    var listenerType: ListenerType = .home

    let SECTION_BIAS_IDOL = 0
    let SECTION_BIAS_GROUP = 1
    
    let CELL_BIAS_IDOL = "biasIdolCell"
    let CELL_BIAS_GROUP = "biasGroupCell"
    
    var favIdol: IdolSingleGroup?
    var favGroup: GroupSingle?
    
    var biasIdolSaleListingList = [SaleListing]()
    var biasGroupSaleListingList = [SaleListing]()
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        databaseController?.allBiasIdolSaleListing.removeAll()
        databaseController?.allBiasGroupSaleListing.removeAll()
        
        
        

    }
    
    
    
    // MARK: Table View Controller Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_BIAS_IDOL {
            if let favIdol = self.favIdol {
                return "Featured market listings: \(favIdol.name) (\(favIdol.group))"
            } else {
                return "Featured market listings"
            }
            
        } else if section == SECTION_BIAS_GROUP {
            if let favGroup = self.favGroup {
                return "Featured market listings: \(favGroup.name)"
            } else {
                return "Featured market listings"
            }
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_BIAS_IDOL {
            if let favIdol = self.favIdol {
                if self.biasIdolSaleListingList.isEmpty {
                    return "No listings for your Idol bias"
                } else {
                    return "Interested? Tap to purchase!"
                }
            } else {
                return "Idol bias not selected. Select at profile!"
            }
            
            
        } else if section == SECTION_BIAS_GROUP {
            if let favGroup = self.favGroup {
                if self.biasGroupSaleListingList.isEmpty {
                    return "No listings for your Group bias"
                } else {
                    return "Interested? Tap to purchase!"
                }
            } else {
                return "Group bias not selected. Select at profile!"
            }
            
        }
        
        return nil
    }
    
    // The cells on this table view are scrolling collection view cells that display (only 5) sale listings. The sale listings are of the same bias as set in a user's profile. If they are not set, it is a random selection of sale listings.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // The sale listing data is obtained using the setupHomeBiasListener() method of the database controller, ran before this view controller appears.
        
        // Delegation is needed as we need to know when a specific sale listing is selected on the table view cell, and thus, perform a transition into the buy photocard page
        
        // In the reloadData() method, we basically refresh the collection view with the new sale listing data we just obtained. This is because the setupHomeBiasListener() is asynchronous, and we use listeners whenever updates happen.
        if indexPath.section == SECTION_BIAS_IDOL {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_BIAS_IDOL, for: indexPath) as! ScrollingCollectionViewTableViewCell
            cell.saleListings = self.biasIdolSaleListingList
            cell.pages.numberOfPages = self.biasIdolSaleListingList.count
            
            cell.delegate = self
            cell.reloadData()
            return cell
            
        } else  {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_BIAS_GROUP, for: indexPath) as! ScrollingCollectionViewTableViewCell
            cell.saleListings = self.biasGroupSaleListingList
            cell.pages.numberOfPages = self.biasGroupSaleListingList.count
            
            cell.delegate = self
            cell.reloadData()
            return cell
        }
        
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_BIAS_IDOL {
            return 1
        } else if section == SECTION_BIAS_GROUP {
            return 1
        }
        
        return 0
    }
    
    // MARK: View Controller Methods
    
    // This is where we ask the database controller to fetch the sale listing data from Firebase.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.allBiasIdolSaleListing.removeAll()
        databaseController?.allBiasGroupSaleListing.removeAll()
        tableView.reloadData()
        databaseController?.addListener(listener: self)
        
        databaseController?.setupHomeBiasListener()
        tableView.reloadData()

    }
    
    // The collection view has a timer which is used to rotate through the collection view. Whenever this view controller is closed, we want to make sure we turn off this timer on all relevant cells.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.allBiasIdolSaleListing.removeAll()
        databaseController?.allBiasGroupSaleListing.removeAll()
        tableView.reloadData()
        databaseController?.removeListener(listener: self)
        
        self.invalidateTimersInVisibleCells()
   
    }
    
    // The actual size of the collection view cells depends on the size of the screen. Obviously the only time that the screen changes is when it is changed from verticle to horizontal or vice versa. Once this is detected, we just need to reload the tableview and this will be done automatically (size of cell is defined in the corresponding collection view cell
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Code to be executed during the orientation change
            self.tableView.reloadData()
        }, completion: nil)
    }

    // Segueing to a new page requires some data from this view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHelp" {
            let destination = segue.destination as! HelpTableViewController
            
            destination.info = info
        } else if segue.identifier == "showBuySaleSegue" {
            if let saleListing = sender as? SaleListing {
                let destination = segue.destination as! BuySaleListingTableViewController

                destination.saleListing = saleListing
            
            }
        }
    }
    
    // MARK: Miscellaneous Methods
    
    // Function to invalidate all timers in the scrolling collection view
    func invalidateTimersInVisibleCells() {
        for cell in tableView.visibleCells {
            if let scrollingCell = cell as? ScrollingCollectionViewTableViewCell {
                scrollingCell.invalidateTimer()
            }
        }
    }
    
    // MARK: Delegation Methods
    
    // Whenever a sale listing is selected in the scrolling collection view, we need to call this method by delegation
    func saleListingSelected(_ saleListing: SaleListing) {
        self.performSegue(withIdentifier: "showBuySaleSegue", sender: saleListing)
    }
    
    // MARK: Used Listeners
    
    // During the setup of this view controller, we need to fetch some data from Firebase. Since this is done asynchronously, whenever data is fetched, we need to tell this view controller that data has been fetched and update the data.
    
    // For this view controller, we need to fetch the user's bias (group and idol) as well as sale listings from the market.
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?) {
        self.favGroup = group
        tableView.reloadData()
    }
    
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?) {
        self.favIdol = idol
        tableView.reloadData()
    }

    func onBiasIdolSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {
        self.biasIdolSaleListingList = allSaleListings
        tableView.reloadData()
    }
    
    func onBiasGroupSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {
        self.biasGroupSaleListingList = allSaleListings
        tableView.reloadData()
    }
    
    // MARK: Unused Listeners

    func onUserSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
    func onAlbumChange(change: DatabaseChange, allAlbums: [String]) {}
    
    func onUserPhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
}
