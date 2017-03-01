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
        
        let container = NSPersistentContainer(name: "SystemOfRecord")
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
    
    func saveInBackground(saveInBackgroundSuccess: VoidBlock? = nil) {
        
        // In background thread
        persistentContainer.performBackgroundTask( {context in
            
            // TODO - Should I alway remove current stores in CoreData whenever I go to the server
            let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
            let deleteRequst = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
            
            do {
                let initialCount = try? context.count(for: fetchRequest)
                try context.persistentStoreCoordinator?.execute(deleteRequst, with: context)
                let finalCount = try? context.count(for: fetchRequest)
                
                print("initialCount: \(initialCount) --- finalCount: \(finalCount)")
                
            } catch _ as NSError {
                // TODO - Error handling
            }
            
            // Save stores downloaded from server
            
            
            
            // Update the main thread
            DispatchQueue.main.sync {
                saveInBackgroundSuccess?()
            }
        })
    }
    
//    func getMessagesOnMainThread() -> [Store] {
//        
//        
//        
//        return stores
//    }
    
    
    
    
    
    
    
    
//    func saveInBackground(daos: [MessageDAO], saveInBackgroundSuccess: VoidBlock? = nil) {
//        //In background thread
//        persistentContainer.performBackgroundTask( { context in
//            
//            //Remove Previous Messages
//            let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
//            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
//            
//            do {
//                let initialCount = try? context.count(for: fetchRequest)
//                try context.persistentStoreCoordinator?.execute(deleteRequest, with: context)
//                let finalCount = try? context.count(for: fetchRequest)
//                
//                print("initialCount: \(initialCount) ::: finalCount: \(finalCount)")
//            } catch _ as NSError {
//                // TODO: handle the error
//            }
//            
//            
//            //Save Message Daos
//            do {
//                for dao in daos {
//                    let message = Message(context: context)
//                    message.id     = Int64(dao.id)
//                    message.body   = dao.body
//                    message.title  = dao.title
//                    message.userId = Int64(dao.userId)
//                    
//                    try context.save()
//                }
//            } catch {
//                print("Error importing messages: \(error.localizedDescription)")
//            }
//            
//            //Update main thread
//            DispatchQueue.main.async {
//                saveInBackgroundSuccess?()
//            }
//        })
//    }
}
