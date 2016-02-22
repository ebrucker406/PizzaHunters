//
//  PizzaAnnotationView.swift
//  PizzaHunters
//
//  Created by Mohammad AZam on 7/18/15.
//  Copyright (c) 2015 Mohammad AZam. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class PizzaAnnotationView: MKAnnotationView {

    override init(frame :CGRect) {
        super.init(frame: frame)
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        var frame = self.frame
        frame.size = CGSizeMake(80, 80)
        self.frame = frame
        self.backgroundColor = UIColor.clearColor()
        self.centerOffset = CGPointMake(-5, -5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        
          UIImage(named: "Pizza.png")?.drawInRect(CGRectMake(30, 30, 30, 30))
        
    }
    

}
