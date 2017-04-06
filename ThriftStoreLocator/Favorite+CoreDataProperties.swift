//
//  Favorite+CoreDataProperties.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 4/5/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import CoreData


extension Favorite {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Favorite> {
        return NSFetchRequest<Favorite>(entityName: "Favorite");
    }
    
    @NSManaged public var username: String?
    @NSManaged public var stores: NSSet?
    
}

extension Favorite {
    
    @objc(addStoresObject:)
    @NSManaged public func addToStores(_ value: Store)
    
    @objc(removeStoresObject:)
    @NSManaged public func removeFromStores(_ value: Store)
    
    @objc(addStores:)
    @NSManaged public func addToStores(_ values: NSSet)
    
    @objc(removeStores:)
    @NSManaged public func removeFromStores(_ values: NSSet)
    
}
