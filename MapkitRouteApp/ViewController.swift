//
//  ViewController.swift
//  MapkitRouteApp
//
//  Created by Mert Gaygusuz on 21.08.2022.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var lblAdress: UILabel!
    @IBOutlet weak var btnCreateRoute: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let regionSize : Double = 9000
    var previousLocation : CLLocation?
    var routes : [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationServiceControl()
        btnCreateRoute.layer.cornerRadius = 20
    }

    func locationServiceControl() {
        if CLLocationManager.locationServicesEnabled() {
            //location service turned on
            setLocationManager()
            permissionCheck()
        } else {
            
        }
    }
    
    func setLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func permissionCheck() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways :
            //permanent use permit
            break
        case .authorizedWhenInUse :
            //location information only during use
            userTracking()
            break
        case .denied :
            //user denied permission request
            break
        case .notDetermined :
            ////user has not decided yet
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted :
            //application status is restricted
            break
        }
    }
    
    func userTracking() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        focusOnLocation()
        previousLocation = fetchCenterCoordinates(mapView: mapView)
    }
    
    func focusOnLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionSize, longitudinalMeters: regionSize)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func fetchCenterCoordinates(mapView: MKMapView) -> CLLocation {
        let latitute = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitute, longitude: longitude)
    }

    
    @IBAction func btnCreateRouteClicked(_ sender: Any) {
        setARoute()
    }
    
    func setARoute() {
        
        guard let startingCoordinate = locationManager.location?.coordinate  else { return }
        let request = createRequest(startingCoordinate: startingCoordinate)
        let routes = MKDirections(request: request)
        clearRoute(newRoute: routes)
        routes.calculate { (answer, error) in
            guard let answer = answer else { return }
            
            for route in answer.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createRequest(startingCoordinate : CLLocationCoordinate2D) -> MKDirections.Request {
        
        let targetCoordinate = fetchCenterCoordinates(mapView: mapView).coordinate
        let startingMark = MKPlacemark(coordinate: startingCoordinate)
        let targetMark = MKPlacemark(coordinate: targetCoordinate)
        
        let request = MKDirections.Request()
        
        request.source = MKMapItem(placemark: startingMark)
        request.destination = MKMapItem(placemark: targetMark)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        return request
    }
    
    func clearRoute(newRoute: MKDirections) {
        
        mapView.removeOverlays(mapView.overlays)
        routes.append(newRoute)
        
        let _ = routes.map { $0.cancel()}
    }
    
}

extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //it will go here on location change
        guard let location = locations.last else { return }
        let centre = CLLocationCoordinate2D.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: centre, latitudinalMeters: regionSize, longitudinalMeters: regionSize)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //if location permission changes it goes here
        permissionCheck()
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let centre = fetchCenterCoordinates(mapView: mapView)
        
        guard let previousLocation = self.previousLocation else { return }
        if centre.distance(from: previousLocation) < 50 { return }
        self.previousLocation = centre
        
        let geoCoder = CLGeocoder()
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(centre) { (placeMarks, error) in
            if let _ = error {
                print("Hata oluştu")
                return
            }
            guard let mark = placeMarks?.first else { return }
            
            let countryName = mark.country ?? "Yok"
            let cityName = mark.administrativeArea ?? "Yok"
            let districtName = mark.locality ?? "Yok"
            
            DispatchQueue.main.async {
                self.lblAdress.text = "\(districtName),\(cityName),\(countryName)"
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .orange
        renderer.lineWidth = 7
        renderer.lineCap = .square
        return renderer
    }
}
