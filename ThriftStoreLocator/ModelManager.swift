//
//  ModelManager.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation

class ModelManager {
    
    static var sharedInstance = ModelManager()
    
    var networkLayer = NetworkLayer()
    var dataLayer = DataLayer()
    
//    func getStoresOnMainThread() -> [Store] {
//        return dataLayer.getMessagesOnMainThread()
//    }
    
    func loadMessages() {
        
        networkLayer.loadStoresFromServer()
    }
    
    
}
