//
//  GroupTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import UIKit

// This view controller displays a list of K-POP idols that a user can select
class IdolTableViewController: UITableViewController, UISearchResultsUpdating {
    
    weak var databaseController: DatabaseProtocol?
    
    weak var delegate: IdolChangeDelegate?
    
    let CELL_IDOL = "idolCell"
    
    var idolsList: [Idol] = []
    var filterdIdolsList: [Idol] = []
    
    var selectedGroup: Group?
    
    var showAllIdols: Bool?
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // This view controller will be able to show all idols from the API call, or just idols from a particular group
        if let showAllIdols = showAllIdols, showAllIdols == true {
            if let groups = databaseController?.allGroups.values {
                for group in groups {
                    for idol in group.idols.values {
                        self.idolsList.append(idol)
                    }
                }
            }
        } else {
            guard let selectedGroup else {
                navigationController?.popViewController(animated: true)
                return
            }
            self.idolsList = Array(selectedGroup.idols.values).map { $0 }
        }
        
        // Sort alphabetically
        idolsList.sort{$0.name.lowercased() < $1.name.lowercased()}
        filterdIdolsList = idolsList
        
        // Initialise the search controller and add it to the navigation item
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search KPOP Idol"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: Table View Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filterdIdolsList.count
    }

    // The content of the cells is the idols in our idols list. This idols list is essentially fetched from an API call (after parsing)
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
       
       var content = idolCell.defaultContentConfiguration()
       
       let idol = filterdIdolsList[indexPath.row]
       
       content.text = idol.name
       
       // Since some idols have duplicate names, we need to also display the group if we are to show all idols
       if let _ = showAllIdols, showAllIdols == true {
           content.secondaryText = idol.group.name
       }

       idolCell.contentConfiguration = content
       return idolCell
    }



    //    Whenever an idol is selected, we need to inform the AddPhotocard view controller which idol has been selected using delegation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedIdol = filterdIdolsList[indexPath.row]
        self.delegate?.changedToIdol(selectedIdol)
        navigationController?.popViewController(animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Find your Idol"
        
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {

        return "ⓘ Swipe down to search"
    }
    
    // MARK: Search Controller Methods
    
    // Called whenever a search has been made, and if so, apply the appropriate filters
    func updateSearchResults(for searchController: UISearchController) {
        
//        Check there is search text to be accessed
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
    
        // Check that there is a search term, by checking if string length > 0. If it is, then apply a filter, otherwise, just return the whole list of idols
        if searchText.count > 0 {
            filterdIdolsList = idolsList.filter { (idol: Idol) -> Bool in
                return idol.name.lowercased().contains(searchText)
            }
        } else {
            searchController.searchBar.showsScopeBar = false
            filterdIdolsList = idolsList
        }
        
        
        //        Reload table once new list of idols have been obtained
        tableView.reloadData()
    }
    
    

}
