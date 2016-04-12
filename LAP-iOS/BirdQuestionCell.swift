//
//  BirdQuestionCell.swift
//  LAP-iOS
//
//  Created by Kevin Argumedo on 2/24/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//

import Foundation
import UIKit

class BirdQuestionCell: UICollectionViewCell {
    
    @IBOutlet var name: UILabel!
    
    @IBOutlet weak var checkedButton: UIButton!
    
    var checked: Bool!
    
    @IBOutlet var imageView: UIImageView!
}