//
//  SearchResultCell.swift
//  PullUpControllerDemo
//
//  Created by Mario on 04/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    func configure(title: String) {
        titleLabel.text = title
    }
}
