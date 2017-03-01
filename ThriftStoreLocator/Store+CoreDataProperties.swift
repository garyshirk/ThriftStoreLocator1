//
//  Store+CoreDataProperties.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Store {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Store> {
        return NSFetchRequest<Store>(entityName: "Store");
    }

    @NSManaged public var locLong: String?
    @NSManaged public var locLat: String?
    @NSManaged public var county: String?
    @NSManaged public var website: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var zip: String?
    @NSManaged public var state: String?
    @NSManaged public var city: String?
    @NSManaged public var address: String?
    @NSManaged public var name: String?
    @NSManaged public var categoryMain: String?
    @NSManaged public var categorySub: String?
    @NSManaged public var storeId: String?

}
