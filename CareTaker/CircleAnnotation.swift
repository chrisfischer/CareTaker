//
//  CircleAnnotation.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/26/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import MapKit

class CircleAnnotation: NSObject, MKAnnotation {

    dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    
    
    init(coordinate: CLLocationCoordinate2D) {
        self.title = nil
        self.coordinate = coordinate
    }
}

 extension MKAnnotationView {
    override open var center: CGPoint {
        didSet {
            let dict = ["coord": center]
            NotificationCenter.default.post(name: Notification.Name(rawValue: annotationDraggedKey), object: nil, userInfo: dict)
        }
    }
    
}
