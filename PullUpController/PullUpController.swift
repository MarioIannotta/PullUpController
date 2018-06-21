//
//  PullUpController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

open class PullUpController: UIViewController {
    
    // MARK: - Open properties
    
    /**
     The closure to execute before the view controller's view move to a sticky point.
     The target sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    open var willMoveToStickyPoint: ((_ point: CGFloat) -> Void)?
    
    /**
     The closure to execute after the view controller's view move to a sticky point.
     The sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    open var didMoveToStickyPoint: ((_ point: CGFloat) -> Void)?
    
    /**
     The closure to execute when the view controller's view is dragged.
     The point, expressed in the pull up controller parent coordinate system, is provided in the closure parameter.
     */
    open var onDrag: ((_ point: CGFloat) -> Void)?
    
    /**
     The desired height in screen units expressed in the pull up controller coordinate system that will be initially showed.
     The default value is 50.
     */
    open var pullUpControllerPreviewOffset: CGFloat {
        return 50
    }
    
    /**
     The desired size of the pull up controller’s view, in screen units.
     The default value is width: UIScreen.main.bounds.width, height: 400.
     */
    open var pullUpControllerPreferredSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 400)
    }
    
    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gestures the pull up controller will scroll to the nearest point in the list.
     
     Please keep in mind that this array should contains only sticky points in the middle of the pull up controller's view;
     There is therefore no need to add the fist one (pullUpControllerPreviewOffset), and/or the last one (pullUpControllerPreferredSize.height).
     
     For a complete list of all the sticky points you can use `pullUpControllerAllStickyPoints`.
     */
    open var pullUpControllerMiddleStickyPoints: [CGFloat] {
        return []
    }
    
    /**
     A Boolean value that determines whether bouncing occurs when scrolling reaches the end of the pull up controller's view size.
     The default value is false.
     */
    open var pullUpControllerIsBouncingEnabled: Bool {
        return false
    }
    
    /**
     The desired size of the pull up controller’s view, in screen units when the device is in landscape mode.
     The default value is (x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20).
     */
    open var pullUpControllerPreferredLandscapeFrame: CGRect {
        return CGRect(x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20)
    }
    
    // MARK: - Public properties
    
    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gesture the pull up controller will scroll at the nearest point in the list.
     */
    public final var pullUpControllerAllStickyPoints: [CGFloat] {
        var sc_allStickyPoints = [pullUpControllerPreviewOffset, pullUpControllerPreferredSize.height]
        sc_allStickyPoints.append(contentsOf: pullUpControllerMiddleStickyPoints)
        return sc_allStickyPoints.sorted()
    }
    
    private var leftConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    private var isPortrait: Bool {
        return UIScreen.main.bounds.height > UIScreen.main.bounds.width
    }
    
    private var portraitPreviousStickyPointIndex: Int?
    
    // MARK: - Open methods
    
    /**
     This method will move the pull up controller's view in order to show the provided visible point.
     
     You may use on of `pullUpControllerAllStickyPoints` item to provide a valid visible point.
     - parameter visiblePoint: the y value to make visible, in screen units expressed in the pull up controller coordinate system.
     - parameter completion: The closure to execute after the animation is completed. This block has no return value and takes no parameters. You may specify nil for this parameter.
     */
    open func pullUpControllerMoveToVisiblePoint(_ visiblePoint: CGFloat, completion: (() -> Void)?) {
        guard isPortrait else { return }
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
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let isPortrait = size.height > size.width
        var targetStickyPoint: CGFloat?
        
        if !isPortrait {
            portraitPreviousStickyPointIndex = currentStickyPointIndex
        } else if
            let portraitPreviousStickyPointIndex = portraitPreviousStickyPointIndex,
            portraitPreviousStickyPointIndex < pullUpControllerAllStickyPoints.count
        {
            targetStickyPoint = pullUpControllerAllStickyPoints[portraitPreviousStickyPointIndex]
            self.portraitPreviousStickyPointIndex = nil
        }
        
        coordinator.animate(alongsideTransition: { [weak self] coordinator in
            self?.refreshConstraints(size: size)
            if let targetStickyPoint = targetStickyPoint {
                self?.pullUpControllerMoveToVisiblePoint(targetStickyPoint, completion: nil)
            }
        })
    }
    
    // MARK: - Setup
    
    fileprivate func setupPanGestureRecognizer() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer?.minimumNumberOfTouches = 1
        panGestureRecognizer?.maximumNumberOfTouches = 1
        if let panGestureRecognizer = panGestureRecognizer {
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    fileprivate func setupConstraints() {
        guard let parentView = parent?.view else { return }
        
        topConstraint = view.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 0)
        leftConstraint = view.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 0)
        widthConstraint = view.widthAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.width)
        heightConstraint = view.heightAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.height)
        
        NSLayoutConstraint.activate([topConstraint, leftConstraint, widthConstraint, heightConstraint].compactMap { $0 })
    }
    
    private var currentStickyPointIndex: Int {
        let stickyPointTreshold = (self.parent?.view.frame.height ?? 0) - (topConstraint?.constant ?? 0)
        let stickyPointsLessCurrentPosition = pullUpControllerAllStickyPoints.map { abs($0 - stickyPointTreshold) }
        guard let minStickyPointDifference = stickyPointsLessCurrentPosition.min() else { return 0 }
        return stickyPointsLessCurrentPosition.index(of: minStickyPointDifference) ?? 0
    }
    
    private func nearestStickyPointY(yVelocity: CGFloat) -> CGFloat {
        var currentStickyPointIndex = self.currentStickyPointIndex
        if abs(yVelocity) > 700 { // 1000 points/sec = "fast" scroll
            if yVelocity > 0 {
                currentStickyPointIndex = max(currentStickyPointIndex - 1, 0)
            } else {
                currentStickyPointIndex = min(currentStickyPointIndex + 1, pullUpControllerAllStickyPoints.count - 1)
            }
        }
        
        willMoveToStickyPoint?(pullUpControllerAllStickyPoints[currentStickyPointIndex])
        return (parent?.view.frame.height ?? 0) - pullUpControllerAllStickyPoints[currentStickyPointIndex]
    }
    
    @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            isPortrait,
            let topConstraint = topConstraint,
            let parentViewHeight = parent?.view.frame.height
            else { return }
        
        let yTranslation = gestureRecognizer.translation(in: view).y
        gestureRecognizer.setTranslation(.zero, in: view)
        
        topConstraint.constant += yTranslation
        
        if !pullUpControllerIsBouncingEnabled {
            topConstraint.constant = max(topConstraint.constant, parentViewHeight - pullUpControllerPreferredSize.height)
            topConstraint.constant = min(topConstraint.constant, parentViewHeight - pullUpControllerPreviewOffset)
        }
        
        onDrag?(topConstraint.constant)
        
        if gestureRecognizer.state == .ended {
            let yVelocity = gestureRecognizer.velocity(in: view).y // v = px/s
            let oldTopConstraintConstant = topConstraint.constant
            topConstraint.constant = nearestStickyPointY(yVelocity: yVelocity)
            let distanceToConver = oldTopConstraintConstant - topConstraint.constant // px
            let animationDuration = TimeInterval(abs(distanceToConver/yVelocity)) // s = px/v
            animateLayout(animationDuration: animationDuration)
        }
    }
    
    @objc fileprivate func handleInternalScrollViewPanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            isPortrait,
            let scrollView = gestureRecognizer.view as? UIScrollView,
            let lastStickyPoint = pullUpControllerAllStickyPoints.last,
            let parentViewHeight = parent?.view.frame.height,
            let topConstraintValue = topConstraint?.constant
            else { return }
        
        let isScrollingDown = gestureRecognizer.translation(in: view).y > 0
        let shouldScrollingDownTriggerGestureRecognizer = isScrollingDown && scrollView.contentOffset.y <= 0
        let shouldScrollingUpTriggerGestureRecognizer = !isScrollingDown && topConstraintValue != parentViewHeight - lastStickyPoint
        
        if shouldScrollingDownTriggerGestureRecognizer || shouldScrollingUpTriggerGestureRecognizer {
            handlePanGestureRecognizer(gestureRecognizer)
        }
        
        if gestureRecognizer.state.rawValue == 3 { // for some reason gestureRecognizer.state == .ended doesn't work
            topConstraint?.constant = nearestStickyPointY(yVelocity: 0)
            animateLayout()
        }
    }
    
    private func animateLayout(animationDuration: TimeInterval? = nil) {
        let defaultAnimationDuration = 0.3
        let animationDuration = max(0.08, min(defaultAnimationDuration, animationDuration ?? defaultAnimationDuration))
        
        UIView.animate(
            withDuration: animationDuration,
            animations: { [weak self] in
                self?.parent?.view.layoutIfNeeded()
                let point = (self?.parent?.view.frame.height ?? 0.0) - (self?.topConstraint?.constant ?? 0.0)
                self?.didMoveToStickyPoint?(point)
            }
        )
    }
    
    private func setPortraitConstraints(parentViewSize: CGSize) {
        topConstraint?.constant = parentViewSize.height - pullUpControllerPreviewOffset
        leftConstraint?.constant = (parentViewSize.width - min(pullUpControllerPreferredSize.width, parentViewSize.width))/2
        widthConstraint?.constant = pullUpControllerPreferredSize.width
        heightConstraint?.constant = pullUpControllerPreferredSize.height
    }
    
    private func setLandscapeConstraints() {
        topConstraint?.constant = pullUpControllerPreferredLandscapeFrame.origin.y
        leftConstraint?.constant = pullUpControllerPreferredLandscapeFrame.origin.x
        widthConstraint?.constant = pullUpControllerPreferredLandscapeFrame.width
        heightConstraint?.constant = pullUpControllerPreferredLandscapeFrame.height
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
    
    /**
     Adds the specified pull up view controller as a child of the current view controller.
     - parameter pullUpController: the pull up controller to add as a child of the current view controller.
     */
    open func addPullUpController(_ pullUpController: PullUpController) {
        addChildViewController(pullUpController)
        
        pullUpController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pullUpController.view)
        
        pullUpController.setupPanGestureRecognizer()
        pullUpController.setupConstraints()
        pullUpController.refreshConstraints(size: view.frame.size)
    }
    
}

extension UIScrollView {
    
    /**
     Attach the scroll view to the provided pull up controller in order to move it with the scroll view content.
     - parameter pullUpController: the pull up controller to move with the current scroll view content.
     */
    open func attach(to pullUpController: PullUpController) {
        panGestureRecognizer.addTarget(pullUpController, action: #selector(pullUpController.handleInternalScrollViewPanGestureRecognizer(_:)))
    }
    
}
