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
    
    func handleStoresUpdated(forLocation location: CLLocationCoordinate2D, withZoomDistance zoomDistance: Double)
    
    func handleFavoritesLoaded()
    
    func handleFavoriteUpdated()
    
    func handleFavoritesList()
    
    func getUserLocation() -> CLLocationCoordinate2D?
    
    func getSortType() -> StoreSortType?
    
    func getMapZoomDistance() -> Double?
}

class StoresViewModel {
    
    var isLoadByState = false
    
    private var modelManager: ModelManager
    
    weak var delegate: StoresViewModelDelegate?
    
    var stores: [Store] = []
    
    var favoriteStores: [Store] = []
    
    var county: String = ""
    
    var state: String = ""
    
    var query: String = ""
    
    var showStoreRadius: Double = 25.0 // Constant - filter stores loaded from server to 25 mile radius of location (in miles)
    
    var storeLocationPredicate: NSPredicate?
    
    var locationLoadedFromServer: String?
    
    var countyPreviouslyLoadedDict = [String: String]() // When loading by counties allow loading multiple counties in a session
    var statePreviouslyLoaded = "" // When loading by state, allow only one state's stores to be in core data at any one time
    
    var mapLocation: CLLocationCoordinate2D?
    
    lazy var geocoder = CLGeocoder()
    
    init(delegate: StoresViewModelDelegate?) {
        self.delegate = delegate
        self.modelManager = ModelManager.sharedInstance
    }
    
    // MARK - public functions
    
    func resetStoresViewModel() {
        stores.removeAll()
        county = ""
        state = ""
        query = ""
        countyPreviouslyLoadedDict.removeAll()
        statePreviouslyLoaded = ""
    }
    
    func setMapZoomArea(radius: Double) {
        
    }
    
    func postFavorite(forStore store: Store, user: String) {
        
        modelManager.postFavoriteToServer(store: store, forUser: user, modelManagerPostFavUpdater: {
        
            self.delegate?.handleFavoriteUpdated()
        })
    }
    
    func removeFavorite(forStore store: Store, user: String) {
        
        modelManager.removeFavoriteFromServer(store: store, forUser: user, modelManagerPostFavUpdater: {
            
            self.delegate?.handleFavoriteUpdated()            
        })
    }
    
    func getListOfFavorites() {
        
        modelManager.listFavorites(modelManagerListFavoritesUpdater: { [weak self] storeEntities -> Void in
        
            guard let strongSelf = self else {
                return
            }
            
            let sortType = strongSelf.delegate?.getSortType()
            strongSelf.favoriteStores = strongSelf.setStoreSortOrder(by: sortType!, forStores: storeEntities)
            
            strongSelf.delegate?.handleFavoritesList()
        })
    }
    
    func loadFavorites(forUser user: String) {
        
        modelManager.loadFavoritesFromServer(forUser: user, modelManagerLoadFavoritesUpdater: { [weak self] storeEntities -> Void in
        
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.delegate?.handleFavoritesLoaded()
        })
    }
    
    func loadStores(forLocation location: CLLocationCoordinate2D, withRefresh isRefresh: Bool) {
        setCountyStoreFilterAndLoadStores(forLocation: location, deleteOld: isRefresh)
    }
    
    func loadStores(forSearchStr searchStr: String) {
        setLocationInfo(forAddressStr: searchStr)
    }
    
    func prepareForZoomToMyLocation(location:CLLocationCoordinate2D) {
        
        var deleteOld: Bool?
        if isLoadByState == false { // Loading store by county
            deleteOld = true
        } else { // Loading stores by state
            deleteOld = false
        }
        setCountyStoreFilterAndLoadStores(forLocation: location, deleteOld: deleteOld!)
    }
    
    func setStoreSortOrder(by sortType: StoreSortType) {
        switch sortType {
        case .distance:
            self.stores = sortStoresByDistance(forStores: self.stores)
        case .name:
            self.stores = sortStoresByName(forStores: self.stores)
        }
    }
    
    private func setStoreSortOrder(by sortType: StoreSortType, forStores stores: [Store]) -> [Store] {
        
        switch sortType {
        case .distance:
            return sortStoresByDistance(forStores: stores)
            
        case .name:
            return sortStoresByName(forStores: stores)
        }
    }
    
    private func doLoadStores(deleteOld: Bool) {
        
        if isLoadByState == false { //Loading stores by county
            
            if let _ = countyPreviouslyLoadedDict[self.county] {
                
                let stores = modelManager.getAllStoresOnMainThread()
                filterStoresAndInformMainController(stores: stores)
                
            } else {
            
                modelManager.loadStoresFromServer(forQuery: query, withDeleteOld: deleteOld, modelManagerStoresUpdater: { [weak self] storeEntities -> Void in
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.countyPreviouslyLoadedDict[strongSelf.county] = strongSelf.locationLoadedFromServer
                    strongSelf.filterStoresAndInformMainController(stores: storeEntities)
                })
            }
            
        } else { // Loading stores by state
            
            if statePreviouslyLoaded == self.query {
                
                let stores = modelManager.getLocationFilteredStores(forPredicate: storeLocationPredicate!)
                updateMainController(stores: stores)
                
            } else {
                
                modelManager.deleteAllStoresFromCoreDataExceptFavs( modelManagerDeleteAllCoreDataExceptFavsUpdater: { [weak self] in
                    
                    guard let strongSelf = self else { return }
                    
                    strongSelf.modelManager.loadStoresFromServer(forQuery: strongSelf.query, withDeleteOld: deleteOld, withLocationPred: strongSelf.storeLocationPredicate!, modelManagerStoresUpdater: { [weak self] storeEntities -> Void in
                        
                        guard let strongSelf = self else {
                            return
                        }
                        
                        strongSelf.statePreviouslyLoaded = strongSelf.query
                        strongSelf.updateMainController(stores: storeEntities)
                    })
                })
            }
        }
    }
    
     private func filterStoresAndInformMainController(stores: [Store]) {
        
        let locationFilteredStores = (stores as NSArray).filtered(using: self.storeLocationPredicate!)
        
        let stores = locationFilteredStores as! [Store]
        
        let sortType = self.delegate?.getSortType()
        self.stores = self.setStoreSortOrder(by: sortType!, forStores: stores)
        
        let mapZoomDistance = delegate?.getMapZoomDistance()
        self.delegate?.handleStoresUpdated(forLocation: self.mapLocation!, withZoomDistance: mapZoomDistance!)
    }
    
    private func updateMainController(stores: [Store]) {
        
        self
            .stores = stores
        
        let sortType = self.delegate?.getSortType()
        self.stores = self.setStoreSortOrder(by: sortType!, forStores: stores)
        
        let mapZoomDistance = delegate?.getMapZoomDistance()
        self.delegate?.handleStoresUpdated(forLocation: self.mapLocation!, withZoomDistance: mapZoomDistance!)
    }

    
    private func sortStoresByDistance(forStores stores: [Store]) -> [Store] {
        
        var dict = [String: Store]()
        var index = 0
        for store in stores {
            let distanceToStore = distance(fromMyLocation: (delegate?.getUserLocation())!, toStoreLocation: store)
            var key =  String(describing: distanceToStore) + "-" + String(describing: index)
            if key.contains(".") {
                let range: Range<String.Index> = key.range(of: ".")!
                let placesToDecimal = key.distance(from: key.startIndex, to: range.lowerBound)
                key = String(describing: placesToDecimal) + key
            } else {
                let placesToDecimal = key.characters.count
                key = String(describing: placesToDecimal) + key
            }
            dict[key] = store
            index += 1
        }
        
        let sortedKeys = Array(dict.keys).sorted{$0 < $1}
        
        var sortedStores: [Store] = []
        for key in sortedKeys {
            sortedStores.append(dict[key]!)
        }
        return sortedStores
    }
    
    private func sortStoresByName(forStores stores: [Store]) -> [Store] {
        return stores.sorted{$0.name! < $1.name!}
    }
    
    // Get the approximate area (expects radius to be in units of miles)
    private func setStoreFilters(forLocation location: CLLocationCoordinate2D, withRadiusInMiles radius:Double, andZip zip:String) {
        
        // TODO - Not ready for this yet, but once you start notifying user about geofence entries, will need to use CLCircularRegion
        // let region = CLCircularRegion.init(center: location, radius: radius, identifier: "region")
        
        self.mapLocation = location
        
        if zip.isEmpty {
            
            // Approximate a region based on location and radius, does not account for curvature of earth but ok for short distances
            let locLat = location.latitude
            let locLong = location.longitude
            let degreesLatDelta = milesToLatDegrees(for: radius)
            let degreesLongDelta = milesToLongDegrees(for: radius, atLatitude: locLat)
            
            let eastLong = locLong + degreesLongDelta
            let westLong = locLong - degreesLongDelta
            let northLat = locLat + degreesLatDelta
            let southLat = locLat - degreesLatDelta
            
            let predicateNorthLat = NSPredicate(format: "%K < %@", "locLat", NSNumber(value: northLat))
            let predicateSouthLat = NSPredicate(format: "%K > %@", "locLat", NSNumber(value: southLat))
            let predicateEastLong = NSPredicate(format: "%K < %@", "locLong", NSNumber(value: eastLong))
            let predicateWestLong = NSPredicate(format: "%K > %@", "locLong", NSNumber(value: westLong))
            storeLocationPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateNorthLat, predicateSouthLat, predicateEastLong, predicateWestLong])
            
            //print("RegionLong: westLong: \(westLong), centerLong: \(locLong), eastLong: \(eastLong)")
            //print("RegionLat : northLat: \(northLat), centerLat: \(locLat), southLat: \(southLat)")
            
        } else {
            
            storeLocationPredicate = NSPredicate(format: "%K == %@", "zip", zip)
        }
    }
    
    private func isZipCode(forSearchStr searchStr:String) -> Bool {
        let regex = "^([^a-zA-Z][0-9]{4})$"
        if let _ = searchStr.range(of: regex, options: .regularExpression) {
            return true
        } else {
            return false
        }
    }
    
    private func setCountyStoreFilterAndLoadStores(forLocation location: CLLocationCoordinate2D, deleteOld: Bool) {
        
        let locationCoords: CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(locationCoords) { [weak self] (placemarks, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            if error != nil {
                print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                return
            }
            
            if let placemarks = placemarks, let placemark = placemarks.first {
                
                if strongSelf.isLoadByState == false { // Loading stores by county
                
                    if let county = placemark.subAdministrativeArea {
                        
                        strongSelf.locationLoadedFromServer = strongSelf.county
                        
                        strongSelf.county = county.lowercased().replacingOccurrences(of: " ", with: "+")
                        
                        strongSelf.setStoreFilters(forLocation: location, withRadiusInMiles: strongSelf.showStoreRadius, andZip: "")
                        
                        if let state = placemark.administrativeArea {
                            
                            strongSelf.state = state
                            
                            strongSelf.query = strongSelf.state + "/" + strongSelf.county
                            
                            strongSelf.doLoadStores(deleteOld: deleteOld)
                        } else {
                            print("Problem getting state")
                        }
                    }
                
                } else { // Loading stores by state
                    
                    if let state = placemark.administrativeArea {
                        
                        strongSelf.state = state
                        
                        strongSelf.query = state
                        
                        strongSelf.locationLoadedFromServer = strongSelf.state
                        
                        strongSelf.setStoreFilters(forLocation: location, withRadiusInMiles: strongSelf.showStoreRadius, andZip: "")
                        
                        strongSelf.doLoadStores(deleteOld: deleteOld)
                    
                    } else {
                        print("Problem getting state")
                    }
                }
            
            } else {
                print("Problem getting county")
            }
        }
    }
    
    private func setLocationInfo(forAddressStr address: String) {
        
        geocoder.geocodeAddressString(address) { [weak self] (placemarks, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            if error != nil {
                print("Geocoder failed with error" + (error?.localizedDescription)!)
                return
            }
            
            if let placemarks = placemarks, let placemark = placemarks.first {
                
                // Check if user entered a valid address as the search string
                var userSearchedAddress = false
                if let _ = placemark.subThoroughfare {
                    if let _ = placemark.thoroughfare {
                        userSearchedAddress = true
                    }
                }
                
                if strongSelf.isLoadByState == false { // Loading by county
                    
                    if let county = placemark.subAdministrativeArea {
                        
                        strongSelf.county = county.lowercased().replacingOccurrences(of: " ", with: "+")
                        strongSelf.state = placemark.administrativeArea!
                        
                        strongSelf.locationLoadedFromServer = strongSelf.county
                        
                        strongSelf.query = strongSelf.state + "/" + strongSelf.county
                        strongSelf.mapLocation = placemark.location?.coordinate
                        
                        var zip = ""
                        let isZip = strongSelf.isZipCode(forSearchStr: address)
                        if isZip == true {
                            zip = address
                        }
                        
                        if userSearchedAddress == true {
                            // Save for possible future use to change zoom radius if user searched for a particular address
                        } else {
                            
                        }
                        
                        strongSelf.setStoreFilters(forLocation: strongSelf.mapLocation!, withRadiusInMiles: strongSelf.showStoreRadius, andZip: zip)
                        strongSelf.doLoadStores(deleteOld: false)
                    }
                
                } else { // Loading by state
                    
                    if let state = placemark.administrativeArea {
                        
                        strongSelf.state = state
                        
                        strongSelf.query = strongSelf.state
                        
                        strongSelf.locationLoadedFromServer = strongSelf.state
                        
                        strongSelf.mapLocation = placemark.location?.coordinate
                        
                        var zip = ""
                        let isZip = strongSelf.isZipCode(forSearchStr: address)
                        if isZip == true {
                            zip = address
                        }
                        
                        if userSearchedAddress == true {
                            // Save for possible future use to change zoom radius if user searched for a particular address
                        } else {
                            
                        }
                        
                        strongSelf.setStoreFilters(forLocation: strongSelf.mapLocation!, withRadiusInMiles: strongSelf.showStoreRadius, andZip: zip)
                        strongSelf.doLoadStores(deleteOld: false)
                    }
                }
                
            } else {
                print("Problem getting county")
            }
        }
    }
}

extension MutableCollection where Self : RandomAccessCollection {
    /// Sort `self` in-place using criteria stored in a NSSortDescriptors array
    public mutating func sort(sortDescriptors theSortDescs: [NSSortDescriptor]) {
        sort { by:
            for sortDesc in theSortDescs {
                switch sortDesc.compare($0, to: $1) {
                case .orderedAscending: return true
                case .orderedDescending: return false
                case .orderedSame: continue
                }
            }
            return false
        }
    }
}

extension StoresViewModel {
    
    func distance(fromMyLocation myLoc: CLLocationCoordinate2D, toStoreLocation store: Store) -> Double {
        let toLatDouble = store.locLat?.doubleValue
        let toLongDouble = store.locLong?.doubleValue
        let myLocation = CLLocation(latitude: myLoc.latitude, longitude: myLoc.longitude)
        let storeLoc = CLLocation(latitude: toLatDouble!, longitude: toLongDouble!)
        return myLocation.distance(from: storeLoc)
    }
    
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
