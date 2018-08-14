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
    @IBOutlet private weak var sizeSliderView: UIView! {
        didSet {
            sizeSliderView.layer.cornerRadius = 10
        }
    }
    @IBOutlet private weak var widthSlider: UISlider!
    @IBOutlet private weak var heightSlider: UISlider!
    
    private func makeSearchViewControllerIfNeeded() -> SearchViewController {
        let currentPullUpController = childViewControllers
            .filter({ $0 is SearchViewController })
            .first as? SearchViewController
        if let currentPullUpController = currentPullUpController {
            return currentPullUpController
        } else {
            return UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPullUpController()
        
        let pullUpController = makeSearchViewControllerIfNeeded()
        widthSlider.maximumValue = Float(pullUpController.portraitSize.width)
        widthSlider.value = widthSlider.maximumValue
        heightSlider.maximumValue = Float(pullUpController.portraitSize.height)
        heightSlider.value = heightSlider.maximumValue
    }
    
    private func addPullUpController() {
        let pullUpController = makeSearchViewControllerIfNeeded()
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
        let pullUpController = makeSearchViewControllerIfNeeded()
        removePullUpController(pullUpController, animated: true)
    }
    
    @IBAction private func widthSliderValueChanged(_ sender: UISlider) {
        let width = CGFloat(sender.value)
        let pullUpController = makeSearchViewControllerIfNeeded()
        pullUpController.portraitSize = CGSize(width: width,
                                               height: pullUpController.portraitSize.height)
        pullUpController.landscapeFrame = CGRect(origin: pullUpController.landscapeFrame.origin,
                                                 size: CGSize(width: width,
                                                              height: pullUpController.landscapeFrame.height))
        pullUpController.updatePreferredFrameIfNeeded(animated: true)
    }
    
    @IBAction private func heightSliderValueChanged(_ sender: UISlider) {
        let height = CGFloat(sender.value)
        let pullUpController = makeSearchViewControllerIfNeeded()
        pullUpController.portraitSize = CGSize(width: pullUpController.portraitSize.width,
                                               height: height)
        pullUpController.landscapeFrame = CGRect(origin: pullUpController.landscapeFrame.origin,
                                                 size: CGSize(width: pullUpController.landscapeFrame.width,
                                                              height: height))
        pullUpController.updatePreferredFrameIfNeeded(animated: true)
        
    }
    
}

