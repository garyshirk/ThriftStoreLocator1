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
    
    func updateFavorite(isFavOn: Bool, forStoreEntity store: Store, saveInBackgroundSuccess: VoidBlock? = nil) {
        
        persistentContainer.performBackgroundTask( {context in
        
            let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "storeId == %@", store.storeId!)
        
            var storeEntity: Store?
            
            do {
                
                let storeEntities = try context.fetch(fetchRequest)
                storeEntity = storeEntities.first
                if isFavOn == true {
                    storeEntity?.isFavorite = 1
                } else {
                    storeEntity?.isFavorite = 0
                }

            } catch _ as NSError {
                // TODO - Error handling
            }
            
            do {
                
                try storeEntity?.managedObjectContext?.save()
                
            } catch _ as NSError {
                // TODO - Error handling
            }
            
            // Update the main thread
            DispatchQueue.main.sync {
                saveInBackgroundSuccess?()
            }
        })
    }
    
    func saveInBackground(stores: [[String:Any]], withDeleteOld deleteOld: Bool, isFavs: Bool, saveInBackgroundSuccess: VoidBlock? = nil) {
        
        // On background thread
        persistentContainer.performBackgroundTask( {context in
            
            let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
            
            var uniqueStores = [[String:Any]]()
            
            if deleteOld {
                
                // Delete all stores currently in core data before loading new stores
                
                uniqueStores = stores
                
                let deleteRequst = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
                
                do {
                    let initialCount = try? context.count(for: fetchRequest)
                    try context.persistentStoreCoordinator?.execute(deleteRequst, with: context)
                    let finalCount = try? context.count(for: fetchRequest)
                    
                    print("Deleting existing Stores: InitialCount: \(initialCount) --- FinalCount: \(finalCount)")
                    
                } catch _ as NSError {
                    // TODO - Error handling
                }
                
            } else {
                
                // Do not delete stores currently in core data, but before saving new ones, eliminate duplicates
                
                if let entityStores = try? context.fetch(fetchRequest) {
                    
                    for storeDict in stores {
                        
                        var duplicate = false
                        
                        for entityStore in entityStores {
                            
                            if ((storeDict["storeId"] as! NSString).integerValue as NSNumber) == entityStore.storeId {
                                
                                duplicate = true
                                
                                break
                            }
                        }
                        
                        if !duplicate {
                            uniqueStores.append(storeDict)
                        }
                    }
                }
            }
            
            // Save stores downloaded from server to Core Data
            do {
                
//                let favEntity = NSEntityDescription.entity(forEntityName: "Favorite", in: context)
//                let favorite = Favorite(entity: favEntity!, insertInto: context)
//                favorite.username = "myuser"
                
            
                for storeDict:[String:Any] in uniqueStores {
                
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
                        
                        if isFavs == true {
                            store.isFavorite = 1
                        } else {
                            store.isFavorite = 0
                        }
                        
                        //favorite.addToStores(store)
                        
                        try store.managedObjectContext?.save()
                    }
                    //try favorite.managedObjectContext?.save()
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
    
    func getAllStoresOnMainThread() -> [Store] {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Store")
        
        // Add Sort descriptor
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // On main thread
        let stores = try! persistentContainer.viewContext.fetch(fetchRequest)
        
        //stores.forEach { print(($0 as AnyObject).name as! String) }
    
        return stores as! [Store]
    }
    
    func getFavoriteStoresOnMainThread() -> [Store] {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Store")
        let predicate = NSPredicate(format: "%K == %@", "isFavorite", NSNumber(value: true))
        fetchRequest.predicate = predicate
        
        // Add Sort descriptor
        //let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        //fetchRequest.sortDescriptors = [sortDescriptor]
        
        // On main thread
        let stores = try! persistentContainer.viewContext.fetch(fetchRequest)
        //stores.forEach { print(($0 as AnyObject).name as! String) }
        
        return stores as! [Store]
    }
}
