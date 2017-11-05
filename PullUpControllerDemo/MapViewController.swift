//
//  MapViewController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPullUpController()
    }
    
    private func addPullUpController() {
        guard
            let pullUpController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController
            else { return }
        
        addPullUpController(pullUpController)
    }
    
    func zoom(to location: CLLocationCoordinate2D) {
        let latDelta: CLLocationDegrees = 0.05
        let lonDelta: CLLocationDegrees = 0.05
        let span = MKCoordinateSpanMake(latDelta, lonDelta)
        let location = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        let region = MKCoordinateRegionMake(location, span)
        
        mapView.setRegion(region, animated: true)
    }

}

