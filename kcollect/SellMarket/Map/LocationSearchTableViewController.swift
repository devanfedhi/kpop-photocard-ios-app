//
//  LocationsTableViewController.swift
//  LAB07
//
//  Created by Devan Fedhi on 12/5/2024.
//

import UIKit
import MapKit

// This class is a table view controller that lists relevant location depending on the search text
class LocationSearchTableViewController: UITableViewController, UISearchResultsUpdating {
    
    /*
    References:
        - https://www.youtube.com/watch?v=KUiISGHO3sw&ab_channel=ProgrammingWithAPurpose (displaying user location on map)
        - https://www.youtube.com/watch?v=otduXQ5ywjE&t=732s&ab_channel=ProgrammingWithAPurpose (search locations)
        - https://www.youtube.com/watch?v=D6JH54Gppzs&ab_channel=ProgrammingWithAPurpose (adding map pins by long press)
     
    To implement the map view controller & location search controller, I used these tutorials to help implement the map screen as well as some of its functions, as listed above. However I made some changes, such as refactoring how the location name was generated to a more general name, utilising delegation to communicate with the sell photocard screen and overall just allowing it to function with my app.
    */
    
    let CELL_LOCATION = "locationCell"
    var locationList = [MKMapItem]()

    var mapView: MKMapView?
    
    var delegate: LocationChangedDelegate?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(named: "Background")

    }

    // MARK: Table View Methods
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationList.count
    }

    // Creates the cell for each location
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath)
        
        // This involves finding a name for each of the location
        let location = locationList[indexPath.row].placemark
        
        var thoroughfare = ""
        var locality = ""
        var subLocality = ""
        var administrativeArea = ""
        var postalCode = ""
        var country = ""
        
        if let thoroughfareExists = location.thoroughfare {
            thoroughfare += (thoroughfareExists + ", ")
        }
        if let localityfareExists = location.locality {
            locality += (localityfareExists + ", ")
        }
        if let subLocalityExists = location.subLocality {
            subLocality += (subLocalityExists + ", ")
        }
        
        if let administrativeAreaExists = location.administrativeArea {
            administrativeArea += (administrativeAreaExists + ", ")
        }
        if let postalCodeExists = location.postalCode {
            postalCode += (postalCodeExists + ", ")
        }
        if let countryExists = location.country {
            country += countryExists
        }
        
        
        let address = "\(thoroughfare)\(locality)\(subLocality)\(administrativeArea)\(postalCode)\(country)"
        
        cell.textLabel?.text = location.name
        cell.detailTextLabel?.text = address


        return cell
    }
    
    // If a cell is selected, we need to obtain its location and a rough name for that location. Then we need to inform the map view controller of the location that has been selected using delegation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let placemark = self.locationList[indexPath.row].placemark
        
        var locationName = ""
        
        if let localityfareExists = placemark.locality {
            locationName += (localityfareExists + ", ")
        }
        
        if let postalCodeExists = placemark.postalCode {
            locationName += (postalCodeExists + ", ")
        }
        
        if let administrativeAreaExists = placemark.administrativeArea {
            locationName += (administrativeAreaExists + ", ")
        }
        
        if let countryExists = placemark.country {
            locationName += countryExists
        }
        
        if locationName.isEmpty {
            if let ocean = placemark.ocean {
                locationName = ocean
            } else {
                locationName = "Unidentified"
            }
        }
        
        guard let delegate = delegate else {
            return
        }
        
        delegate.locationChanged(self.locationList[indexPath.row].placemark.coordinate, locationName)
        
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Search Controller Methods
    
    // This method is called whenever there is an update to the search text
    func updateSearchResults(for searchController: UISearchController) {
        
//        Check there is search text to be accessed
        guard let mapView = mapView, let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
    
        // We make a request to find locations that are relevant to this search text.
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            
            // Once obtained, we update the location list and reload the table view
            self.locationList = response.mapItems
            self.tableView.reloadData()
        }
    }
    
}
