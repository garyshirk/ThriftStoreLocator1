//
//  MainViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import MapKit
import SideMenu

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate {
    
    var stores: [String] = ["Goodwill", "Salvation Army", "Savers", "Thrift on Main", "Sparrows Nest",
                            "Goodwill Schaumburg", "Goodwill2", "Salvation Army2", "Savers2",
                            "Thrift on Main2", "Sparrows Nest2", "Goodwill Crystal Lake",
                            "Thrift on Main3", "Sparrows Nest3", "Goodwill Carpentersville",
                            "Thrift on Main4", "Sparrows Nest4", "Goodwill Lake Zurich"]
    
    var searchedStores: [String] = []
    
    var selectedStore: String!
    
    var isSearching: Bool = false

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewHeightConstraint: NSLayoutConstraint!
    
    // TODO - Move dimmerView to front of view on storyboard. Keeping it behind tableView during development
    @IBOutlet weak var dimmerView: UIView!
    
    var titleBackgroundColor: UIColor!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        
        // Uncomment the following to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        

        // Side Menu appearance and configuration
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SideMenuManager.menuAnimationBackgroundColor = appDelegate.uicolorFromHex(rgbValue: 0x034517)
        SideMenuManager.menuFadeStatusBar = false
        SideMenuManager.menuAnimationTransformScaleFactor = 1
        SideMenuManager.menuPresentMode = .menuSlideIn
        
        // Scroll view inset adjustment handled by tableView constraints in storyboard
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Search and Title configuration
        titleBackgroundColor = searchView.backgroundColor
        titleLabel.text = "Thrift Store Locator"
        titleLabel.tintColor = UIColor.white
        setSearchEditMode(doSet: false)
        setSearchEnabledMode(doSet: false)
        searchTextField.delegate = self
        
        // Map Kit View
        mapView.mapType = .standard
        mapView.delegate = self
        
        
        
        
        //makeGetCall()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewWillAppear")
        tableView.isUserInteractionEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("ViewWillDisappear")
    }
        
    // NOTE: Search bar tutorial json task from http://sweettutos.com/2015/12/26/hands-on-uisearchcontroller-the-complete-guide/
    // But below is old Swift code; Swift 3 updated code is in next function and is working https://grokswift.com/updating-nsurlsession-to-swift-3-0/
//    func retrieveFakeData() {
//        let session = URLSession.shared
//        let url:NSURL! = NSURL(string: "http://jsonplaceholder.typicode.com/users")
//    
//       
//        let task = session.downloadTaskWithURL(url as URL) { (location: NSURL?, response: URLResponse?, error: NSError?) -> Void in
//            if (location != nil){
//                let data:NSData! = NSData(contentsOfURL: location!)
//                do{
//                    self.users = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as! [[String : AnyObject]]
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        self.tableView.reloadData()
//                    })
//                }catch{
//                    // Catch any exception
//                    print("Something went wrong")
//                }
//            }else{
//                // Error
//                print("An error occurred \(error)")
//            }
//        }
//        // Start the download task
//        task.resume()
//    }
    
    
    func makeGetCall() {
        // Set up URL request
        let urlString: String = "http://jsonplaceholder.typicode.com/todos/1" // note: this is a test url
        guard let url = URL(string: urlString) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        
        // Set up session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // Make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            
            // Handle returned response
            print(error ?? "no error")
            print(response!)
            
            // Parse the Json response data
            do {
                guard let todo = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
                    print("Error trying to convert data to JSON")
                    return
                }
                
                // Got the data
                print("Data is \(todo.description)")
                
                // Reload the tableView on the main thread
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                })
                
                // todo object is a dictionary, so can access the title using the "title" key
                guard let todoTitle = todo["title"] as? String else {
                    print("Could not get title from JSON")
                    return
                }
                print("The title is: \(todoTitle)")
            } catch {
                print("Error trying to convert data to JSON")
                return
            }
        })
        task.resume()
    }

    //    func makeGetCall() {
    //        // Set up URL request
    //        let todoEndpoint: String = "http://jsonplaceholder.typicode.com/users"
    //        guard let url = URL(string: todoEndpoint) else {
    //            print("Error: cannot create URL")
    //            return
    //        }
    //        let urlRequest = URLRequest(url: url)
    //
    //        // Set up session
    //        let config = URLSessionConfiguration.default
    //        let session = URLSession(configuration: config)
    //
    //        // Make the request
    //        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
    //            // Handle returned response
    //            print(error ?? "no error")
    //            print(response!)
    //        })
    //        task.resume()
    //    }

 
    // MARK: - TextField delegates
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Did begin editing search field")
        setSearchEditMode(doSet: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setSearchEditMode(doSet: false)
        searchTextField.resignFirstResponder()
        return true
    }
    
    // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("Did end editing search field")
        if let searchStr = searchTextField.text {
            searchedStores.removeAll()
            for store in stores {
                if searchStr.isEmpty || store.localizedCaseInsensitiveContains(searchStr) {
                    searchedStores.append(store)
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if mapViewHeightConstraint.constant > 80.0 {
//            mapViewHeightConstraint.constant = mapViewHeightConstraint.constant - 10.0
//            tableView.reloadData()
//        }
    }
    
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        
//        tableView.reloadData()
//        
//        if (scrollView.contentOffset.y > 400) {
//            headerHeight = 0.0;
//            
//            if (isHidden == NO) {
//                
//                isHidden = YES;
//                self.tableView.reloadData();
//            }
//            
//        } else {
//            headerHeight = 70.0;
//            
//            if (isHidden == YES) {
//                
//                isHidden = NO;
//                self.tableView.reloadData();
//            }
//        }
//    }
    
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
        if isSearching {
            return searchedStores.count
        } else {
            return stores.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath)
        
        if isSearching {
            cell.textLabel?.text = searchedStores[indexPath.row]
        } else {
            cell.textLabel?.text = stores[indexPath.row]
        }
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showStoreDetail" {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                if isSearching {
                    selectedStore = searchedStores[(indexPath.row)]
                } else {
                    selectedStore = stores[(indexPath.row)]
                }
            }
            
            let tabBarController = segue.destination as! UITabBarController
            tabBarController.navigationItem.title = selectedStore
            
            let detailNavigationController = tabBarController.viewControllers!.first as! UINavigationController
            let detailViewController = detailNavigationController.viewControllers.first as! DetailViewController
            detailViewController.labelString = selectedStore + " in Detail view"
            
            let mapNavigationController = tabBarController.viewControllers?[1] as! UINavigationController
            let mapViewController = mapNavigationController.viewControllers.first as! MapViewController
            mapViewController.labelString = selectedStore + " in Map view"
            
            print("Selected Store: \(selectedStore)")
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
