//
//  ModelManager.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import CoreData

class ModelManager {
    
    
    // TODO - Improve singleton implementation
    static var sharedInstance = ModelManager()
    
    var networkLayer = NetworkLayer()
    var dataLayer = DataLayer()
    
    func getStoresOnMainThread() -> [Store] {
        return dataLayer.getStoresOnMainThread()
    }
    
    func loadStores(viewModelUpdater: @escaping ([Store]) -> Void) { //([Store]) -> Void) {
        
        networkLayer.loadStoresFromServer(modelManagerUpdater: {stores in
            
            self.dataLayer.saveInBackground(storeStrArray: stores, saveInBackgroundSuccess: {
            
                let coreDataStores = self.getStoresOnMainThread()
                viewModelUpdater(coreDataStores)
                
            
            })
            
//            print("Test Stores received in ModelManager")
//            viewModelUpdater(stores)
        })
    }
    
    
    
//    modelManager.loadMessages(serverLoadSuccess: { [weak self] stores -> Void in
//    
//    guard let strongSelf = self else {
//    return
//    }
//    
//    strongSelf.stores = stores
//    strongSelf.stores.forEach {print("Store Name: \($0.name)")}
//    strongSelf.delegate?.handleStoresUpdated(stores: stores)
//    
//    
//    })
}
