//
//  BuySortTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 22/5/2024.
//

import UIKit
import CoreLocation

// This view controller displays some of the sorting options for the buy market the user can select from
class BuySortTableViewController: UITableViewController, CLLocationManagerDelegate {
    
//    Since the user may want to sort by location, we need a location manager to keep track of the users current location
    var locationManager: CLLocationManager = CLLocationManager()
    
    var currentLocation: CLLocation?
    
    
    let SECTION_PRICE_LOHI = 0
    let SECTION_PRICE_HILO = 1
    let SECTION_CONDITION_LOHI = 2
    let SECTION_CONDITION_HILO = 3
    let SECTION_LOCATION_LOHI = 4
    let SECTION_LOCATION_HILO = 5
    let SECTION_DATE_LOHI = 6
    let SECTION_DATE_HILO = 7
    
    let CELL_PRICE_LOHI = "priceLoHi"
    let CELL_PRICE_HILO = "priceHiLo"
    let CELL_CONDITION_LOHI = "conditionLoHi"
    let CELL_CONDITION_HILO = "conditionHiLo"
    let CELL_LOCATION_LOHI = "locationLoHi"
    let CELL_LOCATION_HILO = "locationHiLo"
    let CELL_DATE_LOHI = "dateLoHi"
    let CELL_DATE_HILO = "dateHiLo"
    
    let PRICE = "Price"
    let CONDITION = "Condition"
    let LOCATION = "Location"
    let DATE = "Date"
    
    weak var databaseController: DatabaseProtocol?
    var saleListingList = [SaleListing]()
    
    weak var delegate: SortOrderSelected?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // The location manager will be used to track the location of the user, if permission has been granted to a specific accuracy

        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        
        // Requests authorisation of location services during startup. Hides the button if this permission is denied.
        let authorisationStatus = locationManager.authorizationStatus
        if authorisationStatus != .authorizedWhenInUse {
            if authorisationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    // MARK: Table View Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 8
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
//    Creates the content for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        Creates the cell to sort by price, low to high
        if indexPath.section == SECTION_PRICE_LOHI {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_PRICE_LOHI, for: indexPath)
            
            cell.textLabel?.text = "Lowest Price First"
            
            return cell
            
            //        Creates the cell to sort by price, high to low
        } else if indexPath.section == SECTION_PRICE_HILO {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_PRICE_HILO, for: indexPath)
            
            cell.textLabel?.text = "Highest Price First"
            
            return cell
            
            //        Creates the cell to sort by condition, low to high
        } else if indexPath.section == SECTION_CONDITION_LOHI {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CONDITION_LOHI, for: indexPath)
            
            cell.textLabel?.text = "Worse Condition First"
            
            return cell
            
            //        Creates the cell to sort by condition, high to low
        } else if indexPath.section == SECTION_CONDITION_HILO {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CONDITION_HILO, for: indexPath)
            
            cell.textLabel?.text = "Better Condition First"
            
            return cell
            
            //        Creates the cell to sort by location, low to high
        } else if indexPath.section == SECTION_LOCATION_LOHI {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION_LOHI, for: indexPath)
            
            cell.textLabel?.text = "Closest Distance Away"
            
            return cell
            
            //        Creates the cell to sort by location, high to low
        } else if indexPath.section == SECTION_LOCATION_HILO {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION_HILO, for: indexPath)
            
            cell.textLabel?.text = "Furthest Distance Away"
            
            return cell
            
            //        Creates the cell to sort by date, low to high
        } else if indexPath.section == SECTION_DATE_LOHI {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_DATE_LOHI, for: indexPath)
            

            cell.textLabel?.text = "Oldest Date"
            
            return cell
            
            //        Creates the cell to sort by date, high to low
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_DATE_HILO, for: indexPath)
            
            cell.textLabel?.text = "Most Recent Date"
            
            return cell
            
        }
    }
    
//    Creates the title for each section
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_PRICE_LOHI {
            return PRICE
        } else if section == SECTION_CONDITION_LOHI {
            return CONDITION
        } else if section == SECTION_LOCATION_LOHI {
            return LOCATION
        } else if section == SECTION_DATE_LOHI {
            return DATE
        }
        
        return nil
    }
    
//    Creates the footer for each section
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_PRICE_HILO {
            return "ⓘ Tap to sort by price"
        } else if section == SECTION_CONDITION_HILO {
            return "ⓘ Tap to sort by condition"
        } else if section == SECTION_LOCATION_HILO {
            return "ⓘ Tap to sort by location"
        } else if section == SECTION_DATE_HILO {
            return "ⓘ Tap to sort by date"
        }
        
        return nil
    }
    
//    For every sort option, define the actual method in order to sort the sale listings. Once the sale listings are sorted, we inform the buy photocard table view controller of the updated and sorted sale listings
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_PRICE_LOHI {
            
            let sortedSaleListing = saleListingList.sorted{$0.price < $1.price}
            
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
            
            navigationController?.popViewController(animated: true)
            
        } else if indexPath.section == SECTION_PRICE_HILO {
            
            let sortedSaleListing = saleListingList.sorted{$0.price > $1.price}
            
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
            
            navigationController?.popViewController(animated: true)
            
        } else if indexPath.section == SECTION_CONDITION_LOHI {
            
            let sortedSaleListing = saleListingList.sorted{$0.condition < $1.condition}
            
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
            
            navigationController?.popViewController(animated: true)
            
        } else if indexPath.section == SECTION_CONDITION_HILO {
            
            let sortedSaleListing = saleListingList.sorted{$0.condition > $1.condition}
            
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
            
            navigationController?.popViewController(animated: true)
            
        } else if indexPath.section == SECTION_LOCATION_LOHI {
            
//            Sorting by location requires the authorisation of location services. If location services are disabled, an error will be displayed
            let authorisationStatus = locationManager.authorizationStatus
            if authorisationStatus != .authorizedWhenInUse {
                self.displayMessage(title: "Error", message: "Location services not enabled. Enable in settings to sort by distance.")
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
    
//            Obtain the current location coordinate
            guard let currentLocationCoordinate = currentLocation?.coordinate else {
                return
            }
            
//            Once the current location of the user has been found, we can finally sort the array by distance, low to high
            let sortedSaleListing = saleListingList.sorted{
                distanceInKilometers(from: currentLocationCoordinate, to: $0.location.coordinate) < distanceInKilometers(from: currentLocationCoordinate, to: $1.location.coordinate)
            }
            
//            Once the sale listing is sorted, as was the other case, update the buy photocard view controller with the sorted sale listings
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
            
            navigationController?.popViewController(animated: true)
            
        } else if indexPath.section == SECTION_LOCATION_HILO {
            
            //            Sorting by location requires the authorisation of location services. If location services are disabled, an error will be displayed
            let authorisationStatus = locationManager.authorizationStatus
            if authorisationStatus != .authorizedWhenInUse {
                self.displayMessage(title: "Error", message: "Location services not enabled. Enable in settings to sort by distance.")
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
            
            //            Obtain the current location coordinate
            guard let currentLocationCoordinate = currentLocation?.coordinate else {
                return
            }
            
            //            Once the current location of the user has been found, we can finally sort the array by distance, high to low
            let sortedSaleListing = saleListingList.sorted{
                distanceInKilometers(from: currentLocationCoordinate, to: $0.location.coordinate) > distanceInKilometers(from: currentLocationCoordinate, to: $1.location.coordinate)
            }
            
            //            Once the sale listing is sorted, as was the other case, update the buy photocard view controller with the sorted sale listings
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
            
            navigationController?.popViewController(animated: true)
            
        } else if indexPath.section == SECTION_DATE_LOHI {
            
            let sortedSaleListing = saleListingList.sorted{$0.date < $1.date}
            
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
        
            navigationController?.popViewController(animated: true)
            
        } else {
            
            let sortedSaleListing = saleListingList.sorted{$0.date > $1.date}
            
            delegate?.onBuyMarketChange(change: .update, allSaleListings: sortedSaleListing)
            
            navigationController?.popViewController(animated: true)
            
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: View Controller Methods
    
    // Whenever the view appears, we need the location manager to start tracking the location of the user, if permission has been granted.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation()
    }
    
    // Whenever the view disappears, we need the location manager to stop tracking the location of the user to not waste batter/ impact performance
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    
//    MARK: Location/Map Related Methods
    
//    This method simply calculates the distance in km between any two coordinates
    func distanceInKilometers(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        
        // Get distance in meters
        let distanceInMeters = location1.distance(from: location2)
        
        // Convert meters to kilometers
        let distanceInKilometers = distanceInMeters / 1000.0
        
        return distanceInKilometers
    }
    
//    Everytime the location is updated, update the current location to be the last location of the locations array (as we only care about the last, most recent user location)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }


}
