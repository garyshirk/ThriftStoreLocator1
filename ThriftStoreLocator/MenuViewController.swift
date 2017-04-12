//
//  DrawerTableViewController.swift
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

protocol MenuViewDelegate: class {
    
    func userSelectedMenuLoginCell()
    
    func userSelectedManageFavorites()
    
    func sortTypeSelected(sortType: StoreSortType)
}

class MenuTableViewController: UITableViewController {
    
    enum Section: Int {
        case searchSettings
        case favorites
        case login
    }
    
    weak var menuViewDelegate: MenuViewDelegate?
    
    var isLoggedIn: Bool?
    var isRegistered: Bool?
    var username: String?
    var sortType: StoreSortType?
    
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
        
        switch section {
        case 0:
            headerText = "Search Settings"
        case 1:
            headerText = "Favorites"
        case 2:
            headerText = "Logged In As"
        default:
            break
        }

        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.frame = header.frame
        header.textLabel?.text = headerText
    }
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        let section: Section = MenuTableViewController.Section(rawValue: indexPath.section)!
        
        switch section {
            case .searchSettings:
                if row == 0 {
                    
                } else {
                    
                }
            case .favorites:
                if row == 0 {
                    dismiss(animated: true, completion: nil)
                    self.menuViewDelegate?.userSelectedManageFavorites()
                } else {
                    
            }
            case .login:
                if row == 0 {
                    
                } else {
                    self.menuViewDelegate?.userSelectedMenuLoginCell()
                }
        }
    }
    
    @IBAction func sortTypeSelected(_ sender: Any) {
        let selection = self.sortSegControl.selectedSegmentIndex
        switch selection {
        case 0:
            self.menuViewDelegate?.sortTypeSelected(sortType: .distance)
            self.sortType = .distance
        case 1:
            self.menuViewDelegate?.sortTypeSelected(sortType: .name)
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
