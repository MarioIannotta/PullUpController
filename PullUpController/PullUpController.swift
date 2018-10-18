//
//  PullUpController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

private protocol PullUpAble: class {}
private protocol ViewControllerPullUpAble: PullUpAble {}

private var PullUpManagerKey: UInt8 = 0

extension UIViewController: ViewControllerPullUpAble {}

private extension PullUpAble {
    var _pullManager: PullUpManager? {
        get {
            return objc_getAssociatedObject(self, &PullUpManagerKey) as? PullUpManager
        }
        set(newValue) {
            objc_setAssociatedObject(self, &PullUpManagerKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

open class PullUpManager: NSObject {
    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gesture the pull up controller will scroll at the nearest point in the list.
     */
    public final var pullUpControllerAllStickyPoints: [CGFloat] {
        var sc_allStickyPoints = [config.initialStickyPointOffset, pullUpControllerPreferredSize.height].compactMap { $0 }
        sc_allStickyPoints.append(contentsOf: config.middleStickyPoints)
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
    
    private weak var parentViewController: UIViewController?
    private weak var pullUpController: UIViewController?
    private let config: PullUpControllerConfiguration
    
    private var pullUpControllerPreferredSize: CGSize
    private var pullUpControllerPreferredLandscapeFrame: CGRect
    
    init(parentViewController: UIViewController, pullUpController: UIViewController, attaching scrollView: UIScrollView?, configuration: PullUpControllerConfiguration) {
        self.parentViewController = parentViewController
        self.pullUpController = pullUpController
        self.config = configuration
        
        internalScrollView = scrollView
        pullUpControllerPreferredSize = config.initialPreferredSize
        pullUpControllerPreferredLandscapeFrame = config.initialPreferredLandscapeFrame
        
        super.init()
        
        pullUpController._pullManager = self
    }
    
    private var parentView: UIView? {
        return parentViewController?.view
    }
    
    private var pullUpView: UIView? {
        return pullUpController?.view
    }
    
    fileprivate func removePullUpController() {
        parentViewController = nil
        pullUpController = nil
    }
    
    // MARK: - Open methods
    
    open func pullUpControllerUpdateWidth(_ width: CGFloat) {
        pullUpControllerPreferredSize = CGSize(width: width,
                                               height: pullUpControllerPreferredSize.height)
        
        pullUpControllerPreferredLandscapeFrame = CGRect(origin: pullUpControllerPreferredLandscapeFrame.origin,
                                                         size: CGSize(width: width,
                                                                      height: pullUpControllerPreferredLandscapeFrame.height))
        
        updatePreferredFrameIfNeeded(animated: true)
    }
    
    open func pullUpControllerUpdateHeight(_ height: CGFloat) {
        pullUpControllerPreferredSize = CGSize(width: pullUpControllerPreferredSize.width,
                                               height: height)
        pullUpControllerPreferredLandscapeFrame = CGRect(origin: pullUpControllerPreferredLandscapeFrame.origin,
                                                         size: CGSize(width: pullUpControllerPreferredLandscapeFrame.width,
                                                                      height: height))
        updatePreferredFrameIfNeeded(animated: true)
    }
    
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
        topConstraint?.constant = (parentView?.frame.height ?? 0) - visiblePoint
        
        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: { [weak parentView] in
                    parentView?.layoutIfNeeded()
                },
                completion: { _ in
                    completion?()
            })
        } else {
            parentView?.layoutIfNeeded()
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
            let parentView = parentView
            else { return }
        refreshConstraints(newSize: parentView.frame.size,
                           customTopOffset: parentView.frame.size.height - (pullUpControllerAllStickyPoints.first ?? 0))
        
        UIView.animate(withDuration: animated ? 0.3 : 0) { [weak pullUpView] in
            pullUpView?.layoutIfNeeded()
        }
    }
    
    
    open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
    
    fileprivate func setup(superview: UIView) {
        guard let pullUpView = pullUpView else {
            return
        }
        pullUpView.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(pullUpView)
        pullUpView.frame = CGRect(origin: CGPoint(x: pullUpView.frame.origin.x,
                                                  y: superview.bounds.height),
                                  size: pullUpView.frame.size)
        
        setupPanGestureRecognizer()
        setupConstraints()
        refreshConstraints(newSize: superview.frame.size,
                           customTopOffset: superview.frame.height - config.initialStickyPointOffset)
    }
    
    private func setupPanGestureRecognizer() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer?.minimumNumberOfTouches = 1
        panGestureRecognizer?.maximumNumberOfTouches = 1
        panGestureRecognizer?.delegate = self
        if let panGestureRecognizer = panGestureRecognizer, let pullUpView = pullUpView {
            pullUpView.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    private func setupConstraints() {
        guard
            let parentView = parentView,
            let pullUpView = pullUpView
            else { return }
        
        topConstraint = pullUpView.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 0)
        leftConstraint = pullUpView.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 0)
        widthConstraint = pullUpView.widthAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.width)
        heightConstraint = pullUpView.heightAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.height)
        
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
        let stickyPointTreshold = (parentView?.frame.height ?? 0) - (topConstraint?.constant ?? 0)
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
        
        config.willMoveToStickyPoint?(pullUpControllerAllStickyPoints[currentStickyPointIndex])
        return (parentView?.frame.height ?? 0) - pullUpControllerAllStickyPoints[currentStickyPointIndex]
    }
    
    @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            isPortrait,
            let topConstraint = topConstraint,
            let lastStickyPoint = pullUpControllerAllStickyPoints.last,
            let parentView = parentView
            else { return }
        
        let parentViewHeight = parentView.frame.height
        var yTranslation = gestureRecognizer.translation(in: parentView).y
        gestureRecognizer.setTranslation(.zero, in: pullUpView)
        
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
            let yVelocity = gestureRecognizer.velocity(in: pullUpView).y // v = px/s
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
            let parentViewHeight = parentView?.frame.height
            else { return }
        var value = value
        if !config.isBouncingEnabled,
            let firstStickyPoint = pullUpControllerAllStickyPoints.first,
            let lastStickyPoint = pullUpControllerAllStickyPoints.last {
            value = max(value, parentViewHeight - lastStickyPoint)
            value = min(value, parentViewHeight - firstStickyPoint)
        }
        topConstraint?.constant = value
        config.onDrag?(value)
        
        UIView.animate(
            withDuration: animationDuration ?? 0,
            animations: { [weak parentView] in
                parentView?.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                let point = (self?.parentView?.frame.height ?? 0.0) - (self?.topConstraint?.constant ?? 0.0)
                self?.config.didMoveToStickyPoint?(point)
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

extension PullUpManager: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

public protocol PullUpController {
    var isPullUpController: Bool { get }
    func pullUpViewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    func pullUpControllerMoveToVisiblePoint(_ visiblePoint: CGFloat, animated: Bool, completion: (() -> Void)?)
}

public protocol PullUpControllerContainer {
    func addPullUpController(_ pullUpController: UIViewController,
                             attaching scrollView: UIScrollView,
                             configuration: PullUpControllerConfiguration,
                             animated: Bool) -> PullUpManager
    
    func removePullUpController(_ pullUpController: UIViewController, animated: Bool)
}

extension PullUpController where Self: UIViewController {
    public var isPullUpController: Bool {
        return self._pullManager != nil
    }
    
    public func pullUpControllerMoveToVisiblePoint(_ visiblePoint: CGFloat, animated: Bool, completion: (() -> Void)?) {
        guard let manager = _pullManager else {
            return
        }
        manager.pullUpControllerMoveToVisiblePoint(visiblePoint, animated: animated, completion: completion)
    }
    
    public func pullUpViewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let manager = _pullManager else {
            return
        }
        manager.viewWillTransition(to: size, with: coordinator)
    }
}

extension PullUpControllerContainer where Self: UIViewController {
    @discardableResult
    public func addPullUpController(_ pullUpController: UIViewController,
                                    attaching scrollView: UIScrollView,
                                    configuration: PullUpControllerConfiguration,
                                    animated: Bool) -> PullUpManager {
        assert(!(self is UITableViewController), "It's not possible to attach a PullUpController to a UITableViewController. Check this issue for more information: https://github.com/MarioIannotta/PullUpController/issues/14")
        let manager = PullUpManager(parentViewController: self,
                                    pullUpController: pullUpController,
                                    attaching: scrollView,
                                    configuration: configuration)
        addChildViewController(pullUpController)
        manager.setup(superview: view)
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
        return manager
    }
    
    public func removePullUpController(_ pullUpController: UIViewController, animated: Bool) {
        guard let manager = pullUpController._pullManager else {
            return
        }
        manager.pullUpControllerMoveToVisiblePoint(0, animated: animated) {
            pullUpController.willMove(toParentViewController: nil)
            pullUpController.view.removeFromSuperview()
            pullUpController.removeFromParentViewController()
        }
        manager.removePullUpController()
    }
}
