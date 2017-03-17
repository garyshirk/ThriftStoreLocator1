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
    
    func getAllStoresOnMainThread() -> [Store] {
        return dataLayer.getAllStoresOnMainThread()
    }
    
    func getLocationInfo(filter: String, locationViewModelUpdater: @escaping ([String:Any]) -> Void) {
        
        networkLayer.getLocationInfo(forSearchStr: filter, modelManagerLocationUpdater: { locationDict in
            
            locationViewModelUpdater(locationDict)
        })
    }
    
    func loadStoresFromServer(storeFilter: String, withDeleteOld: Bool, storesViewModelUpdater: @escaping ([Store]) -> Void) {
        
        networkLayer.loadStoresFromServer(filterString: storeFilter, modelManagerStoreUpdater: {stores in
            
            self.dataLayer.saveInBackground(stores: stores, withDeleteOld: withDeleteOld, saveInBackgroundSuccess: {
            
                let storeEntities = self.getAllStoresOnMainThread()
                storesViewModelUpdater(storeEntities)
            })
        })
    }
}
