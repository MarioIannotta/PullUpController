import UIKit

private class PullUpConfigComponents {
    var willMoveToStickyPoint: ((_ point: CGFloat) -> Void)? = nil
    var didMoveToStickyPoint: ((_ point: CGFloat) -> Void)? = nil
    var onDrag: ((_ point: CGFloat) -> Void)? = nil
    var middleStickyPoints: [CGFloat] = []
    var initialStickyPointOffset: CGFloat = 0
    var isBouncingEnabled: Bool = false
    var initialPreferredSize: CGSize = .zero
    var initialPreferredLandscapeFrame: CGRect = .zero
}

public struct PullUpControllerConfiguration {
    private var components = PullUpConfigComponents()


    /// - Parameters:
    ///   - initialStickyPointOffset: Default is 0
    ///   - initialPreferredSize: Default is CGSize(width: UIScreen.main.bounds.width, height: 400)
    ///   - initialPreferredLandscapeFrame: Default is CGRect(x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20)
    ///   - isBouncingEnabled: Default is false
    public init(initialStickyPointOffset: CGFloat = 0,
                initialPreferredSize: CGSize = CGSize(width: UIScreen.main.bounds.width, height: 400),
                initialPreferredLandscapeFrame: CGRect = CGRect(x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20),
                isBouncingEnabled: Bool = false) {
        components.initialStickyPointOffset = initialStickyPointOffset
        components.initialPreferredSize = initialPreferredSize
        components.initialPreferredLandscapeFrame = initialPreferredLandscapeFrame
        components.isBouncingEnabled = isBouncingEnabled
    }

    /**
     The closure to execute before the view controller's view move to a sticky point.
     The target sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    public var willMoveToStickyPoint: ((_ point: CGFloat) -> Void)? {
        return components.willMoveToStickyPoint
    }

    /**
     The closure to execute after the view controller's view move to a sticky point.
     The sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    public var didMoveToStickyPoint: ((_ point: CGFloat) -> Void)? {
        return components.didMoveToStickyPoint
    }

    /**
     The closure to execute when the view controller's view is dragged.
     The point, expressed in the pull up controller parent coordinate system, is provided in the closure parameter.
     */
    public var onDrag: ((_ point: CGFloat) -> Void)? {
        return components.onDrag
    }

    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gestures the pull up controller will scroll to the nearest point in the list.

     Please keep in mind that this array should contains only sticky points in the middle of the pull up controller's view;
     There is therefore no need to add the fist one (pullUpControllerPreviewOffset), and/or the last one (pullUpControllerPreferredSize.height).

     For a complete list of all the sticky points you can use `pullUpControllerAllStickyPoints`.
     */
    public var middleStickyPoints: [CGFloat] {
        return components.middleStickyPoints
    }

    var initialStickyPointOffset: CGFloat {
        return components.initialStickyPointOffset
    }

    /**
     A Boolean value that determines whether bouncing occurs when scrolling reaches the end of the pull up controller's view size.
     The default value is false.
     */
    public var isBouncingEnabled: Bool {
        return components.isBouncingEnabled
    }

    /**
     The desired size of the pull up controller’s view, in screen units.
     The default value is width: UIScreen.main.bounds.width, height: 400.
     */
    public var initialPreferredSize: CGSize {
        return components.initialPreferredSize
    }

    /**
     The desired size of the pull up controller’s view, in screen units when the device is in landscape mode.
     The default value is (x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20).
     */
    public var initialPreferredLandscapeFrame: CGRect {
        return components.initialPreferredLandscapeFrame
    }

    /**
     The closure to execute before the view controller's view move to a sticky point.
     The target sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    public func willMoveToStickyPoint(_ closure: ((_ point: CGFloat) -> Void)?) -> PullUpControllerConfiguration {
        components.willMoveToStickyPoint = closure
        return self
    }

    /**
     The closure to execute after the view controller's view move to a sticky point.
     The sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    public func didMoveToStickyPoint(_ closure: ((_ point: CGFloat) -> Void)?) -> PullUpControllerConfiguration {
        components.didMoveToStickyPoint = closure
        return self
    }

    /**
     The closure to execute when the view controller's view is dragged.
     The point, expressed in the pull up controller parent coordinate system, is provided in the closure parameter.
     */
    public func onDrag(_ closure: ((_ point: CGFloat) -> Void)?) -> PullUpControllerConfiguration {
        components.onDrag = closure
        return self
    }

    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gestures the pull up controller will scroll to the nearest point in the list.

     Please keep in mind that this array should contains only sticky points in the middle of the pull up controller's view;
     There is therefore no need to add the fist one (pullUpControllerPreviewOffset), and/or the last one (pullUpControllerPreferredSize.height).

     For a complete list of all the sticky points you can use `pullUpControllerAllStickyPoints`.
     */
    public func pullUpControllerMiddleStickyPoints(_ points: [CGFloat]) -> PullUpControllerConfiguration {
        components.middleStickyPoints = points
        return self
    }

    public func initialStickyPointOffset(_ offset: CGFloat) -> PullUpControllerConfiguration {
        components.initialStickyPointOffset = offset
        return self
    }

    /**
     A Boolean value that determines whether bouncing occurs when scrolling reaches the end of the pull up controller's view size.
     The default value is false.
     */
    public func isBouncingEnabled(_ enabled: Bool) -> PullUpControllerConfiguration {
        components.isBouncingEnabled = enabled
        return self
    }

    /**
     The desired size of the pull up controller’s view, in screen units.
     The default value is width: UIScreen.main.bounds.width, height: 400.
     */
    public func initialPreferredSize(_ size: CGSize) -> PullUpControllerConfiguration {
        components.initialPreferredSize = size
        return self
    }

    /**
     The desired size of the pull up controller’s view, in screen units when the device is in landscape mode.
     The default value is (x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20).
     */
    public func initialPreferredLandscapeFrame(_ frame: CGRect) -> PullUpControllerConfiguration {
        components.initialPreferredLandscapeFrame = frame
        return self
    }
}
