//
//  SearchViewController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit
import MapKit
import PullUpController

class SearchViewController: PullUpController {
    
    enum InitialState {
        case contracted
        case expanded
    }
    
    var initialState: InitialState = .contracted
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    @IBOutlet private weak var searchBoxContainerView: UIView!
    @IBOutlet private weak var searchSeparatorView: UIView! {
        didSet {
            searchSeparatorView.layer.cornerRadius = searchSeparatorView.frame.height/2
        }
    }
    @IBOutlet private weak var firstPreviewView: UIView!
    @IBOutlet private weak var secondPreviewView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    
    var initialPointOffset: CGFloat {
        switch initialState {
        case .contracted:
            return searchBoxContainerView?.frame.height ?? 0
        case .expanded:
            return pullUpControllerPreferredSize.height
        }
    }

    private var locations = [(title: String, location: CLLocationCoordinate2D)]()
    
    public var portraitSize: CGSize = .zero
    public var landscapeFrame: CGRect = .zero
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        portraitSize = CGSize(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height),
                              height: secondPreviewView.frame.maxY)
        landscapeFrame = CGRect(x: 5, y: 50, width: 280, height: 300)
        
        tableView.attach(to: self)
        setupDataSource()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.layer.cornerRadius = 12
    }
    
    override func pullUpControllerWillMove(to stickyPoint: CGFloat) {
//        print("will move to \(stickyPoint)")
    }
    
    override func pullUpControllerDidMove(to stickyPoint: CGFloat) {
//        print("did move to \(stickyPoint)")
    }
    
    override func pullUpControllerDidDrag(to point: CGFloat) {
//        print("did drag to \(point)")
    }
    
    private func setupDataSource() {
        locations.append(("Rome", CLLocationCoordinate2D(latitude: 41.9004041, longitude: 12.4432921)))
        locations.append(("Milan", CLLocationCoordinate2D(latitude: 45.4625319, longitude: 9.1574741)))
        locations.append(("Turin", CLLocationCoordinate2D(latitude: 45.0705805, longitude: 7.6593106)))
        locations.append(("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)))
        locations.append(("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)))
        locations.append(("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)))
        locations.append(("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)))
        locations.append(("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)))
        locations.append(("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)))
        locations.append(("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)))
        locations.append(("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)))
        locations.append(("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)))
        locations.append(("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)))
        locations.append(("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)))
        locations.append(("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)))
        locations.append(("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)))
        locations.append(("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)))
        locations.append(("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)))
    }
    
    // MARK: - PullUpController
    
    override var pullUpControllerPreferredSize: CGSize {
        return portraitSize
    }
    
    override var pullUpControllerPreferredLandscapeFrame: CGRect {
        return landscapeFrame
    }
    
    override var pullUpControllerMiddleStickyPoints: [CGFloat] {
        switch initialState {
        case .contracted:
            return [firstPreviewView.frame.maxY]
        case .expanded:
            return [searchBoxContainerView.frame.maxY, firstPreviewView.frame.maxY]
        }
    }
    
    override var pullUpControllerBounceOffset: CGFloat {
        return 20
    }
    
    override func pullUpControllerAnimate(action: PullUpController.Action,
                                          withDuration duration: TimeInterval,
                                          animations: @escaping () -> Void,
                                          completion: ((Bool) -> Void)?) {
        switch action {
        case .move:
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0,
                           options: .curveEaseInOut,
                           animations: animations,
                           completion: completion)
        default:
            UIView.animate(withDuration: 0.3,
                           animations: animations,
                           completion: completion)
        }
    }
    
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let lastStickyPoint = pullUpControllerAllStickyPoints.last {
            pullUpControllerMoveToVisiblePoint(lastStickyPoint, animated: true, completion: nil)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell",
                                                     for: indexPath) as? SearchResultCell
            else { return UITableViewCell() }
        
        cell.configure(title: locations[indexPath.row].title)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        view.endEditing(true)
        pullUpControllerMoveToVisiblePoint(pullUpControllerMiddleStickyPoints[0], animated: true, completion: nil)
        
        (parent as? MapViewController)?.zoom(to: locations[indexPath.row].location)
    }
}
