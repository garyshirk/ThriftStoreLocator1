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

enum MapZoomRadius: String {
    case five = "five_miles"
    case ten = "ten_miles"
    case fifteen = "fifteen_miles"
    case twenty = "twenty_miles"
    static let mapZoomKey = "map_zoom_key"
}

protocol MenuViewDelegate: class {
    
    func userSelectedMenuLoginCell()
    
    func userSelectedManageFavorites()
    
    func userSelectedSortType(sortType: StoreSortType)
    
    func userSelectedMapZoomRadius(radius: MapZoomRadius)
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
    var mapZoomRadius: MapZoomRadius?
    var storeDisplayDropDownIsOpen: Bool = false
    
    @IBOutlet weak var loginCell: UILabel!
    @IBOutlet weak var signedInAs: UILabel!
    @IBOutlet weak var dropMenuButton: DropMenuButton!
    @IBOutlet weak var sortSegControl: UISegmentedControl!
    @IBOutlet weak var storeDisplayAreaCell: UITableViewCell!
    
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
        
        let zoomRadiusSelections = ["5 miles", "10 miles", "15 miles", "20 miles"]
        let index: Int
        if mapZoomRadius == MapZoomRadius.five {
            index = 0
        } else if mapZoomRadius == MapZoomRadius.ten {
            index = 1
        } else if mapZoomRadius == MapZoomRadius.fifteen {
            index = 2
        } else if mapZoomRadius == MapZoomRadius.twenty {
            index = 3
        } else {
            index = 2 // default in case of problem
        }
        dropMenuButton.initTitle(to: zoomRadiusSelections[index])
        dropMenuButton.initMenu(zoomRadiusSelections,
            actions: [({ [weak self] () -> (Void) in
                        guard let strongSelf = self else { return }
                        strongSelf.userSelectedMapZoom(radius: .five)
                }),
                      ({ [weak self] () -> (Void) in
                        guard let strongSelf = self else { return }
                        strongSelf.userSelectedMapZoom(radius: .ten)
                }),
                      ({ [weak self] () -> (Void) in
                        guard let strongSelf = self else { return }
                        strongSelf.userSelectedMapZoom(radius: .fifteen)
                }),
                      ({ [weak self] () -> (Void) in
                        guard let strongSelf = self else { return }
                        strongSelf.userSelectedMapZoom(radius: .twenty)
                }),
        ])
        
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       
        let row = indexPath.row
        let section: Section = MenuTableViewController.Section(rawValue: indexPath.section)!
        
        switch section {
        case .searchSettings:
            if row == 0 {
                return 88.0
            } else {
                if storeDisplayDropDownIsOpen == true {
                    return 200.0
                } else {
                    return 88.0
                }
            }
        case .favorites:
            if row == 0 {
                return 44.0
            } else {
                return 88.0
            }
        case .login:
            return 44.0
        }
    }
    
    @IBAction func storeDisplayAreaButtonPressed(_ sender: Any) {
        storeDisplayDropDownIsOpen = !storeDisplayDropDownIsOpen
        tableView.beginUpdates()
        tableView.endUpdates()
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
    
    func userSelectedMapZoom(radius: MapZoomRadius) {
        storeDisplayDropDownIsOpen = false
        tableView.beginUpdates()
        tableView.endUpdates()
        self.menuViewDelegate?.userSelectedMapZoomRadius(radius: radius)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
