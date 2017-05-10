//
//  MenuTableViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit

enum StoreSortType: String {
    case distance = "sort_by_distance"
    case name = "sort_by_name"
    static let sortKey = "sort_type_key"
}

enum StoreDisplayType {
    case map
    case list
    case both
}

protocol MenuViewDelegate: class {
    
    func userSelectedMenuLoginCell()
    
    func userSelectedManageFavorites()
    
    func userSelectedDisplayType(displayType: StoreDisplayType)
    
    func userSelectedSortType(sortType: StoreSortType)
}

class MenuTableViewController: UITableViewController {
    
    enum Section: Int {
        case settings
        case account
    }
    
    weak var menuViewDelegate: MenuViewDelegate?
    
    var isLoggedIn: Bool?
    var isRegistered: Bool?
    var username: String?
    var displayType: StoreDisplayType?
    var sortType: StoreSortType?
    
    @IBOutlet weak var displaySegControl: UISegmentedControl!
    @IBOutlet weak var loginCell: UILabel!
    @IBOutlet weak var signedInAs: UILabel!
    @IBOutlet weak var sortSegControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.navigationItem.title = "Menu"
        let navBarDefaultBlueTextColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.DEFAULT_BLUE_COLOR))
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : navBarDefaultBlueTextColor]
        
        if isLoggedIn! == true {
            loginCell.text = "Sign Out"
        } else {
            if isRegistered! == true {
                loginCell.text = "Sign In"
            } else {
                loginCell.text = "Register"
            }
        }
        
        if username?.isEmpty == true {
            self.signedInAs.text = "Anonymous"
        } else {
            self.signedInAs.text = self.username
        }
        
        displaySegControl.setTitle("Map", forSegmentAt: 0)
        displaySegControl.setTitle("List", forSegmentAt: 1)
        displaySegControl.setTitle("Both", forSegmentAt:2)
        
        switch self.displayType! {
        case .map:
            displaySegControl.selectedSegmentIndex = 0
        case .list:
            displaySegControl.selectedSegmentIndex = 1
        case .both:
            displaySegControl.selectedSegmentIndex = 2
        }
        
        sortSegControl.setTitle("Distance", forSegmentAt: 0)
        sortSegControl.setTitle("Name", forSegmentAt: 1)
        if self.sortType == .distance {
            sortSegControl.selectedSegmentIndex = 0
        } else {
            sortSegControl.selectedSegmentIndex = 1
        }
        
        // Do not show empty tableView cells
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // This will be non-nil if a blur effect is applied
//        guard tableView.backgroundView == nil else {
//            return
//        }
//        
//        // Set up a background image in menu
//        let imageView = UIImageView(image: UIImage(named: "saturn"))
//        imageView.contentMode = .scaleAspectFit
//        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
//        tableView.backgroundView = imageView
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        var headerText: String = ""
        let sectionSw: Section = MenuTableViewController.Section(rawValue: section)!
        
        switch sectionSw {
        case .settings:
            headerText = "Settings"
        case .account:
            headerText = "Account"
        }

        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.frame = header.frame
        header.textLabel?.text = headerText
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        let section: Section = MenuTableViewController.Section(rawValue: indexPath.section)!
        
        switch section {
            case .settings:
                if row == 0 { // Display type
                    break
                } else if row == 1 { // Sort type
                    break
                } else if row == 2 { // Open favorites view
                    dismiss(animated: true, completion: nil)
                    self.menuViewDelegate?.userSelectedManageFavorites()
                }
        
            case .account:
                if row == 1 { // Login/out
                    self.menuViewDelegate?.userSelectedMenuLoginCell()
                }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       
        let row = indexPath.row
        let section: Section = MenuTableViewController.Section(rawValue: indexPath.section)!
        
        switch section {
        case .settings:
            if row == 0 { // Display type
                return 88.0
            } else if row == 1 { // Sort type
                return 88.0
            } else if row == 2 { // Go to favorites
                return 50.0
            }
            
        case .account:
            if row == 0 {
                return 44.0 // username
            } else {
                return 50.0 // Login/out
            }
        }
        return 50.0 // 
    }
    
    @IBAction func displaySegSelected(_ sender: Any) {
        let selection = self.displaySegControl.selectedSegmentIndex
        switch selection {
        case 0:
            self.displayType = .map
        case 1:
            self.displayType = .list
        case 2:
            self.displayType = .both
        default:
            break
        }
        self.menuViewDelegate?.userSelectedDisplayType(displayType: self.displayType!)
    }
    
    @IBAction func sortTypeSelected(_ sender: Any) {
        let selection = self.sortSegControl.selectedSegmentIndex
        switch selection {
        case 0:
            self.menuViewDelegate?.userSelectedSortType(sortType: .distance)
            self.sortType = .distance
        case 1:
            self.menuViewDelegate?.userSelectedSortType(sortType: .name)
            self.sortType = .name
        default:
            break
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
