//
//  MapViewOnlyController.swift
//  kcollect
//
//  Created by Devan Fedhi on 13/5/2024.
//

import UIKit
import MapKit
import CoreLocation

// This class displays on the map the location of a sale listing. If location services are enabled, it can also allow the user to visualise their current location on the map as well (including the distance between these two points)
class MapViewOnlyController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    /*
    References:
        - https://www.youtube.com/watch?v=KUiISGHO3sw&ab_channel=ProgrammingWithAPurpose (displaying user location on map)
     
    To implement the map view controller & location search controller, I used these tutorials to help implement the map screen as well as some of its functions, as listed above. However I made some changes, such as creating a polyline between the user's location and the listing's location, calculating distance between the two, parsing the formate into a more appropriate format for the app, and overall a lot of changes to ensure it fits with the app.
    */
    
//    The location manager is needed to track the location of the user, if sufficient permission has been given
    var locationManager: CLLocationManager = CLLocationManager()
    
    var currentLocation: CLLocation?

    @IBOutlet weak var distanceLabel: UILabel!
    
    // This button will be used to set the chosen location as the current location of the user, if they have given sufficient permission to the app. This button will be hidden if no permissions are granted.
    @IBOutlet weak var useCurrentLocationButton: UIButton!
    @IBAction func useCurrentLocationButton(_ sender: Any) {
        if let currentLocation = currentLocation {
            updateMapAndObtainLocationName(currentLocation)
        }
        

    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    var delegate: LocationChangedDelegate?

    var homeLocation: LocationAnnotation?
    
    var location: LocationAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        distanceLabel.text = ""
        
        mapView.delegate = self
        
        guard let location = location else {
            return
        }
        
//        Whenever this screen is loaded, it is provided the location of a sale listing, so we need to update the map to show this location
        self.updateMap(location: location)
        
        // The location manager will be used to track the location of the user, if permission has been granted to a specific accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        
        // Requests authorisation of location services during startup. Hides the button if this permission is denied.
        let authorisationStatus = locationManager.authorizationStatus
        if authorisationStatus != .authorizedWhenInUse {
            useCurrentLocationButton.isHidden = true
            if authorisationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
//    MARK: View Controller Methods
    
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
    
//    MARK: Map/Location Related Methods
    
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
    
//    Calculates the distance in km between any two pairs of coordinates
    func distanceInKilometers(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        
        // Get distance in m
        let distanceInMeters = location1.distance(from: location2)
        
        // Convert metres to km
        let distanceInKilometers = distanceInMeters / 1000.0
        
        return distanceInKilometers
    }
    
//    Update the map with the location of the sale listing, and if there is a home location (location of the user), update that too. This involves adding an annotation mark on the location of the sale listing and the location of the user.
    func updateMap(location: LocationAnnotation) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        let point = MKPointAnnotation()
        point.title = location.title
        point.coordinate = location.coordinate
        self.mapView.addAnnotation(point)
        
        if let homeLocation = self.homeLocation{
            let homePoint = MKPointAnnotation()
            homePoint.title = homeLocation.title
            homePoint.coordinate = homeLocation.coordinate
            self.mapView.addAnnotation(homePoint)
            
//            Also display the distance between the location of the user and the location of the sale listing
            distanceLabel.text = "\(distanceInKilometers(from: homePoint.coordinate, to: point.coordinate).rounded()) km"

//            Create a line between these two locations
            let coordinates = [point.coordinate, homePoint.coordinate]
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            
            // Add the polyline to the map
            mapView.addOverlay(polyline)
            
//            Zoom in/out on the map such that both of these pairs of coordinates can be seen on the map
            mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)

        } else {
//            If there is no current user location, just zoom in on the location of the sale listing
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
            
            self.mapView.setRegion(region, animated: true)
        }
    
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
    
    // This is the renderer for the polyline
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(named: "ThemeColour")
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer()
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
//                    Once the location name has been obtained for the current user location, set it as a property in the class so that we can access it
                    homeLocation = LocationAnnotation(title: locationName, coordinate: location.coordinate)
                    
                    guard let saleLocation = self.location else {
                        return
                    }

//                    Then update the map so that both the sale location and the current user location are displayed
                    updateMap(location: saleLocation)
                }
            }
        }

    }
}


