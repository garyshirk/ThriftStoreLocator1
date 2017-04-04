//
//  DrawerTableViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit

protocol MenuViewDelegate {
    
    func userSelectedMenuLoginCell()
}

class MenuTableViewController: UITableViewController {
    
    var menuViewDelegate: MenuViewDelegate?
    
    var isLoggedIn: Bool?
    
    @IBOutlet weak var loginCell: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isLoggedIn! {
            loginCell.text = "Sign Out"
        } else {
            loginCell.text = "Sign In"
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
    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return "Menu"
//    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.DEFAULT_BLUE_COLOR))
        header.textLabel?.font = UIFont(name: "Helvetica Neue", size: 18)
        header.textLabel?.text = "MENU"
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    

    enum MenuRow: Int {
        case login = 0
        case settings
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case MenuRow.login.rawValue:
            self.menuViewDelegate?.userSelectedMenuLoginCell()
            break
        default: break
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
