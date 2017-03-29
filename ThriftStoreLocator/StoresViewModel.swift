//
//  StoresViewModel.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

protocol StoresViewModelDelegate: class {
    
    func handleStoresUpdated(forLocation location:CLLocationCoordinate2D)
}

class StoresViewModel {
    
    private var modelManager: ModelManager
    
    weak var delegate: StoresViewModelDelegate?
    
    var stores: [Store] = []
    
    var county: String = ""
    
    var storeFilterStr = ""
    
    var storeFilterPredicate: NSPredicate?
    
    var storeFilterTracker = [String:NSPredicate]()
    
    var locationInfoDict: [String: Any]?
    
    var mapLocation: CLLocationCoordinate2D?
    
    var searchType: SearchType
    
    lazy var geocoder = CLGeocoder()
    
    enum SearchType {
        case zipcode
        case other
    }
    
    
    init(delegate: StoresViewModelDelegate?) {
        self.delegate = delegate
        modelManager = ModelManager.sharedInstance
        searchType = .other
    }
    
    func doSearch(forSearchStr searchStr:String) {
        
        setLocationInfo(forAddressStr: searchStr)
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
            
            // Always load stores based on location coordinates unless user specifically searched for a zip code
            if let lat = (strongSelf.locationInfoDict?["lat"] as? NSString)?.doubleValue {
                
                if let long = (strongSelf.locationInfoDict?["long"] as? NSString)?.doubleValue {
                    
                    let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    
                    if strongSelf.searchType == .zipcode {
                        
                        if let zipcode = strongSelf.locationInfoDict?["zip"], !(strongSelf.locationInfoDict?["zip"] as! String).isEmpty {
                            
                            strongSelf.setStoreFilters(forLocation: location, withRadiusInMiles: 10, andZip: zipcode as! String)
                        }
                    
                    } else {
                        
                        strongSelf.setStoreFilters(forLocation: location, withRadiusInMiles: 10, andZip: "")
                    }
                }
            }
            
            // Have we seen this search string before? If yes, maybe no need to load from server
            if strongSelf.storeFilterTracker[searchStr] != nil {
                strongSelf.stores = strongSelf.modelManager.getAllStoresOnMainThread()
                let filteredStores = (strongSelf.stores as NSArray).filtered(using: strongSelf.storeFilterTracker[searchStr]!)
                strongSelf.stores = filteredStores as! [Store]
                strongSelf.delegate?.handleStoresUpdated(forLocation: strongSelf.mapLocation!)
            } else {
                strongSelf.storeFilterTracker[searchStr] = strongSelf.storeFilterPredicate
                strongSelf.doLoadStores(deleteOld: false)
            }
        })
    }
    
    func loadInitialStores(forLocation location:CLLocationCoordinate2D, withRadiusInMiles radius:Double) {
        
        setStoreFilters(forLocation: location, withRadiusInMiles: radius, andZip: "")
        
        setCounty(forLocation: location, deleteOld: true)
        
    }
    
    func doLoadStores(deleteOld: Bool) {
        
        modelManager.loadStoresFromServer(forCounty: county, withDeleteOld: deleteOld, storesViewModelUpdater: { [weak self] storeEntities -> Void in
            
            guard let strongSelf = self else {
                return
            }
            
            let filteredStores = (storeEntities as NSArray).filtered(using: strongSelf.storeFilterPredicate!)
            strongSelf.stores = filteredStores as! [Store]
            strongSelf.delegate?.handleStoresUpdated(forLocation: strongSelf.mapLocation!)
        })
    }
    
    func prepareForZoomToMyLocation(location:CLLocationCoordinate2D) {
        stores = modelManager.getAllStoresOnMainThread()
        setStoreFilters(forLocation: location, withRadiusInMiles: 10, andZip: "")
        let filteredStores = (stores as NSArray).filtered(using: storeFilterPredicate!)
        stores = filteredStores as! [Store]
        self.delegate?.handleStoresUpdated(forLocation: self.mapLocation!)
    }
    
    // Get the approximate area (expects radius to be in units of miles)
    func setStoreFilters(forLocation location:CLLocationCoordinate2D, withRadiusInMiles radius:Double, andZip zip:String) {
        
        // TODO - Not ready for this yet, but once you start notifying user about geofence entries, will need to use CLCircularRegion
        // let region = CLCircularRegion.init(center: location, radius: radius, identifier: "region")
        
        // TODO - Place coord keys in constant class
        self.mapLocation = location
        
        if !zip.isEmpty {
            storeFilterStr = "?bizZip=\(zip)"
            storeFilterPredicate = NSPredicate(format: "%K == %@", "zip", zip)
        }
        
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
        
        buildLocationFilters(forLocationCoords: coords)
    }
    
    func buildLocationFilters(forLocationCoords coords:[String:Double]) {
        
        // Create the filter string used by server to get the within this location
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
        
        // Create the filter predicate used by this class to select which store should be shown in the MainViewController
        // This is needed because when user searches and goes to a new location we keep the stores at the previous location in Core Data
        // to minimize server accesses
        let predicateNorthLat = NSPredicate(format: "%K < %@", "locLat", NSNumber(value: northLat))
        let predicateSouthLat = NSPredicate(format: "%K > %@", "locLat", NSNumber(value: southLat))
        let predicateEastLong = NSPredicate(format: "%K < %@", "locLong", NSNumber(value: eastLong))
        let predicateWestLong = NSPredicate(format: "%K > %@", "locLong", NSNumber(value: westLong))
        storeFilterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateNorthLat, predicateSouthLat, predicateEastLong, predicateWestLong])
    }
    
    func isZipCode(forSearchStr searchStr:String) -> Bool {
        let regex = "^([^a-zA-Z][0-9]{4})$"
        if let _ = searchStr.range(of: regex, options: .regularExpression) {
            return true
        } else {
            return false
        }
    }
    
    func setCounty(forLocation location: CLLocationCoordinate2D, deleteOld: Bool) {
        
        let locationCoords: CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(locationCoords) { (placemarks, error) in
            
            if error != nil {
                print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                return
            }
            
            if let placemarks = placemarks, let placemark = placemarks.first {
                
                self.county = placemark.subAdministrativeArea!.lowercased().replacingOccurrences(of: " ", with: "+")
                
                self.doLoadStores(deleteOld: deleteOld)
            
            } else {
                print("Problem getting county")
            }
        }
    }
    
    func setLocationInfo(forAddressStr address: String) {
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            
            if error != nil {
                print("Geocoder failed with error" + (error?.localizedDescription)!)
                return
            }
            
            if let placemarks = placemarks, let placemark = placemarks.first {
                
                self.county = placemark.subAdministrativeArea!.lowercased().replacingOccurrences(of: " ", with: "+")
                
                self.mapLocation = placemark.location?.coordinate
                
                self.setStoreFilters(forLocation: self.mapLocation!, withRadiusInMiles: 10, andZip: "")
                
                
                print("Placemarks: \(self.county)")
                
                
                self.doLoadStores(deleteOld: false)
                
                
            } else {
                print("Problem getting county")
            }
        }
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

