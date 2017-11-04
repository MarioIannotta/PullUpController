//
//  SliderController.swift
//  SliderControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

open class SliderController: UIViewController {
    
    private var leftConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    open var sc_previewOffset: CGFloat {
        return 50
    }
    open var sc_preferredSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 400)
    }
    open var sc_stickyPoints: [CGFloat] {
        return []
    }
    open var sc_isBouncingEnabled: Bool {
        return false
    }
    open var sc_preferredLandscapeFrame: CGRect {
        return CGRect(x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20)
    }
    
    open func sc_scrollToVisiblePoint(_ visiblePoint: CGFloat, completion: (() -> Void)?) {
        guard
            UIScreen.main.bounds.height > UIScreen.main.bounds.width // disable the scroll in landscape
            else { return }
        topConstraint?.constant = (parent?.view.frame.height ?? 0) - visiblePoint
        
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.parent?.view?.layoutIfNeeded()
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    open func sc_attach(to scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleInternalScrollViewPanGestureRecognizer(_:)))
    }
    
    private var sc_allStickyPoints: [CGFloat] {
        var sc_allStickyPoints = [sc_previewOffset]
        sc_allStickyPoints.append(contentsOf: sc_stickyPoints)
        return sc_allStickyPoints.sorted()
    }
    
    fileprivate func setupPanGestureRecognizer() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer?.minimumNumberOfTouches = 1
        panGestureRecognizer?.maximumNumberOfTouches = 1
        if let panGestureRecognizer = panGestureRecognizer {
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    fileprivate func setupConstrains() {
        guard let parentView = parent?.view else { return }
        
        topConstraint = view.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 0)
        leftConstraint = view.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 0)
        widthConstraint = view.widthAnchor.constraint(equalToConstant: sc_preferredSize.width)
        heightConstraint = view.heightAnchor.constraint(equalToConstant: sc_preferredSize.height)
        
        NSLayoutConstraint.activate([topConstraint, leftConstraint, widthConstraint, heightConstraint].flatMap { $0 })
    }
    
    private var currentStickyPointIndex: Int {
        let stickyPointTreshold = (self.parent?.view.frame.height ?? 0) - (topConstraint?.constant ?? 0)
        let stickyPointsLessCurrentPosition = sc_allStickyPoints.map { abs($0 - stickyPointTreshold) }
        guard let minStickyPointDifference = stickyPointsLessCurrentPosition.min() else { return 0 }
        return stickyPointsLessCurrentPosition.index(of: minStickyPointDifference) ?? 0
    }
    
    private func nearestStickyPointY(yVelocity: CGFloat) -> CGFloat {
        var currentStickyPointIndex = self.currentStickyPointIndex
        if abs(yVelocity) > 700 { // 1000 points/sec = "fast" scroll
            if yVelocity > 0 {
                currentStickyPointIndex = max(currentStickyPointIndex - 1, 0)
            } else {
                currentStickyPointIndex = min(currentStickyPointIndex + 1, sc_allStickyPoints.count - 1)
            }
        }
        
        return (parent?.view.frame.height ?? 0) - sc_allStickyPoints[currentStickyPointIndex]
    }
    
    @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            UIScreen.main.bounds.height > UIScreen.main.bounds.width, // disable the gesture in landscape
            let topConstraint = topConstraint,
            let parentViewHeight = parent?.view.frame.height
            else { return }
        
        let yTranslation = gestureRecognizer.translation(in: view).y
        gestureRecognizer.setTranslation(.zero, in: view)
        
        topConstraint.constant += yTranslation
        
        if !sc_isBouncingEnabled {
            topConstraint.constant = max(topConstraint.constant, parentViewHeight - sc_preferredSize.height)
            topConstraint.constant = min(topConstraint.constant, parentViewHeight - sc_previewOffset)
        }
        
        if gestureRecognizer.state == .ended {
            topConstraint.constant = nearestStickyPointY(yVelocity: gestureRecognizer.velocity(in: view).y)
            UIView.animate(
                withDuration: 0.3,
                animations: { [weak self] in
                    self?.parent?.view.layoutIfNeeded()
                }
            )
        }
    }
    
    @objc private func handleInternalScrollViewPanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            UIScreen.main.bounds.height > UIScreen.main.bounds.width, // disable the gesture in landscape
            let scrollView = gestureRecognizer.view as? UIScrollView,
            let lastStickyPoint = sc_allStickyPoints.last,
            let parentViewHeight = parent?.view.frame.height,
            let topConstraintValue = topConstraint?.constant
            else { return }
        
        if
            (scrollView.contentOffset.y <= 0 && gestureRecognizer.translation(in: view).y > 0) // scrolling down
            || (topConstraintValue != parentViewHeight - lastStickyPoint && gestureRecognizer.velocity(in: view).y < 0) // scrolling up
        {
            handlePanGestureRecognizer(gestureRecognizer)
        }
        
        if gestureRecognizer.state.rawValue == 3 {
            topConstraint?.constant = nearestStickyPointY(yVelocity: 0)
            UIView.animate(
                withDuration: 0.3,
                animations: { [weak self] in
                    self?.parent?.view.layoutIfNeeded()
                }
            )
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] coordinator in
            self?.refreshConstraints(size: size)
        })
        // TODO: restore old portrait constraint when the device is again in portrait
    }
    
    private func setPortraitConstraints(parentViewSize: CGSize) {
        topConstraint?.constant = parentViewSize.height - sc_previewOffset
        leftConstraint?.constant = (parentViewSize.width - min(sc_preferredSize.width, parentViewSize.width))/2
        widthConstraint?.constant = sc_preferredSize.width
        heightConstraint?.constant = sc_preferredSize.height
    }
    
    private func setLandscapeConstraints() {
        topConstraint?.constant = sc_preferredLandscapeFrame.origin.y
        leftConstraint?.constant = sc_preferredLandscapeFrame.origin.x
        widthConstraint?.constant = sc_preferredLandscapeFrame.width
        heightConstraint?.constant = sc_preferredLandscapeFrame.height
    }
    
    fileprivate func refreshConstraints(size: CGSize) {
        if size.width > size.height {
            setLandscapeConstraints()
        } else {
            setPortraitConstraints(parentViewSize: size)
        }
    }
}

extension UIViewController {
    
    open func addSliderController(_ sliderController: SliderController) {
        addChildViewController(sliderController)
        
        sliderController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderController.view)
        
        sliderController.setupPanGestureRecognizer()
        sliderController.setupConstrains()
        sliderController.refreshConstraints(size: view.frame.size)
    }
}
