//
//  DetailViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController {
    
    weak var delegate: FavoriteButtonPressedDelegate?
    
    var selectedStoreIndex: Int!
    var storeNameStr: String!
    var distanceStr: String!
    var isFav: Bool!
    var streetStr: String!
    var cityStr: String!
    var stateStr: String!
    var zipStr: String!
    var storeLocation: (lat: Double, long: Double)?

    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var zipLabel: UILabel!
    @IBOutlet weak var favButton: UIButton!
    
    
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
        
        var favImg: UIImage?
        if isFav == true {
            favImg = UIImage(named: "fav_on")!
        } else {
            favImg = UIImage(named: "fav_off")
        }
        favButton.setBackgroundImage(favImg, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func getDirectionsButton(_ sender: Any) {
        openMapForPlace()
    }
    
    
    @IBAction func favButtonPressed(_ sender: Any) {
        if isFav == true {
            isFav = false
            favButton.setBackgroundImage(UIImage(named: "fav_off"), for: .normal)
        } else {
            isFav = true
            favButton.setBackgroundImage(UIImage(named: "fav_on"), for: .normal)
        }
        self.delegate?.favoriteButtonPressed(forStore: selectedStoreIndex, isFav: isFav, isCallFromFavoritesVC: false)
    }
  
    func openMapForPlace() {
        
        let latitude: CLLocationDegrees = storeLocation!.lat
        let longitude: CLLocationDegrees = storeLocation!.long
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = streetLabel.text
        
        print(mapItem.name ?? "No name")
        
        mapItem.openInMaps(launchOptions: options)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
