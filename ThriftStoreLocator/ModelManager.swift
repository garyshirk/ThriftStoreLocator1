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
    
    func getLocationFilteredStores(forPredicate predicate: NSPredicate) -> [Store] {
        return dataLayer.getLocationFilteredStoresOnMainThread(forPredicate: predicate)
    }
    
    func deleteAllStoresFromCoreDataExceptFavs(modelManagerDeleteAllCoreDataExceptFavsUpdater: @escaping () -> Void) {
        
        self.dataLayer.deleteCoreDataObjectsExceptFavorites(deleteAllStoresExceptFavsUpdater: {
            
            modelManagerDeleteAllCoreDataExceptFavsUpdater()
        })
    }
    
    func postFavoriteToServer(store: Store, forUser user: String, modelManagerPostFavUpdater: @escaping () -> Void) {
        
        self.networkLayer.postFavorite(store: store, forUser: user, networkLayerPostFavUpdater: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
        
            strongSelf.dataLayer.updateFavorite(isFavOn: true, forStoreEntity: store, saveInBackgroundSuccess: {
            
                modelManagerPostFavUpdater()
            })
        })
    }
    
    func removeFavoriteFromServer(store: Store, forUser user: String, modelManagerPostFavUpdater: @escaping () -> Void) {
        
        self.networkLayer.removeFavorite(store: store, forUser: user, networkLayerRemoveFavUpdater: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
        
            strongSelf.dataLayer.updateFavorite(isFavOn: false, forStoreEntity: store, saveInBackgroundSuccess: {
                
                modelManagerPostFavUpdater()
            })
        })
    }
    
    func listFavorites(modelManagerListFavoritesUpdater: ([Store]) -> Void) {
        
        let stores = self.dataLayer.getFavoriteStoresOnMainThread()
        modelManagerListFavoritesUpdater(stores)
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
    
    // Use for loading stores by county
    func loadStoresFromServer(forQuery query: String, withDeleteOld deleteOld: Bool, modelManagerStoresUpdater: @escaping ([Store]) -> Void) {
        
        self.networkLayer.loadStoresFromServer(forQuery: query, networkLayerStoreUpdater: { [weak self] stores in
            
            guard let strongSelf = self else { return }
            
            strongSelf.dataLayer.saveInBackground(stores: stores, withDeleteOld: deleteOld, isFavs: false, saveInBackgroundSuccess: {
            
                let storeEntities = strongSelf.getAllStoresOnMainThread()
                modelManagerStoresUpdater(storeEntities)
            })
        })
    }
    
    // Use for loading stores by state
    func loadStoresFromServer(forQuery query: String, withDeleteOld deleteOld: Bool, withLocationPred predicate: NSPredicate, modelManagerStoresUpdater: @escaping ([Store]) -> Void) {
        
        self.networkLayer.loadStoresFromServer(forQuery: query, networkLayerStoreUpdater: { [weak self] stores in
            
            guard let strongSelf = self else { return }
            
            strongSelf.dataLayer.saveInBackground(stores: stores, withDeleteOld: deleteOld, isFavs: false, saveInBackgroundSuccess: {
                
                let storeEntities = strongSelf.getLocationFilteredStores(forPredicate: predicate)
                modelManagerStoresUpdater(storeEntities)
            })
        })
    }
}
