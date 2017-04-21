//
//  ModelManager.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import CoreData

private let _shareManager = ModelManager()

class ModelManager {

    class var shareManager: ModelManager {
        return _shareManager
    }
    
    var networkLayer = NetworkLayer()
    var dataLayer = DataLayer()
    
    func getAllStoresOnMainThread() -> [Store] {
        return dataLayer.getAllStoresOnMainThread()
    }
    
    func getLocationFilteredStores(forPredicate predicate: NSPredicate) -> [Store] {
        return dataLayer.getLocationFilteredStoresOnMainThread(forPredicate: predicate)
    }
    
    func deleteAllStoresFromCoreDataExceptFavs(modelManagerDeleteAllCoreDataExceptFavsUpdater: @escaping (ErrorType) -> Void) {
        
        self.dataLayer.deleteCoreDataObjectsExceptFavorites(deleteAllStoresExceptFavsUpdater: { error in
            modelManagerDeleteAllCoreDataExceptFavsUpdater(error)
        })
    }
    
    func postFavoriteToServer(store: Store, forUser user: String, modelManagerPostFavUpdater: @escaping (ErrorType) -> Void) {
        
        self.networkLayer.postFavorite(store: store, forUser: user, networkLayerPostFavUpdater: { [weak self] networkError in
            
            guard let strongSelf = self else { return }
            
            if networkError == .none {
                strongSelf.dataLayer.updateFavorite(isFavOn: true, forStoreEntity: store, saveInBackgroundSuccess: { dataLayerError in
                    if dataLayerError == .none {
                        modelManagerPostFavUpdater(ErrorType.none)
                    } else {
                        modelManagerPostFavUpdater(dataLayerError)
                    }
                })
            } else {
                modelManagerPostFavUpdater(networkError)
            }
        })
    }
    
    func removeFavoriteFromServer(store: Store, forUser user: String, modelManagerPostFavUpdater: @escaping (ErrorType) -> Void) {
        
        self.networkLayer.removeFavorite(store: store, forUser: user, networkLayerRemoveFavUpdater: { [weak self]  networkError in
            
            guard let strongSelf = self else { return }
            
            if networkError == .none {
                strongSelf.dataLayer.updateFavorite(isFavOn: false, forStoreEntity: store, saveInBackgroundSuccess: { dataLayerError in
                    if dataLayerError == .none {
                        modelManagerPostFavUpdater(.none)
                    } else {
                        modelManagerPostFavUpdater(dataLayerError)
                    }
                })
            } else {
                modelManagerPostFavUpdater(networkError)
            }
        })
    }
    
    
    func listFavorites(modelManagerListFavoritesUpdater: ([Store]) -> Void) {
        
        let stores = self.dataLayer.getFavoriteStoresOnMainThread()
        modelManagerListFavoritesUpdater(stores)
    }
    
    func loadFavoritesFromServer(forUser user: String, modelManagerLoadFavoritesUpdater: @escaping([Store], ErrorType) -> Void) {
        
        self.networkLayer.loadFavoritesFromServer(forUser: user, networkLayerLoadFavoritesUpdater: { [weak self] (stores, networkError) in
            
            guard let strongSelf = self else { return }
            
            if networkError == .none {
                strongSelf.dataLayer.saveInBackground(stores: stores, withDeleteOld: true, isFavs: true, saveInBackgroundSuccess: { dataLayerError in
                    if dataLayerError == .none {
                        let storeEntities = strongSelf.getAllStoresOnMainThread()
                        modelManagerLoadFavoritesUpdater(storeEntities, .none)
                    } else {
                        modelManagerLoadFavoritesUpdater([Store](), dataLayerError)
                    }
                })
            } else {
                modelManagerLoadFavoritesUpdater([Store](), networkError)
            }
        })
    }
    
    // Use for loading stores by county
    func loadStoresFromServer(forQuery query: String, withDeleteOld deleteOld: Bool, modelManagerStoresUpdater: @escaping ([Store], ErrorType) -> Void) {
        
        self.networkLayer.loadStoresFromServer(forQuery: query, networkLayerStoreUpdater: { [weak self] (stores, networkError) in
            
            guard let strongSelf = self else { return }
            
            if networkError == .none {
                strongSelf.dataLayer.saveInBackground(stores: stores, withDeleteOld: deleteOld, isFavs: false, saveInBackgroundSuccess: { dataLayerError in
                    
                    if dataLayerError == .none {
                        let storeEntities = strongSelf.getAllStoresOnMainThread()
                        modelManagerStoresUpdater(storeEntities, ErrorType.none)
                    } else {
                        modelManagerStoresUpdater([Store](), dataLayerError)
                    }
                })
            } else {
                modelManagerStoresUpdater([Store](), networkError)
            }
        })
    }
    
    // Use for loading stores by state
    func loadStoresFromServer(forQuery query: String, withDeleteOld deleteOld: Bool, withLocationPred predicate: NSPredicate, modelManagerStoresUpdater: @escaping ([Store], ErrorType) -> Void) {
        
        self.networkLayer.loadStoresFromServer(forQuery: query, networkLayerStoreUpdater: { [weak self] (stores, networkError) in
            
            guard let strongSelf = self else { return }
            
            if networkError == .none {
                
                strongSelf.dataLayer.saveInBackground(stores: stores, withDeleteOld: deleteOld, isFavs: false, saveInBackgroundSuccess: { dataLayerError in
                    
                    if dataLayerError == .none {
                        let storeEntities = strongSelf.getLocationFilteredStores(forPredicate: predicate)
                        modelManagerStoresUpdater(storeEntities, ErrorType.none)
                    } else {
                        modelManagerStoresUpdater([Store](), dataLayerError)
                    }
                })
            } else {
                modelManagerStoresUpdater([Store](), networkError)
            }
        })
    }
}
