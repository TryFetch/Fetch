//
//  TVShowCollectionViewCell.swift
//  Fetch
//
//  Created by Stephen Radford on 21/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class TVShowCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var doneView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = [.flexibleHeight]
        
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.fetchLighterBackground().cgColor
    }
    
}
