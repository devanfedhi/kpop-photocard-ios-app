//
//  MapViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 13/5/2024.
//

import UIKit
import MapKit
import CoreLocation

// This view controller displays map. Users can select a location on the map to be used as the location for the sale listing
class MapViewController: UIViewController, CLLocationManagerDelegate, LocationChangedDelegate, MKMapViewDelegate {
    
    /*
    References:
        - https://www.youtube.com/watch?v=KUiISGHO3sw&ab_channel=ProgrammingWithAPurpose (displaying user location on map)
        - https://www.youtube.com/watch?v=otduXQ5ywjE&t=732s&ab_channel=ProgrammingWithAPurpose (search locations)
        - https://www.youtube.com/watch?v=D6JH54Gppzs&ab_channel=ProgrammingWithAPurpose (adding map pins by long press)
     
    To implement the map view controller & location search controller, I used these tutorials to help implement the map screen as well as some of its functions, as listed above. However I made some changes, such as refactoring how the location name was generated to a more general name, utilising delegation to communicate with the sell photocard screen and overall just allowing it to function with my app.
    */
    
    let info =   [[
                    "Map Selection",
                    """
                    In order to select a location on the map, you have 3 options.
                    """
                ],[
                    "1. Choosing any location on the map",
                    """
                    Navigate to any location on the map. Press and hold on the screen to mark that location on the map used for your sale listing. This will also try to find an approximate name for the location on the map that will be displayed on the sale listing.
                    """
                ],[
                    "2. Searching for a location",
                    """
                    Swipe down to search for any location on the map.
                    """
                ],[
                    "3. Choosing your current location",
                    """
                    Optionally, enable location services (as instructed when the screen loads) or in your devies settings. Once this has been enabled, a button will appear on the top right of the map which you can use to automatically navigate to your current, approximate location.
                    """
                ]]
    
    // When this button is selected, the location chosen (the location marked on the map) will be sent to the sell photocard view controller. If a location has not yet been selected, display an error message
    @IBAction func useChosenLocation(_ sender: Any) {
        guard let delegate = delegate, let chosenLocation = chosenLocation, let chosenLocationName = chosenLocationName else {
            displayMessage(title: "Error", message: "Please select a location on the map using one of the three ways mentioned on the info page. To view the info page, select the info button on the top left of the screen")
            return
        }
        delegate.locationChanged(chosenLocation, chosenLocationName)
        navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    // This button will be used to set the chosen location as the current location of the user, if they have given sufficient permission to the app. This button will be hidden if no permissions are granted.
    @IBOutlet weak var useCurrentLocationButton: UIButton!
    @IBAction func useCurrentLocationButton(_ sender: Any) {
        if let currentLocation = currentLocation {
            updateMapAndObtainLocationName(currentLocation)
        }
        
    }
    var locationManager: CLLocationManager = CLLocationManager()
    
    var currentLocation: CLLocation?
    
    var chosenLocation: CLLocationCoordinate2D?
    var chosenLocationName: String?
    
    var searchController: UISearchController?
    
    var delegate: LocationChangedDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        // The location manager will be used to track the location of the user, if permission has been granted to a specific accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        
        
        
        // Requests authorisation of location services during startup. Hides the button if this permission is denied.
        let authorisationStatus = locationManager.authorizationStatus
        
        
        print(authorisationStatus.rawValue)
        print(authorisationStatus.hashValue)
        if authorisationStatus != .authorizedWhenInUse {
            useCurrentLocationButton.isHidden = true
            if authorisationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            
            
        }
        
        // This search controller will be used to search thorugh locations in the world
        let locationSearchController = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTableViewController") as! LocationSearchTableViewController
        locationSearchController.delegate = self
        searchController = UISearchController(searchResultsController: locationSearchController)
        searchController?.searchResultsUpdater = locationSearchController as! any UISearchResultsUpdating
        
        let searchBar = searchController?.searchBar
        searchBar?.sizeToFit()
        searchBar?.placeholder = "Enter a location"
        navigationItem.searchController = searchController
        
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchController.mapView = mapView
        
        // Whenever a user long presses on the map, it will call the addAnotation method
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(_:)))
        mapView.addGestureRecognizer(longPressRecogniser)
        
    }
    
    // MARK: View Controller Methods

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHelp" {
            let destination = segue.destination as! HelpTableViewController
            
            destination.info = info
        }
    }
    
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
    
    // MARK: Location/Map Related Methods
    
    // This method will be called whenever location services has been enabled, which will unhide the current location button on the top right of the map
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            useCurrentLocationButton.isHidden = false
        }
    }
    
    // Locations are update in an array. We only care about the last location since we only want a singular location, the most recent one
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    // Given a coordinate and a title, set an annotation on the map at those coordinates with that title, removing any past annotations
    
    func updateMap(location: CLLocationCoordinate2D, title: String?) {
        
        // Make the annotation on the map
        let point = MKPointAnnotation()
        point.title = title
        point.coordinate = location
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        self.mapView.addAnnotation(point)
        
        // Zoom in on the annotation
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 200, longitudinalMeters: 200)
        
        self.mapView.setRegion(region, animated: true)
        
        // Update the chosne location and its name
        chosenLocation = location
        chosenLocationName = title
    }
    
    // This is the renderer for the pin
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") {
            return annotationView
        } else {
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            annotationView.canShowCallout = true
            return annotationView
        }
    }
    
    // This method is called whenever the user long presses on the map. The location of the press will be obtained as well as its name.
    @objc func addAnnotation(_ recogniser: UILongPressGestureRecognizer) {
        if recogniser.state == .began {
            let point = recogniser.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            var location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            updateMapAndObtainLocationName(location)
  
        }
    }
    
    // For a specific location on the map, this method will attempt to find a rough title for this location.
    func updateMapAndObtainLocationName(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [self] (placemarks, error) in
            if let error = error {
                print("reverse code location failed")
            } else {
                if let placemarks = placemarks, let placemark = placemarks.first {
                    
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

                    // Once the location name has been identified, update the map with the locations coordinate and name
                    updateMap(location: location.coordinate, title: locationName)
                } else {
                    updateMap(location: location.coordinate, title: "(\(location.coordinate.latitude),\(location.coordinate.longitude))")
                }
            }
        }

    }
    
    // MARK: Delegation Methods
    
    // Whenever a location is selected on the location search table view controller, we need to inform the map of the chosen location and its name
    func locationChanged(_ location: CLLocationCoordinate2D, _ title: String) {
        self.updateMap(location: location, title: title)
    }
    
}


