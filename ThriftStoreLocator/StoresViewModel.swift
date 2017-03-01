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
    
    var stores = [Store]()
    
    init(delegate: StoresViewModelDelegate?) {
        self.delegate = delegate
        modelManager = ModelManager.sharedInstance
        modelManager.loadMessages()
    }
    
}

