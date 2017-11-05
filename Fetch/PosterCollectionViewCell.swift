//
//  PosterCollectionViewCell.swift
//  Fetch
//
//  Created by Stephen Radford on 13/12/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit

class PosterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var poster: UIImageView!
    
    override func awakeFromNib() {
        clipsToBounds = true
        backgroundColor =  UIColor(hue: 0, saturation: 0, brightness: 0.1, alpha: 1)
        layer.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.1, alpha: 1).cgColor
        layer.borderWidth = 1
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
}
