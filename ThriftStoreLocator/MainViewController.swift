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
import Firebase

// TODO - MapView initial height should be proportional to device height
// TODO - Define a CLCicularRegion based on user's current location and update store map and list when user leaves that region
class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, StoresViewModelDelegate, LogInDelegate, MenuViewDelegate, FavoriteButtonPressedDelegate {
    
    var mapHiddenView: Bool?
    
    var loginType: String?
    
    var username: String?
    
    var viewModel: StoresViewModel!
    
    var selectedStore: Store!
    
    var isSearching: Bool = false
    
    var searchBarButton: UIBarButtonItem!
    
    var titleBackgroundColor: UIColor!
    
    var previousScrollViewOffset: CGFloat = 0.0
    
    var barButtonDefaultTintColor: UIColor?
    
    var myLocation: CLLocationCoordinate2D?
    
    var mapLocation: CLLocationCoordinate2D?
    
    let locationManager = CLLocationManager()
    
    var needsInitialStoreLoad = false
    
    var refreshControl: UIRefreshControl?
    
    var showSearchAreaButton = false
    
    var favoritesViewController: FavoritesViewController?
    
    var sortType: StoreSortType?
    
    var mapZoomRadius: Double?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchThisAreaBtn: UIButton!
    @IBOutlet weak var mapViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapViewYConstraint: NSLayoutConstraint!
    // TODO - Move dimmerView to front of view on storyboard. Keeping it behind tableView during development
    @IBOutlet weak var dimmerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        
        // Scroll view inset adjustment handled by tableView constraints in storyboard
        self.automaticallyAdjustsScrollViewInsets = false
        
        //titleLabel.tintColor = UIColor.white
        titleBackgroundColor = searchView.backgroundColor
        titleLabel.text = "Thrift Store Locator"
        barButtonDefaultTintColor = self.view.tintColor
        
        if let sortTypeUserDef = UserDefaults.standard.value(forKey: StoreSortType.sortKey) {
            self.sortType = StoreSortType(rawValue: sortTypeUserDef as! String)
        } else {
            self.sortType = .distance
        }
        
        if let mapZoomRadiusUserDef = UserDefaults.standard.value(forKey: MapZoomRadius.mapZoomKey) {
            let mapZoomRadius = MapZoomRadius(rawValue: mapZoomRadiusUserDef as! String)
            if let mapZoomRadiusNonNil = mapZoomRadius {
                self.mapZoomRadius = mapZoomRadiusAsDouble(forRadius: mapZoomRadiusNonNil)
            } else {
                self.mapZoomRadius = 10.0
            }
        } else {
            self.mapZoomRadius = 10.0
        }
        
        self.mapHiddenView = false
        userSelectedDisplayType(isHideMap: self.mapHiddenView!)
        
        refreshControl = UIRefreshControl()
        if let refresh = refreshControl {
            refresh.attributedTitle = NSAttributedString(string: "")
            refresh.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
            tableView.addSubview(refresh)
        }
        
        setSearchEditMode(doSet: false)
        setSearchEnabledMode(doSet: false)
        searchTextField.delegate = self
        configureSearchButton()
        
        mapView.mapType = .standard
        mapView.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // KCLLocationAccuracyNearestTenMeters
        }
        
        viewModel = StoresViewModel(delegate: self)
        
        let user = FIRAuth.auth()?.currentUser
        updateLoginStatus(forUser: user)
        
        FIRAuth.auth()!.addStateDidChangeListener() { [weak self] auth, user in
            guard let strongSelf = self else { return }
            strongSelf.updateLoginStatus(forUser: user)
        }
        
        // Always segue to LoginViewController if user is first time or had previously registered and then logged out
        let regType = getRegistrationType()
        if regType == RegistrationType.firstTimeInApp ||
                      (regType == RegistrationType.registered && loginType == LogInType.isNotLoggedIn) {
            performSegue(withIdentifier: "presentLoginView", sender: nil)
        } else {
            doInitialLoad()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setShadowButton(button: self.searchThisAreaBtn)
        searchThisAreaBtn.isHidden = true
        tableView.isUserInteractionEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func doInitialLoad() {
        viewModel.resetStoresViewModel()
        // nil user is not logged in, so not necessary to load stores
        if let user = FIRAuth.auth()?.currentUser {
            viewModel.loadFavorites(forUser: user.uid)
        }
    }
    
    func refresh(sender: Any) {
        viewModel.loadStores(forLocation: mapLocation!, withRefresh: false)
    }
    
    func showActivityIndicator() {
        if IJProgressView.shared.isShowing() == false {
            IJProgressView.shared.showProgressView(view)
            UIApplication.shared.beginIgnoringInteractionEvents()
            dimmerView.isHidden = false
        }
    }
    
    func hideActivityIndicator() {
        IJProgressView.shared.hideProgressView()
        UIApplication.shared.endIgnoringInteractionEvents()
        dimmerView.isHidden = true
    }
    
    func setShadowButton(button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        button.layer.masksToBounds = false
        button.layer.shadowRadius = 1.0
        button.layer.shadowOpacity = 0.5
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
        sideMenuViewController.isLoggedIn = isLoggedIn()
        sideMenuViewController.isRegistered = (getRegistrationType() == RegistrationType.registered)
        sideMenuViewController.username = self.username ?? ""
        sideMenuViewController.displayTypeMapHidden = self.mapHiddenView
        sideMenuViewController.sortType = self.sortType
        sideMenuViewController.mapZoomRadius = self.mapZoomRadiusAsEnum(forRadius: self.mapZoomRadius!)
        sideMenuViewController.menuViewDelegate = self
        
        present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
    }
    
    // TODO - Need new arrow location image; current one has white background
    @IBAction func didPressLocArrow(_ sender: Any) {
        setSearchEnabledMode(doSet: false)
        viewModel.prepareForZoomToMyLocation(location: myLocation!)
    }
    
    @IBAction func didPressSearchAreaBtn(_ sender: Any) {
        viewModel.loadStores(forLocation: mapLocation!, withRefresh: false)
        searchThisAreaBtn.isHidden = true
    }
    
    // TODO - Currently no longer getting location after I get it first time; need to change this to update every couple minutes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let loc = manager.location?.coordinate {
            
            self.refreshControl?.endRefreshing()
            
            myLocation = loc
            mapLocation = loc
            
            if needsInitialStoreLoad == true {
                needsInitialStoreLoad = false
                locationManager.stopUpdatingLocation()
                viewModel.loadStores(forLocation: myLocation!, withRefresh: false)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let previousMapLocation = mapLocation {
            mapLocation = mapView.centerCoordinate
            
            let newLoc = CLLocation(latitude: (mapLocation?.latitude)!, longitude: (mapLocation?.longitude)!)
            let previousLoc = CLLocation(latitude: previousMapLocation.latitude, longitude: previousMapLocation.longitude)
            let changeInDistance = newLoc.distance(from: previousLoc) * 0.000621371
            
            if showSearchAreaButton == true {
                if changeInDistance > 0.5 { // miles
                    searchThisAreaBtn.isHidden = false
                } else {
                    searchThisAreaBtn.isHidden = true
                }
            } else {
                searchThisAreaBtn.isHidden = true
                showSearchAreaButton = true
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Did click on annotation: \(String(describing: mapView.selectedAnnotations.first))")
    }
    
    func timer() {
        let when = DispatchTime.now() + 1 // seconds
        DispatchQueue.main.asyncAfter(deadline: when) {}
    }
    
    // MARK - StoresViewModelDelegate methods
    
    func handleFavoritesLoaded() {
        locationManager.startUpdatingLocation()
        needsInitialStoreLoad = true
    }
    
    func handleFavoriteUpdated() {
        self.tableView.reloadData()
        if let favoritesVC = self.favoritesViewController {
            favoritesVC.tableView.reloadData()
        }
    }
    
    func handleFavoritesList() {
        performSegue(withIdentifier: "showFavorites", sender: nil)
    }
    
    func handleStoresUpdated(forLocation location:CLLocationCoordinate2D, withZoomDistance distance: Double) {
        self.refreshControl?.endRefreshing()
        tableView.reloadData()
        zoomToLocation(at: location, withZoomDistanceInMiles: distance)
        
        for annotation in self.mapView.annotations {
            self.mapView.removeAnnotation(annotation)
        }
        
        for store in viewModel.stores {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: store.locLat as! CLLocationDegrees, longitude: store.locLong as! CLLocationDegrees)
            mapView.addAnnotation(annotation)
        }
    }
    
    func getUserLocation() -> CLLocationCoordinate2D? {
        return self.myLocation
    }
    
    func getSortType() -> StoreSortType? {
        return self.sortType
    }
    
    func getMapZoomDistance() -> Double? {
        // DEBUG
        return 500.0
        //return self.mapZoomRadius
    }
    
    func handleError(type: ErrorType) {
        // TODO - Receiving runtime warning when attempting to present alert view for Favorite post/delete errors:
        // "Presenting VC on detached VC is discouraged". Possible fix below, but not working:
        // http://stackoverflow.com/q/25401889/7601815
        // Note: At time of this writing error dialogs are not being shown for fav/unfav update failures
        DispatchQueue.main.async(execute: { () -> Void in
            let errorHandler = ErrorHandler()
            if let errorAlert = errorHandler.handleError(ofType: type) {
                 self.present(errorAlert, animated: true, completion: nil)
            }
            self.refreshControl?.endRefreshing()
        })
    }
    
    func zoomToLocation(at location: CLLocationCoordinate2D, withZoomDistanceInMiles distance: Double) {
        let region = MKCoordinateRegionMakeWithDistance(location, milesToMeters(for: distance), milesToMeters(for: distance))
        mapView.setRegion(region, animated: true)
        showSearchAreaButton = false
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
            viewModel.loadStores(forSearchStr: searchStr)
        }
    }
    
    func rightBarButtonItemPressed() {
        if isSearching == true {
            
        } else {
            
        }
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
        configureSearchButton()
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
    
    func configureSearchButton() {
       
        if isSearching == false {
            self.searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(MainViewController.searchPressed))
            self.navigationItem.rightBarButtonItem = self.searchBarButton
        } else {
            self.searchBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(MainViewController.searchPressed))
            self.navigationItem.rightBarButtonItem = self.searchBarButton
        }
    }
    
    func searchPressed() {
        isSearching = !isSearching
        if isSearching {
            setSearchEnabledMode(doSet: true)
        } else {
            setSearchEnabledMode(doSet: false)
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if mapHiddenView == true {
            return 88
        } else {
            return 68
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let viewModel = viewModel else {
            return 0
        }
        
        return viewModel.stores.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var selectedStore: Store
        selectedStore = viewModel.stores[indexPath.row]
        
        if mapHiddenView == true {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "storeCellListView", for: indexPath) as! StoreCellListView
            
            cell.storeLabel.text = selectedStore.name
            
            if let address = selectedStore.address, let city = selectedStore.city, let state = selectedStore.state {
                cell.addressLabel.text = "\(address), \(city), \(state)"
            }
            
            cell.distanceLabel.text = ("\(distanceFromMyLocation(toLat: selectedStore.locLat!, long: selectedStore.locLong!)) away")
            
            if selectedStore.isFavorite == true {
                cell.favImgView.isHidden = false
            } else {
                cell.favImgView.isHidden = true
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "storeCellMapView", for: indexPath) as! StoreCellMapView
            
            cell.storeLabel.text = selectedStore.name
            
            let dist = ("\(distanceFromMyLocation(toLat: selectedStore.locLat!, long: selectedStore.locLong!))")
            
            if let city = selectedStore.city, let state = selectedStore.state {
                cell.cityStateLabel.text = "\(city), \(state)  \(dist)"
            }
        
            cell.locationButton.tag = indexPath.row
            cell.locationButton.addTarget(self, action: #selector(locationButtonPressed), for: .touchUpInside)
            
            if selectedStore.isFavorite == true {
                cell.favImgView.isHidden = false
            } else {
                cell.favImgView.isHidden = true
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func locationButtonPressed(sender: Any) {
        let button = sender as! UIButton
        let selectedStore = viewModel.stores[button.tag]
        let location = CLLocationCoordinate2DMake(selectedStore.locLat as! CLLocationDegrees, selectedStore.locLong as! CLLocationDegrees)
        zoomToLocation(at: location, withZoomDistanceInMiles: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showStoreDetail" {
            
            // If navigation bar was hidden due to scrolling, restore it before seguing
            restoreNavigationBar()
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                selectedStore = viewModel.stores[(indexPath.row)]
                
                if let detailViewController = segue.destination as? DetailViewController {
                    detailViewController.delegate = self
                    detailViewController.selectedStoreIndex = indexPath.row
                    detailViewController.storeNameStr = selectedStore.name
                    detailViewController.isFav = selectedStore.isFavorite as! Bool!
                    detailViewController.streetStr = selectedStore.address
                    detailViewController.cityStr = selectedStore.city
                    detailViewController.stateStr = selectedStore.state
                    detailViewController.zipStr = selectedStore.zip
                    detailViewController.distanceStr = ("\(distanceFromMyLocation(toLat: selectedStore.locLat!, long: selectedStore.locLong!)) away")
                    let locLat = selectedStore.locLat as! Double
                    let locLong = selectedStore.locLong as! Double
                    detailViewController.storeLocation = (locLat, locLong)
                }
            }
            
        } else if segue.identifier == "presentLoginView" {
            
            if let loginVC = segue.destination as? LoginViewController {
                
                loginVC.logInDelegate = self
            }
        
        } else if segue.identifier == "showFavorites" {
            
            let favNavigationController = segue.destination as! UINavigationController
            self.favoritesViewController = (favNavigationController.topViewController as! FavoritesViewController)
            self.favoritesViewController?.delegate = self
            self.favoritesViewController?.favoriteStores = viewModel.favoriteStores
            self.favoritesViewController?.userLocation = self.myLocation
        }
    }
    
    // MARK - FavoriteButtonPressedDelegate
    
    func favoriteButtonPressed(forStore index: Int, isFav: Bool, isCallFromFavoritesVC: Bool) {
        
        let user = FIRAuth.auth()?.currentUser
        let uid = (user?.uid)!
        
        var store: Store?
        if isCallFromFavoritesVC == true {
            store = viewModel.favoriteStores[index]
        } else {
            store = viewModel.stores[index]
        }
        
        if  isFav == true {
            // Write new favorite to db and update Store entity in core data
            viewModel.postFavorite(forStore: store!, user: uid)
            
        } else {
            // Delete favorite from db and update Store entity in core data
            viewModel.removeFavorite(forStore: store!, user: uid)
        }
    }
    
    // MARK - LogInDelegates
    
    func getRegistrationType() -> String {
        
        let regStatus = UserDefaults.standard.value(forKey: RegistrationType.regKey) as? String
        if regStatus != nil {
            if regStatus == RegistrationType.firstTimeInApp {
                return RegistrationType.anonymousUser
            } else {
                return regStatus!
            }
        } else {
            return RegistrationType.firstTimeInApp
        }
    }
    
    func setRegistrationType(with regType: String) {
        UserDefaults.standard.setValue(regType, forKey: RegistrationType.regKey)
    }
    
    func isLoggedIn() -> Bool {
        return (loginType == LogInType.facebook as String ||
                loginType == LogInType.email as String)
    }
    
    func updateLoginStatus(forUser user: FIRUser?) {
        
        self.username = ""
        
        if user != nil {
            
            self.username = user!.email
            
            if let providerData = user?.providerData {
                for userInfo in providerData {
                    switch userInfo.providerID {
                    case "facebook.com":
                        loginType = LogInType.facebook as String
                    default:
                        if (user?.isAnonymous)! {
                            loginType = LogInType.anonymousLogin as String
                        } else {
                            loginType = LogInType.email as String
                        }
                    }
                }
            }
            
        } else {
            
            loginType = LogInType.isNotLoggedIn as String
        }
    }
    
    func handleUserLoggedIn(via loginType: String) {
        self.loginType = loginType
        dismiss(animated: false, completion: nil)
        doInitialLoad()
    }
    
    // MARK - MenuViewController delegates
    
    func userSelectedMenuLoginCell() {
        
        setSearchEnabledMode(doSet: false)
        
        dismiss(animated: true, completion: nil)
        
        if isLoggedIn() {
        
            if loginType == LogInType.facebook as String {
                let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
                fbLoginManager.logOut()
            }
            
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
                loginType = LogInType.isNotLoggedIn as String
            } catch let signOutError as NSError {
                print("Error logging out: %@", signOutError)
            }
        }
        performSegue(withIdentifier: "presentLoginView", sender: nil)
    }
    
    func userSelectedManageFavorites() {
        viewModel.getListOfFavorites()
    }
    
    func userSelectedDisplayType(isHideMap: Bool) {
        mapHiddenView = isHideMap
        if isHideMap == true {
            mapViewHeightConstraint.constant = 0.0
        } else {
            mapViewHeightConstraint.constant = 202.0
        }
        self.tableView.reloadData()
    }
    
    func userSelectedSortType(sortType: StoreSortType) {
        if self.sortType != sortType {
            UserDefaults.standard.setValue(sortType.rawValue, forKey: StoreSortType.sortKey)
            self.sortType = sortType
            viewModel.setStoreSortOrder(by: sortType)
            self.tableView.reloadData()
        }
    }
    
    func userSelectedMapZoomRadius(radius: MapZoomRadius) {
        self.mapZoomRadius = mapZoomRadiusAsDouble(forRadius: radius)
        UserDefaults.standard.setValue(radius.rawValue, forKey: MapZoomRadius.mapZoomKey)
        zoomToLocation(at: self.mapLocation!, withZoomDistanceInMiles: self.mapZoomRadius!)
    }
    
    func mapZoomRadiusAsDouble(forRadius radius: MapZoomRadius) -> Double {
        var radiusDouble = 10.0 // default
        switch radius {
        case .five:
            radiusDouble = 5.0
        case .ten:
            radiusDouble = 10.0
        case .fifteen:
            radiusDouble = 15.0
        case .twenty:
            radiusDouble = 20.0
        }
        return radiusDouble
    }
    
    func mapZoomRadiusAsEnum(forRadius radius: Double) -> MapZoomRadius {
        var mapZoomRadiusEnum: MapZoomRadius
        switch radius {
        case 5.0:
            mapZoomRadiusEnum = MapZoomRadius.five
        case 10.0:
            mapZoomRadiusEnum = MapZoomRadius.ten
        case 15.0:
            mapZoomRadiusEnum = MapZoomRadius.fifteen
        case 20.0:
            mapZoomRadiusEnum = MapZoomRadius.twenty
        default:
            mapZoomRadiusEnum = MapZoomRadius.ten // default in case of problem
        }
        return mapZoomRadiusEnum
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
