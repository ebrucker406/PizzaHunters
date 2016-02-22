//
//  PizzaAnnotation.swift
//  PizzaHunters
//
//  Created by Mohammad AZam on 7/15/15.
//  Copyright (c) 2015 Mohammad AZam. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class PizzaAnnotation: NSObject, MKAnnotation {
   
    var coordinate :CLLocationCoordinate2D
    var title :String?
    var subtitle :String?
    
    init(coordinate :CLLocationCoordinate2D, title :String?, subtitle :String?) {
        
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
}
