//
//  ViewController.swift
//  PizzaHunters
//
//  Created by Mohammad AZam on 7/14/15.
//  Copyright (c) 2015 Mohammad AZam. All rights reserved.
//

import UIKit
import MapKit

import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var mapView :MKMapView?
    @IBOutlet weak var addressTextField :UITextField?
    
    var locationManager :CLLocationManager = CLLocationManager()
    var currentLocation :CLLocation?
    var geocoder :CLGeocoder = CLGeocoder()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setup()
    }
    
    func setup() {
        
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = kCLHeadingFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView!.showsUserLocation = true
        
       // dropFavoriteAnnotation()
       
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        let address = self.addressTextField?.text
        
        openDirections(address)
        
        return textField.resignFirstResponder()
        
    }
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer! {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blueColor()
        renderer.lineWidth = 5.0
        return renderer
        
    }
    
    
    func openDirections(address :String?) {
    
        self.geocoder.geocodeAddressString(address!, completionHandler: { (placemarks :[CLPlacemark]?, error :NSError?) -> Void in
            
            let placemark = placemarks![0] as? CLPlacemark
            
            let destinationPlacemark = MKPlacemark(coordinate: placemark!.location!.coordinate, addressDictionary: placemark?.addressDictionary as? [String:NSObject])
            
            let startingMapItem = MKMapItem.mapItemForCurrentLocation()
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
            
            let directionsRequest = MKDirectionsRequest()
            directionsRequest.transportType = .Automobile
            directionsRequest.source = startingMapItem
            directionsRequest.destination = destinationMapItem
            
            let directions = MKDirections(request: directionsRequest)
            
            directions.calculateDirectionsWithCompletionHandler({ (response :MKDirectionsResponse?, error :NSError?) -> Void in

                let route = response!.routes[0] as? MKRoute
                
                if route!.steps.count > 0 {
                    
                    for step in route!.steps {
                        
                        print(step.instructions)
                        
                    }
                }
                
                self.mapView!.addOverlay((route?.polyline)!, level: MKOverlayLevel.AboveRoads)
            })
            
            
//            let mapItems = [destinationMapItem]
//            
//            let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
//            
//            let success = MKMapItem.openMapsWithItems(mapItems, launchOptions: launchOptions)
            
        })
        
    
    
    }
    
    func dropFavoriteAnnotation() {
        
        let googleCoordinate = CLLocationCoordinate2D(latitude: 37.422, longitude: -122.084058)
        
        let favAnnotation = PizzaAnnotation(coordinate: googleCoordinate, title: "Favorite Pizza", subtitle: nil)
        
        self.mapView?.addAnnotation(favAnnotation)
        
        // register to monitor region
        let region = CLCircularRegion(center: googleCoordinate, radius: 1000, identifier: "FavoritePizzaRegion")
        
        self.mapView?.addOverlay(MKCircle(centerCoordinate: googleCoordinate, radius: 1000))
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        self.locationManager.startMonitoringForRegion(region)
        
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Region Entered")
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Region Exited")
    }
    
    
//    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
//        if overlay is MKCircle {
//            var circleRenderer = MKCircleRenderer(overlay: overlay)
//            circleRenderer.lineWidth = 1.0
//            circleRenderer.strokeColor = UIColor.purpleColor()
//            circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
//            return circleRenderer
//        }
//        return nil
//    }
    
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        print("didStartMonitoringForRegion")
    }
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
        self.currentLocation = userLocation.location
        
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 250, 250)
        self.mapView!.setRegion(region, animated: true)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
        
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        
        var annotationView = self.mapView?.dequeueReusableAnnotationViewWithIdentifier("PizzaAnnotationView")
        
        if(annotationView == nil) {
            
            annotationView = PizzaAnnotationView(annotation: annotation, reuseIdentifier: "PizzaAnnotationView")
            annotationView?.canShowCallout = true
        }
        else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
        
    }
    
    func addAnnotationToMap() {
        
        self.geocoder.reverseGeocodeLocation(self.currentLocation!) { (placemarks :[CLPlacemark]?, error :NSError?) -> Void in
            
            if error != nil { return }
            
                        let placemark = placemarks![0] as? CLPlacemark
            
                        if let streetName = placemark!.addressDictionary!["Street"] as? String {
            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
                                let pizzaAnnotation = PizzaAnnotation(coordinate: self.currentLocation!.coordinate, title: "Pizza Hunters", subtitle: streetName)
            
                                self.mapView!.addAnnotation(pizzaAnnotation)
                                
                            })
                            
                        }
            
        }
        
        
//        self.geocoder.reverseGeocodeLocation(self.currentLocation!, completionHandler: { (placemarks :[AnyObject]!, error :NSError!) -> Void in
//            
//            if error != nil { return }
//            
//            let placemark = placemarks[0] as! CLPlacemark
//            
//            if let streetName = placemark.addressDictionary!["Street"] as? String {
//                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//
//                    let pizzaAnnotation = PizzaAnnotation(coordinate: self.currentLocation!.coordinate, title: "Pizza Hunters", subtitle: streetName)
//                    
//                    self.mapView!.addAnnotation(pizzaAnnotation)
//                    
//                })
//                
//            }
//            
//        })
        
        
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        
        if(motion == .MotionShake) {
            
            addAnnotationToMap()
            
        }
        
    }

}









