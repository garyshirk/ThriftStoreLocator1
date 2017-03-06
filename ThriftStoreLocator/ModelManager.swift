//
//  ModelManager.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation

class ModelManager {
    
    
    // TODO - Improve singleton implementation
    static var sharedInstance = ModelManager()
    
    var networkLayer = NetworkLayer()
    var dataLayer = DataLayer()
    
//    func getStoresOnMainThread() -> [Store] {
//        return dataLayer.getMessagesOnMainThread()
//    }
    
    func loadStores(serverLoadSuccess: @escaping ([String]) -> Void) { //([Store]) -> Void) {
        
        networkLayer.loadStoresFromServer(loadStores: {stores in
            print("running enclosure in modelmanager: \(stores)")
            
            serverLoadSuccess(stores)
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
