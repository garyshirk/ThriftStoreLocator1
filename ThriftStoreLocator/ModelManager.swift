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
    
    
    // TODO - add weak self to below closures
    
    
    func postFavoriteToServer(store: Store, forUser user: String, modelManagerPostFavUpdater: @escaping () -> Void) {
        
        self.networkLayer.postFavorite(store: store, forUser: user, networkLayerPostFavUpdater: {
        
            self.dataLayer.setAsFavorite(toStoreEntity: store, saveInBackgroundSuccess: {
            
                modelManagerPostFavUpdater()
            })
        })
    }
    
    func loadFavoritesFromServer(forUser user: String, modelManagerLoadFavoritesUpdater: @escaping([Store]) -> Void) {
        
        self.networkLayer.loadFavoritesFromServer(forUser: user, networkLayerLoadFavoritesUpdater: { [weak self] stores in
            
            guard let strongSelf = self else { return }
        
            strongSelf.dataLayer.saveInBackground(stores: stores, withDeleteOld: true, isFavs: true, saveInBackgroundSuccess: {
            
                let storeEntities = strongSelf.getAllStoresOnMainThread()
                modelManagerLoadFavoritesUpdater(storeEntities)
            })
        })
    }
    
    func loadStoresFromServer(forQuery query: String, withDeleteOld deleteOld: Bool, modelManagerStoresUpdater: @escaping ([Store]) -> Void) {
        
        self.networkLayer.loadStoresFromServer(forQuery: query, networkLayerStoreUpdater: { [weak self] stores in
            
            guard let strongSelf = self else { return }
            
            strongSelf.dataLayer.saveInBackground(stores: stores, withDeleteOld: deleteOld, isFavs: false, saveInBackgroundSuccess: {
            
                let storeEntities = strongSelf.getAllStoresOnMainThread()
                modelManagerStoresUpdater(storeEntities)
            })
        })
    }
}
