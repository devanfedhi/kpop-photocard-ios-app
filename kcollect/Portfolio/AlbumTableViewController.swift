//
//  AlbumTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 21/4/2024.
//

import UIKit

// This view controller displays a list of K-POP albums that a user can select
class AlbumTableViewController: UITableViewController, DatabaseListener, SearchAlbumTableViewCellDelegate, UISearchResultsUpdating {

    var listenerType: ListenerType = .album
    
    weak var databaseController: DatabaseProtocol?
    
    weak var delegate: AlbumChangeDelegate?
    
    let SECTION_SEARCH = 0
    let SECTION_ALBUM = 1
    
    let CELL_SEARCH = "searchCell"
    let CELL_ALBUM = "albumCell"
    
    
    var selectedIdol: Idol?
    var selectedGroup: Group?
    
    var allAlbums: [String] = []
    var allFilteredAlbums: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        guard let group = selectedGroup, let idol = selectedIdol else {
            return
        }
        
        allFilteredAlbums = allAlbums
        
        // Initialise the search controller and add it to the navigation item
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search KPOP Album"
        navigationItem.searchController = searchController
        definesPresentationContext = true

    }
    
    // MARK: Table View Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_SEARCH:
            return 1
        case SECTION_ALBUM:
            return allFilteredAlbums.count
        default:
            return 0
        }

    }

    // The content of the cells is the albums in our albums list. This idols list is essentially fetched from an API call (after parsing)
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // This specific section is for all the albums stored in Firebase
        if indexPath.section == SECTION_ALBUM {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
            
            var content = albumCell.defaultContentConfiguration()
            
            let album = allFilteredAlbums[indexPath.row]
            
            content.text = album
            
            albumCell.contentConfiguration = content
            return albumCell
            
            // This section is for a search cell (a cell to create a new album)
        } else {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_SEARCH, for: indexPath) as! AlbumSearchTableViewCell
            
            infoCell.delegate = self
        
            return infoCell
        }
    }
    
//    Only the album section (not search section) will have select functionality. Once an album is selected, we need to tell the add photocard screen which album it is
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == SECTION_ALBUM) {
            let selectedRow = allFilteredAlbums[indexPath.row]
            self.delegate?.changedToAlbum(selectedRow)
            navigationController?.popViewController(animated: true)
        }
        
        
    }
    
//    Search section should not even be selectable
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath.section == SECTION_SEARCH) {
            return nil
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case SECTION_SEARCH:
            return "Add a new album"
        case SECTION_ALBUM:
            if allFilteredAlbums.count == 0 {
                return nil
            }
            return "Find an existing album"
        default:
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case SECTION_SEARCH:
            return "ⓘ Tap 'Add' to add the new album"
        case SECTION_ALBUM:
            if allFilteredAlbums.count == 0 {
                return nil
            }
            return "ⓘ Swipe down to search"
        default:
            return nil
        }
    }
    
//    Search section needs to be a slightly larger height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Check the index path and return different heights for different cells
        if indexPath.section == 0 {
            return 80
        } else {
            // Return the default height for other cells
            return UITableView.automaticDimension
        }
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
    
    // MARK: Delegation Methods
    
    //    This function will be called from the search ablum table view cell when we create/search for a new album. This will then tell the addphotocard view controller the selected album
        func addAlbumButtonClicked(_ album: String) {
            self.delegate?.changedToAlbum(album)
            navigationController?.popViewController(animated: true)
        }
    
    // MARK: Search Controller Methods
    
    // Called whenever a search has been made, and if so, apply the appropriate filters
    func updateSearchResults(for searchController: UISearchController) {
        
//        Check there is search text to be accessed
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
    
        // Check that there is a search term, by checking if string length > 0. If it is, then apply a filter, otherwise, just return the whole list of albums
        if searchText.count > 0 {
            allFilteredAlbums = allAlbums.filter { (album: String) -> Bool in
                return album.lowercased().contains(searchText)
            }
        } else {
            searchController.searchBar.showsScopeBar = false
            allFilteredAlbums = allAlbums
        }
        
        
        //        Reload table once new list of idols have been obtained
        tableView.reloadData()
    }
    
    // MARK: Used Listeners
    
    func onAlbumChange(change: DatabaseChange, allAlbums: [String]) {
        self.allAlbums = allAlbums
        self.allFilteredAlbums = allAlbums

        tableView.reloadData()
    }
    
    // MARK: Unused Listeners
    
    func onBiasIdolSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onBiasGroupSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}
    
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onUserSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing]) {}
    
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?) {}
    
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?) {}
    
    func onUserPhotocardChange(change: DatabaseChange, allPhotocards: [Photocard]) {}

}


