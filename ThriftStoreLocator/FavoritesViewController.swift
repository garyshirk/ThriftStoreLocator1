//
//  FavoritesViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 4/11/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import CoreLocation

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FavoriteButtonPressedDelegate {
    
    weak var delegate: FavoriteButtonPressedDelegate?
    
    var isFav: Bool!
    var favoriteStores: [Store]!
    var userLocation: CLLocationCoordinate2D!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noFavoritesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.navigationItem.title = "Favorites"
        let navBarDefaultBlueTextColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.DEFAULT_BLUE_COLOR))
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : navBarDefaultBlueTextColor]
        
        self.noFavoritesLabel.isHidden = (favoriteStores.count > 0)
        
        // Do not show empty tableView cells
        tableView.tableFooterView = UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteStores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "favoriteStoreCell") as! FavoriteStoreCell
        
        var store: Store!
        
        store = favoriteStores[indexPath.row]
        
        cell.storeName.text = store.name
        if let address = store.address, let city = store.city {
            cell.address.text = "\(address), \(city)"
        }
        cell.distance.text = ("\(distanceFromMyLocation(toLat: store.locLat!, long: store.locLong!)) away")
        
        cell.favButton.tag = indexPath.row
        
        cell.favButton.addTarget(self, action: #selector(favButtonPressed), for: .touchUpInside)
        
        if store.isFavorite == true {
            cell.favButton.setBackgroundImage(UIImage(named: "fav_on"), for: .normal)
        } else {
            cell.favButton.setBackgroundImage(UIImage(named: "fav_off"), for: .normal)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "favListToStoreDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func favCellSelected(index: Int) {
        let store = favoriteStores[index]
        let isFav = !(store.isFavorite == 1)
        updateFavorite(forIndex: index, isFav: isFav)
    }
    
    func favButtonPressed(sender: Any) {
        let button = sender as! UIButton
        let store = favoriteStores[button.tag]
        let isFav = !(store.isFavorite == 1)
        updateFavorite(forIndex: button.tag, isFav: isFav)
    }
    
    func updateFavorite(forIndex index: Int, isFav: Bool) {
        self.delegate?.favoriteButtonPressed(forStore: index, isFav: isFav, isCallFromFavoritesVC: true)
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func distanceFromMyLocation(toLat: NSNumber, long: NSNumber) -> String {
        
        let toLatDouble = toLat.doubleValue
        let toLongDouble = long.doubleValue
        
        let myLoc = CLLocation(latitude: (userLocation.latitude), longitude: (userLocation.longitude))
        let storeLoc = CLLocation(latitude: toLatDouble, longitude: toLongDouble)
        var distance = myLoc.distance(from: storeLoc) * 0.000621371
        
        if distance < 0.1 {
            distance = distance * 5280.0
            return ("\(distance.roundTo(places: 1)) feet")
        } else if (distance >= 9) {
            return ("\(Int(distance)) miles")
        } else {
            return ("\(distance.roundTo(places: 1)) miles")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "favListToStoreDetail" {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let selectedFav = favoriteStores[indexPath.row]
                
                if let detailViewController = segue.destination as? DetailViewController {
                    detailViewController.delegate = self
                    detailViewController.selectedStoreIndex = indexPath.row
                    detailViewController.storeNameStr = selectedFav.name
                    detailViewController.isFav = selectedFav.isFavorite as! Bool!
                    detailViewController.streetStr = selectedFav.address
                    detailViewController.cityStr = selectedFav.city
                    detailViewController.stateStr = selectedFav.state
                    detailViewController.zipStr = selectedFav.zip
                    detailViewController.distanceStr = ("\(distanceFromMyLocation(toLat: selectedFav.locLat!, long: selectedFav.locLong!)) away")
                    let locLat = selectedFav.locLat as! Double
                    let locLong = selectedFav.locLong as! Double
                    detailViewController.storeLocation = (locLat, locLong)
                }
            }
            
        }
    }
    
    // MARK - FavoriteButtonPressedDelegate
    
    func favoriteButtonPressed(forStore index: Int, isFav: Bool, isCallFromFavoritesVC: Bool) {
        favCellSelected(index: index)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
