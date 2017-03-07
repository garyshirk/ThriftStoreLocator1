//
//  StoresViewModel.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation

protocol StoresViewModelDelegate: class {
    func handleStoresUpdated(stores: [Store])
}

class StoresViewModel {
    
    private var modelManager: ModelManager
    weak var delegate: StoresViewModelDelegate?
    var stores: [Store] = []
    
    init(delegate: StoresViewModelDelegate?, withLoadStores: Bool) {
        
        self.delegate = delegate
        
        modelManager = ModelManager.sharedInstance
        
        if withLoadStores {
            doLoadStores()
        }
    }
    
    func doLoadStores() {
        
        modelManager.loadStores(viewModelUpdater: { [weak self] storeEntities -> Void in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.stores = storeEntities
            
            print("Test stores received in StoresViewModel")
            
            //strongSelf.stores.forEach {print("Store Name: \($0.name)")}
            
            strongSelf.delegate?.handleStoresUpdated(stores: storeEntities)
        })
    }
}

