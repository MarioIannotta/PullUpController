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
        
        addPullUpController(pullUpController, animated: true)
    }
    
    func zoom(to location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegionMake(location, span)
        
        mapView.setRegion(region, animated: true)
    }
    
    @IBAction private func addButtonTapped() {
        guard
            childViewControllers.filter({ $0 is SearchViewController }).count == 0
            else { return }
        addPullUpController()
    }
    
    @IBAction private func removeButtonTapped() {
        guard
            let pullUpController = childViewControllers.filter({ $0 is SearchViewController }).first as? SearchViewController
            else { return }
        removePullUpController(pullUpController, animated: true)
    }
    
}

