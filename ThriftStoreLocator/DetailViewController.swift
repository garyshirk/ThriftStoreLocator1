//
//  DetailViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    var storeNameStr: String!
    var distanceStr: String!
    var isFav: Bool!
    var streetStr: String!
    var cityStr: String!
    var stateStr: String!
    var zipStr: String!

    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var favImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var zipLabel: UILabel!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        storeName.text = storeNameStr
        distanceLabel.text = distanceStr
        streetLabel.text = streetStr
        
        if let unwrappedCityStr = cityStr {
            cityLabel.text = ("\(unwrappedCityStr),")
        }

        stateLabel.text = stateStr
        zipLabel.text = zipStr
        
        let heartImg: UIImage = (isFav == true ? UIImage(named: "fav_on") : UIImage(named: "fav_off"))!
        favImageView.image = heartImg
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
  
    
    
    
    
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    
    }

}
