//
//  GroupTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import UIKit

// This view controller displays a list of K-POP groups that a user can select
class GroupTableViewController: UITableViewController, UISearchResultsUpdating {
    
    weak var databaseController: DatabaseProtocol?
    weak var delegate: GroupChangeDelegate?
    
    let CELL_GROUP = "groupCell"
    
    var groupsList: [Group] = []
    var filteredGroupsList: [Group] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        

        // This gets all the groups from the API call, and sorts alphabetically.
        groupsList = Array(self.databaseController!.allGroups.values).map { $0 }
        
        groupsList.sort{$0.name.lowercased() < $1.name.lowercased()}
        
        filteredGroupsList = groupsList
        
        // Initialise the search controller and add it to the navigation item
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search KPOP Group"
        navigationItem.searchController = searchController
        definesPresentationContext = true

    }
    
    // MARK: Table View Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredGroupsList.count
    }


    // The content of the cells is the groups in our groups list. This groups list is essentially fetched from an API call (after parsing)
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
       
       var content = groupCell.defaultContentConfiguration()
       
       let group = filteredGroupsList[indexPath.row]
       
       content.text = group.name
       
       groupCell.contentConfiguration = content
       return groupCell
    }
    
    

    //    Whenever a group is selected, we need to inform the AddPhotocard view controller which group has been selected using delegation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedGroup = filteredGroupsList[indexPath.row]
        self.delegate?.changedToGroup(selectedGroup)
        navigationController?.popViewController(animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Find your Group"
        
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "ⓘ Swipe down to search"
    }
    
    // MARK: Search Controller Methods
    
    // Called whenever a search has been made, and if so, apply the appropriate filters
    func updateSearchResults(for searchController: UISearchController) {
        
        //  Check there is search text to be accessed
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
    
        // Check that there is a search term, by checking if string length > 0. If it is, then apply a filter, otherwise, just return the whole list of groups
        if searchText.count > 0 {
            filteredGroupsList = groupsList.filter { (group: Group) -> Bool in
                return group.name.lowercased().contains(searchText) ?? false
            }
        } else {
            searchController.searchBar.showsScopeBar = false
            filteredGroupsList = groupsList
        }
        
//        Reload table once new list of groups have been obtained
        tableView.reloadData()
    }

}
