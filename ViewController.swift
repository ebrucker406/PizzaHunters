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
    
    var cityList : [String] = []
    
    public let coordinates: [CLLocationCoordinate2D]?
    /// The encoded polyline
    public let encodedPolyline: String
    
    /// The array of levels (nil if cannot be decoded, or is not provided)
    public let levels: [UInt32]?
    /// The encoded levels (nil if cannot be encoded, or is not provided)
    public let encodedLevels: String?
    
    /// The array of location (computed from coordinates)
    public var locations: [CLLocation]? {
        return self.coordinates.map(toLocations)
    }
    
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
                var cities :Int = 0
                
                for var pointCount = 0; pointCount <= route?.polyline.pointCount; ++pointCount{
                    
                    print("Test")
                    self.cityList[cities] = self.searchCity((route?.polyline.coordinate.latitude)!, longitude: (route?.polyline.coordinate.longitude)!)
                    cities++
                    
                }
            })
            
            
//            let mapItems = [destinationMapItem]
//            
//            let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
//            
//            let success = MKMapItem.openMapsWithItems(mapItems, launchOptions: launchOptions)
            
        })
    }
    
    public func decodePolyline(encodedPolyline :String, precision: Double = 1e5)->[CLLocationCoordinate2D]{
        let data = encodedPolyline.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let byteArray = unsafeBitCast(data.bytes, UnsafePointer<Int8>.self)
        let length = Int(data.length)
        var position = Int(0)
        
        var decodedCoordinates = [CLLocationCoordinate2D]()
        
        var lat = 0.0
        var lon = 0.0
        
        while position < length{
            do {
                let resultingLat = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lat += resultingLat
                
                let resultingLon = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lon += resultingLon
            } catch {
                //return nil
                print("Error")
            }
            decodedCoordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return decodedCoordinates
        
    }
    
    public func decodePolyline(encodedPolyline: String, precision: Double = 1e5) -> [CLLocation]? {
        
        return decodePolyline(encodedPolyline, precision: precision).map(toLocations)
    }
    
    private func decodeSingleCoordinate(byteArray byteArray: UnsafePointer<Int8>, length: Int, inout position: Int, precision: Double = 1e5) throws -> Double {
        
        guard position < length else { throw PolylineError.SingleCoordinateDecodingError }
        
        let bitMask = Int8(0x1F)
        
        var coordinate: Int32 = 0
        
        var currentChar: Int8
        var componentCounter: Int32 = 0
        var component: Int32 = 0
        
        repeat {
            currentChar = byteArray[position] - 63
            component = Int32(currentChar & bitMask)
            coordinate |= (component << (5*componentCounter))
            position++
            componentCounter++
        } while ((currentChar & 0x20) == 0x20) && (position < length) && (componentCounter < 6)
        
        if (componentCounter == 6) && ((currentChar & 0x20) == 0x20) {
            throw PolylineError.SingleCoordinateDecodingError
        }
        
        if (coordinate & 0x01) == 0x01 {
            coordinate = ~(coordinate >> 1)
        } else {
            coordinate = coordinate >> 1
        }
        
        return Double(coordinate) / precision
    }
    
    func searchCity(latitude :Double, longitude :Double) -> String{
        var city :String = ""
        
        var localGeoCoder :CLGeocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        localGeoCoder.reverseGeocodeLocation(location){
            (placemarks, error) -> Void in
            let placeArray  = placemarks as [CLPlacemark]!
            
            var placeMark: CLPlacemark!
            placeMark = placeArray?[0]
            
            print(placeMark.addressDictionary)
            let locationName = placeMark.addressDictionary?["Name"] as? String
            print(locationName)
            city = locationName!
            print("testing123")
            print(city)
            
        }
        print(city)
        
        return city
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

enum PolylineError: ErrorType {
    case SingleCoordinateDecodingError
    case ChunkExtractingError
}

private func toCoordinates(locations: [CLLocation]) -> [CLLocationCoordinate2D] {
    return locations.map {location in location.coordinate}
}

private func toLocations(coordinates: [CLLocationCoordinate2D]) -> [CLLocation] {
    return coordinates.map { coordinate in
        CLLocation(latitude:coordinate.latitude, longitude:coordinate.longitude)
    }
}

private func isSeparator(value: Int32) -> Bool {
    return (value - 63) & 0x20 != 0x20
}

private typealias IntegerCoordinates = (latitude: Int, longitude: Int)









