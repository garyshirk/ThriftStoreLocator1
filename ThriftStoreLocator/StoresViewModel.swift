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
    
    func handleStoresUpdated(forLocation location:CLLocationCoordinate2D)
}


class StoresViewModel {
    
    private var modelManager: ModelManager
    
    weak var delegate: StoresViewModelDelegate?
    
    var stores: [Store] = []
    
    //var storeFilter: String = "?upper_long=-42.8&lower_long=-43&upper_lat=62.3&lower_lat=62"
    var storeFilterStr = ""
    
    var locationInfoDict: [String: Any]?
    
    var mapLocation: CLLocationCoordinate2D?
    
    
    init(delegate: StoresViewModelDelegate?, withLoadStores: Bool) {
        self.delegate = delegate
        modelManager = ModelManager.sharedInstance
        if withLoadStores {
            
            // DEBUG - Do not load stores while testing Map location api
            //doLoadStores()
            // instead:
            //doGetLocationInfo()
        }
    }
    
    func doSearch(forSearchStr searchStr:String) {
        if isZipCode(forSearchStr: searchStr) {
            setStoreFilter(forSearchStr: searchStr)
            doLoadStores()
        } else {
            getLocationInfo(forSearchStr: searchStr)
        }
    }
    
    
    func getLocationInfo(forSearchStr searchStr:String) {
        
        modelManager.getLocationInfo(filter: searchStr, locationViewModelUpdater: { [weak self] returnedLocationDict -> Void in
        
            guard let strongSelf = self else {
                return
            }
            
            if (returnedLocationDict["error"] as! String) != "" {
                print(returnedLocationDict["error"] as! String)
                return
            }
            
            strongSelf.locationInfoDict = returnedLocationDict
            
            if let lat = (strongSelf.locationInfoDict?["lat"] as? NSString)?.doubleValue {
                if let long = (strongSelf.locationInfoDict?["long"] as? NSString)?.doubleValue {
                    let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    strongSelf.setStoreFilter(forLocation: location, withRadiusInMiles: 20)
                }
            // TODO - Not sure if rest of if statements are needed. I always want to find valid location coords above or flag error
            } else if let city = strongSelf.locationInfoDict?["city"], !(strongSelf.locationInfoDict?["city"] as! String).isEmpty {
                strongSelf.setStoreFilter(forSearchStr: city as! String)
            } else  if let zipcode = strongSelf.locationInfoDict?["zipcode"], !(strongSelf.locationInfoDict?["zipcode"] as! String).isEmpty {
                strongSelf.setStoreFilter(forSearchStr: zipcode as! String)
            }

            strongSelf.doLoadStores()
        })
    }
    
    func doLoadStores() {
        
        stores.removeAll()
        
        modelManager.loadStores(storeFilter: storeFilterStr, storesViewModelUpdater: { [weak self] storeEntities -> Void in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.stores = storeEntities
            //strongSelf.stores.forEach {print("Store Name: \($0.name)")}
            strongSelf.delegate?.handleStoresUpdated(forLocation: strongSelf.mapLocation!)
        })
    }
    
    // Get the approximate area (expects radius to be in units of miles)
    func setStoreFilter(forLocation location:CLLocationCoordinate2D, withRadiusInMiles radius:Double) {
        
        // TODO - Not ready for this yet, but once you start notifying user about geofence entries, will need to use CLCircularRegion
        // let region = CLCircularRegion.init(center: location, radius: radius, identifier: "region")
        
        // TODO - Place coord keys in constant class
        
        self.mapLocation = location
        
        // Approximate a region based on location and radius, does not account for curvature of earth but ok for short distances
        let locLat = location.latitude
        let locLong = location.longitude
        let degreesLatDelta = milesToLatDegrees(for: radius)
        let degreesLongDelta = milesToLongDegrees(for: radius, atLatitude: locLat)
        var coords = [String: Double]()
        coords["eastLong"] = locLong + degreesLongDelta
        coords["westLong"] = locLong - degreesLongDelta
        coords["northLat"] = locLat + degreesLatDelta
        coords["southLat"] = locLat - degreesLatDelta
        
        print("RegionLong: westLong: \(coords["westLong"]), centerLong: \(locLong), eastLong: \(coords["eastLong"])")
        print("RegionLat : northLat: \(coords["northLat"]), centerLat: \(locLat), southLat: \(coords["southLat"])")
        
        buildLocationFilterString(forLocationCoords: coords)
    }
    
    func buildLocationFilterString(forLocationCoords coords:[String:Double]) {
        
        guard let eastLong = coords["eastLong"],
              let westLong = coords["westLong"],
              let northLat = coords["northLat"],
              let southLat = coords["southLat"] else {
            print("Error - Could not unwrap location coordinates")
            return
        }
        
        // TODO - use constant class for dictionary keys
        storeFilterStr = "?" + "east_long=" +
                        String(describing: eastLong) +
                        "&west_long=" +
                        String(describing: westLong) +
                        "&north_lat=" +
                        String(describing: northLat) +
                        "&south_lat=" +
                        String(describing: southLat)
        
        print("Location Filter: \(storeFilterStr)")
    }
    
    func isZipCode(forSearchStr searchStr:String) -> Bool {
        let regex = "^([^a-zA-Z][0-9]{4})$"
        if let _ = searchStr.range(of: regex, options: .regularExpression) {
            return true
        } else {
            return false
        }
    }
    
    
    func setStoreFilter(forSearchStr searchStr:String) {
        
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

extension StoresViewModel {
    
    func milesToLatDegrees(for miles:Double) -> Double {
        // TODO - Add to constants class
        return miles / 69.0
    }
    
    func milesToLongDegrees(for miles:Double, atLatitude lat:Double) -> Double {
        
        // Approximations for long degree deltas based on lat found at www.csgnetwork.com/degreelenllavcalc.html
        
        let milesPerDeg:Double
        
        switch lat {
        
        case 0..<25.0:
            milesPerDeg = 62.7 // lat: 25.0
            break
            
        case 25.0..<30.0:
            milesPerDeg = 61.4 // lat: 27.5
            break
            
        case 30.0..<35.0:
            milesPerDeg = 58.4 // lat: 32.5
            break
            
        case 35.0..<40.0:
            milesPerDeg = 55.0 // lat: 37.5
            break
            
        case 40.0..<45.0:
            milesPerDeg = 51.1 // lat: 42.5
            break
            
        case 45.0..<60.0:
            milesPerDeg = 47.3 // lat: 47.0
            break
            
        default:
            milesPerDeg = 55.0 // lat:
            break
        }
        
        return miles / milesPerDeg
    }
}

