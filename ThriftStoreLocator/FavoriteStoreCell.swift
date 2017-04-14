//
//  FavoriteStoreCell.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 4/12/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit

protocol FavoriteButtonPressedDelegate: class {
    
    func favoriteButtonPressed(forStore index: Int, isFav: Bool, isCallFromFavoritesVC: Bool)
}

class FavoriteStoreCell: UITableViewCell {
    
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var favButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
