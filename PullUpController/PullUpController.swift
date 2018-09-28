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
     The desired size of the pull up controller’s view, in screen units.
     The default value is width: UIScreen.main.bounds.width, height: 400.
     */
    open var pullUpControllerPreferredSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 400)
    }
    
    /**
     The desired size of the pull up controller’s view, in screen units when the device is in landscape mode.
     The default value is (x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20).
     */
    open var pullUpControllerPreferredLandscapeFrame: CGRect {
        return CGRect(x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20)
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
    
    // MARK: - Public properties
    
    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gesture the pull up controller will scroll at the nearest point in the list.
     */
    public final var pullUpControllerAllStickyPoints: [CGFloat] {
        var sc_allStickyPoints = [initialStickyPointOffset, pullUpControllerPreferredSize.height].compactMap { $0 }
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
    
    fileprivate weak var internalScrollView: UIScrollView?
    
    private var initialInternalScrollViewContentOffset: CGPoint = .zero
    private var initialStickyPointOffset: CGFloat?
    
    // MARK: - Open methods
    
    /**
     This method will move the pull up controller's view in order to show the provided visible point.
     
     You may use on of `pullUpControllerAllStickyPoints` item to provide a valid visible point.
     - parameter visiblePoint: the y value to make visible, in screen units expressed in the pull up controller coordinate system.
     - parameter animated: Pass true to animate the move; otherwise, pass false.
     - parameter completion: The closure to execute after the animation is completed. This block has no return value and takes no parameters. You may specify nil for this parameter.
     */
    open func pullUpControllerMoveToVisiblePoint(_ visiblePoint: CGFloat, animated: Bool, completion: (() -> Void)?) {
        guard
            isPortrait
            else { return }
        topConstraint?.constant = (parent?.view.frame.height ?? 0) - visiblePoint
        
        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: { [weak self] in
                    self?.parent?.view?.layoutIfNeeded()
                },
                completion: { _ in
                    completion?()
                })
        } else {
            parent?.view?.layoutIfNeeded()
            completion?()
        }
    }
    
    /**
     This method update the pull up controller's view size according to `pullUpControllerPreferredSize` and `pullUpControllerPreferredLandscapeFrame`.
     If the device is in portrait, the pull up controller's view will be attached to the nearest sticky point after the resize.
     - parameter animated: Pass true to animate the resize; otherwise, pass false.
    */
    open func updatePreferredFrameIfNeeded(animated: Bool) {
        guard
            let parentView = parent?.view
            else { return }
        refreshConstraints(newSize: parentView.frame.size,
                           customTopOffset: parentView.frame.size.height - (pullUpControllerAllStickyPoints.first ?? 0))
        
        UIView.animate(withDuration: animated ? 0.3 : 0) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let isNewSizePortrait = size.height > size.width
        var targetStickyPoint: CGFloat?
        
        if !isNewSizePortrait {
            portraitPreviousStickyPointIndex = currentStickyPointIndex
        } else if
            let portraitPreviousStickyPointIndex = portraitPreviousStickyPointIndex,
            portraitPreviousStickyPointIndex < pullUpControllerAllStickyPoints.count
        {
            targetStickyPoint = pullUpControllerAllStickyPoints[portraitPreviousStickyPointIndex]
            self.portraitPreviousStickyPointIndex = nil
        }
        
        coordinator.animate(alongsideTransition: { [weak self] coordinator in
            self?.refreshConstraints(newSize: size)
            if let targetStickyPoint = targetStickyPoint {
                self?.pullUpControllerMoveToVisiblePoint(targetStickyPoint, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - Setup
    
    fileprivate func setup(superview: UIView, initialStickyPointOffset: CGFloat) {
        self.initialStickyPointOffset = initialStickyPointOffset
        view.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(view)
        view.frame = CGRect(origin: CGPoint(x: view.frame.origin.x,
                                            y: superview.bounds.height),
                            size: view.frame.size)
        
        setupPanGestureRecognizer()
        setupConstraints()
        refreshConstraints(newSize: superview.frame.size,
                           customTopOffset: superview.frame.height - initialStickyPointOffset)
    }
    
    private func setupPanGestureRecognizer() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer?.minimumNumberOfTouches = 1
        panGestureRecognizer?.maximumNumberOfTouches = 1
        panGestureRecognizer?.delegate = self
        if let panGestureRecognizer = panGestureRecognizer {
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    private func setupConstraints() {
        guard
            let parentView = parent?.view
            else { return }
        
        topConstraint = view.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 0)
        leftConstraint = view.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 0)
        widthConstraint = view.widthAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.width)
        heightConstraint = view.heightAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.height)
        
        NSLayoutConstraint.activate([topConstraint, leftConstraint, widthConstraint, heightConstraint].compactMap { $0 })
    }
    
    private func refreshConstraints(newSize: CGSize, customTopOffset: CGFloat? = nil) {
        if newSize.height > newSize.width {
            setPortraitConstraints(parentViewSize: newSize, customTopOffset: customTopOffset)
        } else {
            setLandscapeConstraints()
        }
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
            let lastStickyPoint = pullUpControllerAllStickyPoints.last,
            let parentView = parent?.view
            else { return }
        
        let parentViewHeight = parentView.frame.height
        var yTranslation = gestureRecognizer.translation(in: parentView).y
        gestureRecognizer.setTranslation(.zero, in: view)
        
        let scrollViewPanVelocity = internalScrollView?.panGestureRecognizer.velocity(in: parentView).y ?? 0
        let isScrollingDown = scrollViewPanVelocity > 0
        
        /**
         A Boolean value that controls whether the scroll view scroll should pan the parent view up **or** down.
         
         1. The user should be able to drag the view down through the internal scroll view when
            - the scroll direction is down (`isScrollingDown`)
            - the internal scroll view is scrolled to the top (`scrollView.contentOffset.y <= 0`)
         
         2. The user should be able to drag the view up through the internal scroll view when
            - the scroll direction is up (`!isScrollingDown`)
            - the PullUpController's view is fully opened. (`topConstraint.constant != parentViewHeight - lastStickyPoint`)
         */
        let shouldDragView: Bool = {
            // Condition 1
            let shouldDragViewDown = isScrollingDown && internalScrollView?.contentOffset.y ?? 0 <= 0
            // Condition 2
            let shouldDragViewUp = !isScrollingDown && topConstraint.constant != parentViewHeight - lastStickyPoint
            return shouldDragViewDown || shouldDragViewUp
        }()
        
        switch gestureRecognizer.state {
        case .began:
            initialInternalScrollViewContentOffset = internalScrollView?.contentOffset ?? .zero
            
        case .changed:
            // the user is scrolling the internal scroll view
            if scrollViewPanVelocity != 0, let scrollView = internalScrollView {
                // if the user shouldn't be able to drag the view up through the internal scroll view reset the translation
                guard
                    shouldDragView
                    else {
                        yTranslation = 0
                        return
                    }
                // disable the bounces when the user is able to drag the view through the internal scroll view
                scrollView.bounces = false
                if isScrollingDown {
                    // take the initial internal scroll view content offset into account when scrolling down
                    yTranslation -= initialInternalScrollViewContentOffset.y
                    initialInternalScrollViewContentOffset = .zero
                } else {
                    // keep the initial internal scroll view content offset when scrolling up
                    internalScrollView?.contentOffset = initialInternalScrollViewContentOffset
                }
            }
            setTopOffset(topConstraint.constant + yTranslation)
            
        case .ended:
            internalScrollView?.bounces = true
            guard
                shouldDragView
                else { return }
            let yVelocity = gestureRecognizer.velocity(in: view).y // v = px/s
            let targetTopOffset = nearestStickyPointY(yVelocity: yVelocity)
            let distanceToConver = topConstraint.constant - targetTopOffset // px
            let animationDuration = max(0.08, min(0.3, TimeInterval(abs(distanceToConver/yVelocity)))) // s = px/v
            setTopOffset(targetTopOffset, animationDuration: animationDuration)
            
        default:
            break
        }
    }
    
    private func setTopOffset(_ value: CGFloat, animationDuration: TimeInterval? = nil) {
        guard
            let parentViewHeight = parent?.view.frame.height
            else { return }
        var value = value
        if !pullUpControllerIsBouncingEnabled,
            let firstStickyPoint = pullUpControllerAllStickyPoints.first,
            let lastStickyPoint = pullUpControllerAllStickyPoints.last {
            value = max(value, parentViewHeight - lastStickyPoint)
            value = min(value, parentViewHeight - firstStickyPoint)
        }
        topConstraint?.constant = value
        onDrag?(value)
        
        UIView.animate(
            withDuration: animationDuration ?? 0,
            animations: { [weak self] in
                self?.parent?.view.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                let point = (self?.parent?.view.frame.height ?? 0.0) - (self?.topConstraint?.constant ?? 0.0)
                self?.didMoveToStickyPoint?(point)
            }
        )
    }
    
    private func setPortraitConstraints(parentViewSize: CGSize, customTopOffset: CGFloat? = nil) {
        if let customTopOffset = customTopOffset {
            topConstraint?.constant = customTopOffset
        } else {
            topConstraint?.constant = nearestStickyPointY(yVelocity: 0)
        }
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
    
}

extension PullUpController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension UIViewController {
    
    /**
     Adds the specified pull up view controller as a child of the current view controller.
     - parameter pullUpController: the pull up controller to add as a child of the current view controller.
     - parameter initialStickyPointOffset: The point where the provided `pullUpController`'s view will be initially placed expressed in screen units of the pull up controller coordinate system. If this value is not provided, the `pullUpController`'s view will be initially placed expressed
     - parameter animated: Pass true to animate the adding; otherwise, pass false.
     */
    open func addPullUpController(_ pullUpController: PullUpController,
                                  initialStickyPointOffset: CGFloat,
                                  animated: Bool) {
        assert(!(self is UITableViewController), "It's not possible to attach a PullUpController to a UITableViewController. Check this issue for more information: https://github.com/MarioIannotta/PullUpController/issues/14")
        addChild(pullUpController)
        pullUpController.setup(superview: view, initialStickyPointOffset: initialStickyPointOffset)
        if animated {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
    
    /**
     Adds the specified pull up view controller as a child of the current view controller.
     - parameter pullUpController: the pull up controller to remove as a child from the current view controller.
     - parameter animated: Pass true to animate the removing; otherwise, pass false.
     */
    open func removePullUpController(_ pullUpController: PullUpController, animated: Bool) {
        pullUpController.pullUpControllerMoveToVisiblePoint(0, animated: animated) {
            pullUpController.willMove(toParent: nil)
            pullUpController.view.removeFromSuperview()
            pullUpController.removeFromParent()
        }
    }
    
}

extension UIScrollView {
    
    /**
     Attach the scroll view to the provided pull up controller in order to move it with the scroll view content.
     - parameter pullUpController: the pull up controller to move with the current scroll view content.
     */
    open func attach(to pullUpController: PullUpController) {
        pullUpController.internalScrollView = self
    }
    
    /**
     Remove the scroll view from the pull up controller so it no longer moves with the scroll view content.
     - parameter pullUpController: the pull up controller to be removed from controlling the scroll view.
     */
    open func detach(from pullUpController: PullUpController) {
        pullUpController.internalScrollView = nil
    }

}
