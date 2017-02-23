//
//  MainViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import SideMenu

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    
    var stores: [String] = ["Goodwill", "Salvation Army", "Savers", "Thrift on Main", "Sparrows Nest"]
    var searchedStores: [String] = []
    var selectedStore: String!
    var resultsController: UITableViewController!
    var searchController: UISearchController!
    
    // Total hack here: When store is selected from search results tableview, I set the selected store
    // in didSelect method, then programmatically perform a segue. But if user selects cell from 
    // regular tableview, then segue is automatically connected via storyboard and don't have a way
    // to know in prepareForSegue whether to set store from searched tableview or regular tableview
    var isSearchCellSelected: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Side Menu configuration
        // Prevent menu status bar from fading to black
        SideMenuManager.menuFadeStatusBar = false
        SideMenuManager.menuAnimationTransformScaleFactor = 1
        //SideMenuManager.menuAnimationBackgroundColor = UIColor(patternImage: UIImage(named: "stars")!)
        SideMenuManager.menuPresentMode = .menuSlideIn
        
        // Scroll view inset adjustment handled by tableView constraints in storyboard
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Search configuration
        resultsController = UITableViewController(style: .plain)
        resultsController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "searchedStoreCell")
        
        
        resultsController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mapCell")
        
        
        resultsController.tableView.dataSource = self
        resultsController.tableView.delegate = self
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchResultsUpdater = self
        self.tableView.tableHeaderView = searchController.searchBar
        
        /*
            The current view controller will present a search controller over its main view.
            Setting the definesPresentationContext property to true will indicate that the view controller’s
            view will be covered each time the search controller is shown over it.
            This will allow to avoid unknown behaviour
        */
        self.definesPresentationContext = true
        
        //makeGetCall()
        
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

    // MARK = Search Results Updating
    
    func updateSearchResults(for searchController: UISearchController) {
        searchedStores.removeAll()
        for store in stores {
            if store.localizedCaseInsensitiveContains(searchController.searchBar.text!) {
                searchedStores.append(store)
            }
        }
        self.resultsController.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return stores.count + 1
        } else {
            return searchedStores.count + 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellIdentifier: String!
        var storeName: String!
        
        let cell: UITableViewCell?
        
        if isMapCell(at: indexPath) {
            // this will eventually be the map cell
            cell = tableView.dequeueReusableCell(withIdentifier: "mapCell", for: indexPath)
            cell?.textLabel?.text = "--"
        } else {
            
            let index = indexPath.row - 1
            
            if tableView == self.tableView {
                cellIdentifier = "storeCell"
                storeName = self.stores[index]
            } else {
                cellIdentifier = "searchedStoreCell"
                storeName = self.searchedStores[index]
            }

            cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            
            cell?.textLabel?.text = storeName
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isMapCell(at: indexPath) {
            return
        }
        
        if tableView == resultsController.tableView {
            isSearchCellSelected = true
            selectedStore = searchedStores[indexPath.row - 1]
            self.performSegue(withIdentifier: "showStoreDetail", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func isMapCell(at indexPath: IndexPath) -> Bool {
        return indexPath.row == 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showStoreDetail" {
        
            // Determine if segue is from searched store cell or regular store cell
            let indexPath: IndexPath?
            if isSearchCellSelected {
                indexPath = resultsController.tableView.indexPathForSelectedRow
            } else {
                indexPath = tableView.indexPathForSelectedRow
            }
        
            // Do not segue if Map cell selected
            if isMapCell(at: indexPath!) {
                return
            }
        
            // If this is a segue for a regular cell, need to set the selectedStore
            if !isSearchCellSelected {
                selectedStore = stores[(indexPath?.row)! - 1]
            } else {
                // Hack!! - If this is segue for a search cell, then we're done with isSearchCellSelected,
                // reset it back to false
                isSearchCellSelected = false
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
