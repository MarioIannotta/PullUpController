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
    @IBOutlet private weak var initialStateSegmentedControl: UISegmentedControl!
    
    private var originalPullUpControllerViewSize: CGSize = .zero
    
    private func makeSearchViewControllerIfNeeded() -> SearchViewController {
        let currentPullUpController = children
            .filter({ $0 is SearchViewController })
            .first as? SearchViewController
        let pullUpController: SearchViewController = currentPullUpController ?? UIStoryboard(name: "Main",bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        if initialStateSegmentedControl.selectedSegmentIndex == 0 {
            pullUpController.initialState = .contracted
        } else {
            pullUpController.initialState = .expanded
        }
        if originalPullUpControllerViewSize == .zero {
            originalPullUpControllerViewSize = pullUpController.view.bounds.size
        }
        return pullUpController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPullUpController()
    }
    
    private func addPullUpController() {
        let pullUpController = makeSearchViewControllerIfNeeded()
        _ = pullUpController.view // call pullUpController.viewDidLoad()
        addPullUpController(pullUpController,
                            initialStickyPointOffset: pullUpController.initialPointOffset,
                            animated: true)
    }
    
    func zoom(to location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    @IBAction private func addButtonTapped() {
        guard
            children.filter({ $0 is SearchViewController }).count == 0
            else { return }
        addPullUpController()
    }
    
    @IBAction private func removeButtonTapped() {
        let pullUpController = makeSearchViewControllerIfNeeded()
        removePullUpController(pullUpController, animated: true)
    }
    
    @IBAction private func widthSliderValueChanged(_ sender: UISlider) {
        let pullUpController = makeSearchViewControllerIfNeeded()
        let width = originalPullUpControllerViewSize.width * CGFloat(sender.value)
        pullUpController.portraitSize = CGSize(width: width,
                                               height: pullUpController.portraitSize.height)
        pullUpController.landscapeFrame = CGRect(origin: pullUpController.landscapeFrame.origin,
                                                 size: CGSize(width: width,
                                                              height: pullUpController.landscapeFrame.height))
        pullUpController.updatePreferredFrameIfNeeded(animated: true)
    }
    
}

