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
    
    func loadStores(viewModelUpdater: @escaping ([Store]) -> Void) {
        
        networkLayer.loadStoresFromServer(modelManagerUpdater: {stores in
            
            self.dataLayer.saveInBackground(stores: stores, saveInBackgroundSuccess: {
            
                let storeEntities = self.getStoresOnMainThread()
                viewModelUpdater(storeEntities)
            })
        })
    }
}
