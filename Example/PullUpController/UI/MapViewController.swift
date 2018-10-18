//
//  MapViewController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit
import MapKit
import PullUpController

class MapViewController: UIViewController, PullUpControllerContainer {
    
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var sizeSliderView: UIView! {
        didSet {
            sizeSliderView.layer.cornerRadius = 10
        }
    }
    @IBOutlet private weak var widthSlider: UISlider!
    @IBOutlet private weak var heightSlider: UISlider!
    @IBOutlet private weak var initialStateSegmentedControl: UISegmentedControl!
    private var pullUpControllerManager: PullUpManager?
    
    private func makeSearchViewControllerIfNeeded() -> SearchViewController {
        let currentPullUpController = childViewControllers
            .filter({ $0 is SearchViewController })
            .first as? SearchViewController
        let pullUpController: SearchViewController = currentPullUpController ?? UIStoryboard(name: "Main",bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        if initialStateSegmentedControl.selectedSegmentIndex == 0 {
            pullUpController.initialState = .contracted
        } else {
            pullUpController.initialState = .expanded
        }
        return pullUpController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let searchController = addPullUpController()
        
        widthSlider.maximumValue = Float(min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
        widthSlider.value = widthSlider.maximumValue
        heightSlider.maximumValue = Float(searchController.portraitHeight)
        heightSlider.value = heightSlider.maximumValue
    }
    
    @discardableResult
    private func addPullUpController() -> SearchViewController {
        let pullUpController = makeSearchViewControllerIfNeeded()
        pullUpController.loadViewIfNeeded()
        
        let pullUpControllerConfiguration = PullUpControllerConfiguration()
            .initialStickyPointOffset(pullUpController.initialPointOffset)
            .pullUpControllerMiddleStickyPoints(pullUpController.pullUpControllerMiddleStickyPoints)
            .willMoveToStickyPoint { (point) in
                print("willMoveToStickyPoint \(point)")
            }
            .didMoveToStickyPoint { (point) in
                print("didMoveToStickyPoint \(point)")
            }
            .onDrag { (point) in
                print("onDrag: \(point)")
        }
        
        pullUpControllerManager = addPullUpController(pullUpController,
                                                      attaching: pullUpController.tableView,
                                                      configuration: pullUpControllerConfiguration,
                                                      animated: true)
        
        return pullUpController
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
        guard let pullUpControllerManager = pullUpControllerManager else {
            return
        }
        let width = CGFloat(sender.value)
        
        pullUpControllerManager.pullUpControllerUpdateWidth(width)
    }
    
    @IBAction private func heightSliderValueChanged(_ sender: UISlider) {
        guard let pullUpControllerManager = pullUpControllerManager else {
            return
        }
        let height = CGFloat(sender.value)
        
        pullUpControllerManager.pullUpControllerUpdateHeight(height)
    }
    
}

