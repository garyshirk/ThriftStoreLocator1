//
//  StoreAnnotation.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 4/22/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import MapKit
import Contacts

class StoreAnnotation: NSObject, MKAnnotation {
    
    let tag: Int
    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(tag: Int, title: String, coordinate: CLLocationCoordinate2D) {
        self.tag = tag
        self.title = title
        self.coordinate = coordinate
        
        super.init()
    }
}
