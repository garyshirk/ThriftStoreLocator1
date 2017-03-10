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

// TODO - MapView initial height should be proportional to device height

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, StoresViewModelDelegate {
    
    var viewModel: StoresViewModel!
    
    var searchedStores: [Store] = []
    
    var selectedStore: Store!
    
    var isSearching: Bool = false
    
    var titleBackgroundColor: UIColor!
    
    var previousScrollViewOffset: CGFloat = 0.0
    
    var barButtonDefaultTintColor: UIColor?
    
    var myLocation: (lat: Double, long: Double) = (0.0, 0.0)
    
    lazy var geocoder = CLGeocoder()
    
    let locationManager = CLLocationManager()

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
        

        // Side Menu appearance and configuration
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //SideMenuManager.menuAnimationBackgroundColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.NAV_BAR_TINT_COLOR))
        SideMenuManager.menuAnimationBackgroundColor = UIColor.white
        SideMenuManager.menuFadeStatusBar = false
        SideMenuManager.menuAnimationTransformScaleFactor = 1.0
        SideMenuManager.menuPresentMode = .menuSlideIn
        
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
        
        // Map Kit View
        mapView.mapType = .standard
        mapView.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // Get list of stores for current location
        // TODO - Use dependency injection for setting viewModel
        viewModel = StoresViewModel(delegate: self, withLoadStores: true)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.isUserInteractionEnabled = true
        
        // DEBUG
        // print(mapViewYConstraint.constant)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        myLocation.lat = locValue.latitude
        myLocation.long = locValue.longitude
        //print("locations = \(myLocation.lat) \(myLocation.long)")
        lookUpLocation()
    }
    
    func lookUpLocation() {
        
        let locationCoords: CLLocation = CLLocation(latitude: myLocation.lat, longitude: myLocation.long)
    
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
    
    // TODO - Don't need to pass back store array here because view is populated via viewModel.stores
    func handleStoresUpdated(stores: [Store]) {
        tableView.reloadData()
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
            searchedStores.removeAll()
            for store in viewModel.stores {
                if let storeStr = store.name {
                    if searchStr.isEmpty || (storeStr.localizedCaseInsensitiveContains(searchStr)) {
                        searchedStores.append(store)
                    }
                }
            }
        }
        tableView.reloadData()
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
        print("search button pressed")
        
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let viewModel = viewModel else {
            return 0 }
        
        if isSearching {
            return searchedStores.count
        } else {
            return viewModel.stores.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath)
        
        if isSearching {
            if let searchedStoreName = searchedStores[indexPath.row].name {
                cell.textLabel?.text = searchedStoreName
            }
        } else {
            if let storeName = viewModel.stores[indexPath.row].name {
                cell.textLabel?.text = storeName
            }
        }
        
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
                
                if isSearching {
                    selectedStore = searchedStores[(indexPath.row)]
                } else {
                    selectedStore = viewModel.stores[(indexPath.row)]
                }
            }
            
            if let detailViewController = segue.destination as? DetailViewController {
                detailViewController.storeNameStr = selectedStore.name
                detailViewController.distanceStr = "10 miles away"
                detailViewController.isFav = false
                detailViewController.streetStr = selectedStore.address
                detailViewController.cityStr = selectedStore.city
                detailViewController.stateStr = selectedStore.state
                detailViewController.zipStr = selectedStore.zip
                
                let locLat = selectedStore.locLat as! Double
                let locLong = selectedStore.locLong as! Double
                detailViewController.storeLocation = (locLat, locLong)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
