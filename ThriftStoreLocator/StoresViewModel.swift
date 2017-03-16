//
//  StoresViewModel.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import CoreLocation

protocol StoresViewModelDelegate: class {
    
    func handleStoresUpdated(stores: [Store])
    
    func searchedLocationUpdated(location: CLLocationCoordinate2D)
}


class StoresViewModel {
    
    private var modelManager: ModelManager
    
    weak var delegate: StoresViewModelDelegate?
    
    var stores: [Store] = []
    
    //var storeFilter: String = "?upper_long=-42.8&lower_long=-43&upper_lat=62.3&lower_lat=62"
    var storeFilterStr = ""
    
    var locationDict: [String: Any]?
    
    var searchedLocation: CLLocationCoordinate2D?
    
    
    init(delegate: StoresViewModelDelegate?, withLoadStores: Bool) {
        self.delegate = delegate
        modelManager = ModelManager.sharedInstance
        if withLoadStores {
            
            // DEBUG - Do not load stores while testing Map location api
            //doLoadStores()
            // instead:
            doGetLocationInfo()
        }
    }
    
    
    func doGetLocationInfo() {
        
        modelManager.getLocationInfo(filter: "houston", locationViewModelUpdater: { [weak self] returnedLocationDict -> Void in
        
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.locationDict = returnedLocationDict
            
            // TODO - Check locationDict["status"] = OK
            
            if let zipcode = strongSelf.locationDict?["zipcode"], !(strongSelf.locationDict?["zipcode"] as! String).isEmpty {
                strongSelf.setStoreFilterString(searchStr: zipcode as! String)
            } else if let city = strongSelf.locationDict?["city"], !(strongSelf.locationDict?["city"] as! String).isEmpty {
                strongSelf.setStoreFilterString(searchStr: city as! String)
            }
            
            if let lat = (strongSelf.locationDict?["lat"] as? NSString)?.doubleValue {
                if let long = (strongSelf.locationDict?["long"] as? NSString)?.doubleValue {
                    strongSelf.searchedLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    strongSelf.delegate?.searchedLocationUpdated(location: strongSelf.searchedLocation!)
                }
            }
        })
    }
    
    
    func doLoadStores() {
        
        modelManager.loadStores(storeFilter: storeFilterStr, storesViewModelUpdater: { [weak self] storeEntities -> Void in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.stores = storeEntities
            //strongSelf.stores.forEach {print("Store Name: \($0.name)")}
            strongSelf.delegate?.handleStoresUpdated(stores: storeEntities)
        })
    }
    
    
    func setStoreFilterString(searchStr: String) {
        
        // Check if searchStr is a 5 digit zip code
        let regex = "^([^a-zA-Z][0-9]{4})$"
        if let range = searchStr.range(of: regex, options: .regularExpression) {
            storeFilterStr = "?bizZip=\(searchStr.substring(with: range))"
        } else {
            storeFilterStr = "?search=\(searchStr)"
        }
        
        doLoadStores()
    }
}

