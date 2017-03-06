//
//  StoresViewModel.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation

protocol StoresViewModelDelegate: class {
    func handleStoresUpdated(stores: [String]) //[Store])
}

class StoresViewModel {
    
    private var modelManager: ModelManager
    
    weak var delegate: StoresViewModelDelegate?
    
    var stores: [Store] = []
    
    var testStores: [String] = []
    
    
    init(delegate: StoresViewModelDelegate?) {
        
        self.delegate = delegate
        
        modelManager = ModelManager.sharedInstance
        
        modelManager.loadStores(serverLoadSuccess: { [weak self] testStores -> Void in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.testStores = testStores
            print(strongSelf.testStores)
            
            //strongSelf.stores = stores
            //strongSelf.stores.forEach {print("Store Name: \($0.name)")}
            strongSelf.delegate?.handleStoresUpdated(stores: strongSelf.testStores)
        })
    }
    
}

