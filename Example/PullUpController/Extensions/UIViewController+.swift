//
//  UIViewController+.swift
//  PullUpController_Example
//
//  Created by Mario on 24/02/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

extension UIViewController {

    var hasSafeArea: Bool {
        guard
            #available(iOS 11.0, tvOS 11.0, *)
            else {
                return false
            }
        return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
    }

}
