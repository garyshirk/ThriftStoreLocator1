//
//  StoreCellListView.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 4/21/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit

class StoreCellListView: UITableViewCell {
    
    
    @IBOutlet weak var storeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var favImgView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
