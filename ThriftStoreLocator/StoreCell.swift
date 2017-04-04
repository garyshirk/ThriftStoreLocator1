//
//  StoreCell.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 3/14/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit

class StoreCell: UITableViewCell {
    
    
    @IBOutlet weak var storeLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var locationButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
