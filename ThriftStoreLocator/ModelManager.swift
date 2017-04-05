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
    
    func loadFavoritesFromServer(forUser user: String, favoritesViewModelUpdater: @escaping([Store]) -> Void) {
        
        networkLayer.loadFavoritesFromServer(forUser: user, modelManagerFavoriteUpdater: {stores in
        
            self.dataLayer.saveInBackground(stores: stores, withDeleteOld: false, saveInBackgroundSuccess: {
            
                
            })
        })
    }
    
    func loadStoresFromServer(forQuery query: String, withDeleteOld: Bool, storesViewModelUpdater: @escaping ([Store]) -> Void) {
        
        networkLayer.loadStoresFromServer(forQuery: query, modelManagerStoreUpdater: {stores in
            
            self.dataLayer.saveInBackground(stores: stores, withDeleteOld: withDeleteOld, saveInBackgroundSuccess: {
            
                let storeEntities = self.getAllStoresOnMainThread()
                storesViewModelUpdater(storeEntities)
            })
        })
    }
}
