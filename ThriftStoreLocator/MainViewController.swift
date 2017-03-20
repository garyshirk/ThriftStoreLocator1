//
//  MainViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SideMenu
import FBSDKLoginKit

// DEBUG
import Alamofire
import SwiftyJSON


// TODO - MapView initial height should be proportional to device height
// TODO - Define a CLCicularRegion based on user's current location and update store map and list when user leaves that region

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, StoresViewModelDelegate, FacebookLogInDelegate {
    
    var isTestingPost: Bool = false
    
    var viewModel: StoresViewModel!
    
    var searchedStores: [Store] = []
    
    var selectedStore: Store!
    
    var isSearching: Bool = false
    
    var titleBackgroundColor: UIColor!
    
    var previousScrollViewOffset: CGFloat = 0.0
    
    var barButtonDefaultTintColor: UIColor?
    
    var myLocation: CLLocationCoordinate2D?
    
    var mapLocation: CLLocationCoordinate2D?
    
    lazy var geocoder = CLGeocoder()
    
    let locationManager = CLLocationManager()
    
    var isLocationReceived = false
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var searchBarButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapViewYConstraint: NSLayoutConstraint!
    
    // TODO - Move dimmerView to front of view on storyboard. Keeping it behind tableView during development
    @IBOutlet weak var dimmerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        
        // Uncomment the following to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Scroll view inset adjustment handled by tableView constraints in storyboard
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Search and Title configuration
        //titleLabel.tintColor = UIColor.white
        titleBackgroundColor = searchView.backgroundColor
        titleLabel.text = "Thrift Store Locator"
        barButtonDefaultTintColor = self.view.tintColor
        
        setSearchEditMode(doSet: false)
        setSearchEnabledMode(doSet: false)
        searchTextField.delegate = self
        
        // Set up Map Kit view
        mapView.mapType = .standard
        mapView.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // KCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // Set up StoresViewModel
        // TODO - Use dependency injection for setting viewModel
        viewModel = StoresViewModel(delegate: self)
        
        //
        if let _ = FBSDKAccessToken.current() {
            print("User is logged in")
        } else {
            print("User is logged out")
            performSegue(withIdentifier: "presentFacebookLoginView", sender: nil)
        }
        
        
        
        // DEBUG
        if isTestingPost == true {
            testPost()
            return
        }
    }
    
    // TODO - This will be moved to SideMenu
    @IBAction func logoutButton(_ sender: Any) {
        let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
        fbLoginManager.logOut()
        performSegue(withIdentifier: "presentFacebookLoginView", sender: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.isUserInteractionEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func didPressSideMenuButton(_ sender: Any) {
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let menuRightNavigationController = sb.instantiateViewController(withIdentifier: "sideMenuNavigationController") as! UISideMenuNavigationController
        menuRightNavigationController.leftSide = true
        SideMenuManager.menuRightNavigationController = menuRightNavigationController
        
        // Side Menu appearance and configuration
        // let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // SideMenuManager.menuAnimationBackgroundColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.NAV_BAR_TINT_COLOR))
        // SideMenuManager.menuAnimationBackgroundColor = UIColor.white
        SideMenuManager.menuAnimationBackgroundColor = UIColor.white
        SideMenuManager.menuFadeStatusBar = false
        SideMenuManager.menuAnimationTransformScaleFactor = 0.9
        SideMenuManager.menuPresentMode = .viewSlideOut
        
        let sideMenuViewController = menuRightNavigationController.viewControllers[0] as! MenuTableViewController
        sideMenuViewController.someString = "HELLO WORLD"
        
        present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
    }
    
    // TODO - Need new arrow location image; current one has white background
    @IBAction func didPressLocArrow(_ sender: Any) {
        viewModel.prepareForZoomToMyLocation(location: myLocation!)
    }

    // TODO - Currently no longer getting location after I get it first time; need to change this to update every couple minutes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let loc = manager.location?.coordinate {
            
            if isLocationReceived == false {
                
                isLocationReceived = true
                
                myLocation = loc
            
                viewModel.setStoreFilters(forLocation: myLocation!, withRadiusInMiles: 10, andZip: "")
                
                viewModel.doLoadStores(deleteOld: true)
            }
        }
    }
    
    // TODO - Don't need to pass back store array here because view is populated via viewModel.stores
    func handleStoresUpdated(forLocation location:CLLocationCoordinate2D) {
        tableView.reloadData()
        zoomToLocation(at: location)
        mapLocation = location
        
        for store in viewModel.stores {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: store.locLat as! CLLocationDegrees, longitude: store.locLong as! CLLocationDegrees)
            mapView.addAnnotation(annotation)
        }
    }
    
    func zoomToLocation(at location: CLLocationCoordinate2D) {
        let region = MKCoordinateRegionMakeWithDistance(location, milesToMeters(for: 10), milesToMeters(for: 10))
        mapView.setRegion(region, animated: true)
        
        //print("LOCATION - Lat:\(myLocation?.latitude), Long:\(myLocation?.longitude)")
    }
    
    
    func lookUpLocation() {
        
        let locationCoords: CLLocation = CLLocation(latitude: myLocation!.latitude, longitude: myLocation!.longitude)
    
        geocoder.reverseGeocodeLocation(locationCoords) { (placemarks, error) in
    
            print(locationCoords)
    
            if error != nil {
                print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                return
            }
    
            if let placemarks = placemarks, let placemark = placemarks.first, let zip = placemark.postalCode {
                
                let locality = placemark.locality ?? "No locality found"
                print("Locality: \(locality)")
                
                let subLocality = placemark.subLocality ?? "No sub locality found"
                print("Sub Locality: \(subLocality)")
                
                let name = placemark.name ?? "No name found"
                print("Name: \(name)")
                
                let region = placemark.region?.identifier ?? "No region found"
                print("Region Identifier: \(region)")
                
                print("Zip Code: \(zip)")
            } else {
                print("Problem with placemark data")
            }
        }
    }
    
    func distanceFromMyLocation(toLat: NSNumber, long: NSNumber) -> String {
        
        let toLatDouble = toLat.doubleValue
        let toLongDouble = long.doubleValue
        
        let myLoc = CLLocation(latitude: (myLocation?.latitude)!, longitude: (myLocation?.longitude)!)
        let storeLoc = CLLocation(latitude: toLatDouble, longitude: toLongDouble)
        var distance = myLoc.distance(from: storeLoc) * 0.000621371
        
        if distance < 0.1 {
            distance = distance * 5280.0
            return ("\(distance.roundTo(places: 1)) feet")
        } else if (distance >= 9) {
            return ("\(Int(distance)) miles")
        } else {
            return ("\(distance.roundTo(places: 1)) miles")
        }
    }
    
    
    // MARK: - TextField delegates
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setSearchEditMode(doSet: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setSearchEditMode(doSet: false)
        searchTextField.resignFirstResponder()
        return true
    }
    
    // May be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if let searchStr = searchTextField.text {
            
            viewModel.doSearch(forSearchStr: searchStr)
            
//            searchedStores.removeAll()
//            for store in viewModel.stores {
//                if let storeStr = store.name {
//                    if searchStr.isEmpty || (storeStr.localizedCaseInsensitiveContains(searchStr)) {
//                        searchedStores.append(store)
//                    }
//                }
//            }
        }
//        tableView.reloadData()
    }
    
    func setSearchEnabledMode(doSet setToEnabled: Bool) {
        if setToEnabled {
            isSearching = true
            setSearchEditMode(doSet: true)
            searchView.backgroundColor = UIColor.white
            titleLabel.isHidden = true
            searchTextField.isHidden = false
            searchTextField.becomeFirstResponder()
        } else {
            isSearching = false
            setSearchEditMode(doSet: false)
            searchView.backgroundColor = titleBackgroundColor
            titleLabel.isHidden = false
            searchTextField.isHidden = true
            searchTextField.text = ""
            searchTextField.resignFirstResponder()
            tableView.reloadData()
        }
    }
    
    func setSearchEditMode(doSet setToEdit: Bool) {
        if setToEdit {
            dimmerView.isHidden = false
            tableView.isUserInteractionEnabled = false
        } else {
            dimmerView.isHidden = true
            tableView.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        if isSearching {
            setSearchEnabledMode(doSet: false)
        } else {
            setSearchEnabledMode(doSet: true)
        }
    }
    
    // MARK - ScrollView
    
    func restoreNavigationBar() {
        mapViewYConstraint.constant = 0.0
        var frame = self.navigationController?.navigationBar.frame
        frame?.origin.y = 20
        self.navigationController?.navigationBar.frame = frame!
        searchView.alpha = 1.0
        searchBarButton.isEnabled = true
        searchBarButton.tintColor = barButtonDefaultTintColor
        menuBarButton.isEnabled = true
        menuBarButton.tintColor = barButtonDefaultTintColor
    }
    
    func updateBarButtonItems(alpha: CGFloat) {
        searchView.alpha = alpha
        if alpha < 0.5 {
            searchBarButton.isEnabled = false
            searchBarButton.tintColor = UIColor.clear
            menuBarButton.isEnabled = false
            menuBarButton.tintColor = UIColor.clear
        } else {
            searchBarButton.isEnabled = true
            searchBarButton.tintColor = barButtonDefaultTintColor
            menuBarButton.isEnabled = true
            menuBarButton.tintColor = barButtonDefaultTintColor
        }
    }
    
    // TODO - This code came with sample code to hide nav bar when scrolling
    // Purpose was to animate the nav bar title to and from 1 -> 0 alpha,
    // But that seems to be happening even though this code is commented out
    
//    func stoppedScrolling() {
//        if let frame = self.navigationController?.navigationBar.frame {
//            if frame.origin.y < 20 {
//                animateNavBarTo(y: -(frame.size.height - 21))
//            }
//        }
//    }

    
//    func animateNavBarTo(y: CGFloat) {
//        UIView.animate(withDuration: 0.2, animations: {
//            if var frame = self.navigationController?.navigationBar.frame {
//                let alpha: CGFloat = frame.origin.y >= y ? 0.0 : 1.0
//                frame.origin.y = y
//                self.navigationController?.navigationBar.frame = frame
//                self.updateBarButtonItems(alpha: alpha)
//            }
//        })
//    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            //stoppedScrolling()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if var frame = self.navigationController?.navigationBar.frame {
            let navHeightMinus21 = (frame.size.height) - 21
            let scrollOffset = scrollView.contentOffset.y
            let scrollDiff = scrollOffset - self.previousScrollViewOffset
            let scrollHeight = scrollView.frame.size.height
            let scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom
            
            if scrollOffset <= -scrollView.contentInset.top {
                frame.origin.y = 20
                //print("scrollOffset <= -scrollview: Nav bar should show")
                
            } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
                frame.origin.y = -navHeightMinus21
                //print("scrollOffset <+ scrollHeight >= -scrollContentSizeHeight: Nav bar should hide")
                
            } else {
                frame.origin.y = min(20, max(-navHeightMinus21, frame.origin.y - scrollDiff))
                //print("else clause: Nav bar should be moving")
            }
            
            let framePercentageHidden = (( 20 - (frame.origin.y)) / ((frame.size.height) - 1))
            updateBarButtonItems(alpha: 1.0 - framePercentageHidden)
            
            self.navigationController?.navigationBar.frame = frame
            self.previousScrollViewOffset = scrollOffset
            
            mapViewYConstraint.constant = frame.origin.y - 20
            
            // DEBUG
//            print("navBarY = \(frame.origin.y), mapViewY = \(mapViewYConstraint.constant)")
//            print("navHeightMinus21: \(navHeightMinus21)")
//            print("Alpha: \(1.0 - framePercentageHidden)")
//            print("scrollOffset: \(scrollOffset)")
//            print("scrollDiff: \(scrollDiff)")
//            print("scrollHeight: \(scrollHeight)")
//            print("scrollView.contentSize.ht: \(scrollView.contentSize.height)")
//            print("scrollView.contentInsetBottom: \(scrollView.contentInset.bottom)")
//            print("scrollContentSize: \(scrollContentSizeHeight)")
//            print("=====")
            
            // TODO - This code shrinks and grows map view as user scrolls, but needs to be smoother
//            if (frame.origin.y == -size) && (mapViewHeightConstraint.constant >= 100) {
//                mapViewHeightConstraint.constant = mapViewHeightConstraint.constant - 10
//            }
//            else if (frame.origin.y == 20) && (mapViewHeightConstraint.constant <= 200.0) {
//                mapViewHeightConstraint.constant = mapViewHeightConstraint.constant + 10
//            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    // MARK: - Table view data source and delegates
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let v = UIView()
//        v.backgroundColor = .blue
//        let segmentedControl = UISegmentedControl(frame: CGRect(x: 10, y: 5, width: tableView.frame.width - 20, height: 30))
//        segmentedControl.insertSegment(withTitle: "One", at: 0, animated: false)
//        segmentedControl.insertSegment(withTitle: "Two", at: 1, animated: false)
//        segmentedControl.insertSegment(withTitle: "Three", at: 2, animated: false)
//        v.addSubview(segmentedControl)
//        return v
//    }
//    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return mapViewHeight
//    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let viewModel = viewModel else {
            return 0
        }
        
        return viewModel.stores.count
//        if isSearching {
//            return searchedStores.count
//        } else {
//            return viewModel.stores.count
//        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath) as! StoreCell
        
        var selectedStore: Store
        
        selectedStore = viewModel.stores[indexPath.row]
//        if isSearching {
//            selectedStore = searchedStores[indexPath.row]
//        } else {
//            selectedStore = viewModel.stores[indexPath.row]
//        }
        
        cell.storeLabel.text = selectedStore.name
        if let city = selectedStore.city, let state = selectedStore.state {
            cell.cityStateLabel.text = "\(city), \(state)"
        }
        cell.distanceLabel.text = ("\(distanceFromMyLocation(toLat: selectedStore.locLat!, long: selectedStore.locLong!)) away")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showStoreDetail" {
            
            // If navigation bar was hidden due to scrolling, restore it before seguing
            restoreNavigationBar()
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                selectedStore = viewModel.stores[(indexPath.row)]
//                if isSearching {
//                    selectedStore = searchedStores[(indexPath.row)]
//                } else {
//                    selectedStore = viewModel.stores[(indexPath.row)]
//                }
            }
            
            if let detailViewController = segue.destination as? DetailViewController {
                detailViewController.storeNameStr = selectedStore.name
                detailViewController.isFav = false
                detailViewController.streetStr = selectedStore.address
                detailViewController.cityStr = selectedStore.city
                detailViewController.stateStr = selectedStore.state
                detailViewController.zipStr = selectedStore.zip
                detailViewController.distanceStr = ("\(distanceFromMyLocation(toLat: selectedStore.locLat!, long: selectedStore.locLong!)) away")
                let locLat = selectedStore.locLat as! Double
                let locLong = selectedStore.locLong as! Double
                detailViewController.storeLocation = (locLat, locLong)
            }
        
        } else if segue.identifier == "presentFacebookLoginView" {
            
            if let loginVC = segue.destination as? FacebookLoginViewController {
                
                loginVC.logInDelegate = self
            }
        }
    }
    
    func handleUserLoggedInViaFacebook() {
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // DEBUG 
    func testPost() {
        let thriftStoreUrl: String = "http://localhost:8000/thriftstores/"
        
        let newPost: [String: Any] = ["bizID": 66,
                                      "bizName": "Play It Again Store",
                                      "bizAddr": "113 Allen Rd",
                                      "bizCity": "Niles",
                                      "bizState": "IL",
                                      "bizZip": "61275",
                                      "locLat": 41.343,
                                      "locLong": -66.676]
        
        Alamofire.request(thriftStoreUrl, method: .post, parameters: newPost,
                          encoding: JSONEncoding.default)
            .responseJSON { response in
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    print("error calling POST on /todos/1")
                    print(response.result.error!)
                    return
                }
                // make sure we got some JSON since that's what we expect
                guard let json = response.result.value as? [String: Any] else {
                    print("didn't get todo object as JSON from API")
                    print("Error: \(response.result.error)")
                    return
                }
                // get and print the title
                guard let storeName = json["bizName"] as? String else {
                    print("Could not get store name from JSON")
                    return
                }
                print("The store name is: " + storeName)
        }
    }

}

extension MainViewController {
    func metersToMiles(for meters: Double) -> Double {
        // TODO - Add to a constants class
        return meters * 0.000621371
    }
    
    func milesToMeters(for miles: Double) -> Double {
        return miles / 0.000621371
    }
}

extension Double {
    // Rounds Double to decimal places value
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
