//
//  DrawerTableViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit

protocol MenuViewDelegate: class {
    
    func userSelectedMenuLoginCell()
    
    func userSelectedManageFavorites()
}

class MenuTableViewController: UITableViewController {
    
    weak var menuViewDelegate: MenuViewDelegate?
    
    var isLoggedIn: Bool?
    var isRegistered: Bool?
    var username: String?
    
    @IBOutlet weak var loginCell: UILabel!
    @IBOutlet weak var signedInAs: UILabel!
    
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
            headerText = "Favorites"
        case 1:
            headerText = "Search Settings"
        case 2:
            headerText = "Logged In As"
        default:
            break
        }

        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.frame = header.frame
        header.textLabel?.text = headerText
    }
    

    enum Section: Int {
        case favorites
        case searchSettings
        case login
    }
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        let section: Section = MenuTableViewController.Section(rawValue: indexPath.section)!
        
        switch section {
            case .favorites:
                if row == 0 {
                    dismiss(animated: true, completion: nil)
                    self.menuViewDelegate?.userSelectedManageFavorites()
                } else {
                    
                }
            case .searchSettings:
                if row == 0 {
                    
                } else {
                    
            }
            case .login:
                if row == 0 {
                    
                } else {
                    self.menuViewDelegate?.userSelectedMenuLoginCell()
                }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
