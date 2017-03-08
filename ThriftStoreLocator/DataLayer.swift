//
//  DataLayer.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import CoreData

typealias VoidBlock = ()->Void

class DataLayer {
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "ThriftStoreLocator")
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
}

extension DataLayer {
    
    // TODO - Is weak self required here?
    func saveInBackground(stores: [[String:AnyObject]], saveInBackgroundSuccess: VoidBlock? = nil) {
        
        // On background thread
        persistentContainer.performBackgroundTask( {context in
            
            // TODO - Should I alway remove current stores in CoreData whenever I go to the server
            let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
            let deleteRequst = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
            
            do {
                let initialCount = try? context.count(for: fetchRequest)
                try context.persistentStoreCoordinator?.execute(deleteRequst, with: context)
                let finalCount = try? context.count(for: fetchRequest)
                
                print("Deleting existing Stores: InitialCount: \(initialCount) --- FinalCount: \(finalCount)")
                
            } catch _ as NSError {
                // TODO - Error handling
            }
            
            // Save stores downloaded from server to Core Data
            do {
            
                for storeDict:[String:AnyObject] in stores {
                
                    let entity = NSEntityDescription.entity(forEntityName: "Store", in: context)
                
                    if let entity = entity {
                        
                        let store = Store(entity: entity, insertInto: context)
                        
                        store.name = storeDict["name"] as? String
                        store.storeId = (storeDict["storeId"] as! NSString).integerValue as NSNumber?
                        store.categoryMain = storeDict["categoryMain"] as? String
                        store.categorySub = storeDict["categorySub"] as? String
                        store.address = storeDict["address"] as? String
                        store.city = storeDict["city"] as? String
                        store.state = storeDict["state"] as? String
                        store.zip = storeDict["zip"] as? String
                        store.phone = storeDict["phone"] as? String
                        store.email = storeDict["email"] as? String
                        store.website = storeDict["website"] as? String
                        store.locLat = (storeDict["locLat"] as? NSString)?.doubleValue as NSNumber?
                        store.locLong = (storeDict["locLong"] as? NSString)?.doubleValue as NSNumber?
                        store.county = storeDict["county"] as? String
                        
                        print(store.description)
                        
                        try store.managedObjectContext?.save()
                    }
                }
            } catch {
                print("Error saving Stores")
            }
            
            // Update the main thread
            DispatchQueue.main.sync {
                saveInBackgroundSuccess?()
            }
        })
    }
    
    func getStoresOnMainThread() -> [Store] {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Store")
        
        // Add Sort descriptor
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // On main thread
        let stores = try! persistentContainer.viewContext.fetch(fetchRequest)
        
        // stores.forEach { print($0.title) }
    
        return stores as! [Store]
    }
}
