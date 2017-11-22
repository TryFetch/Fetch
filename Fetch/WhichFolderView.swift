//
//  WhichFolderView.swift
//  Fetch
//
//  Created by Stephen Radford on 15/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class WhichFolderView: UIView {

    /// The label that will display which folder is currently selected
    var label: UILabel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fetchLighterBackground()
        
        label = UILabel(frame: CGRect(x: 50, y: 0, width: frame.width-80, height: frame.height))
        label.text = "All Files"
        label.font = .preferredFont(forTextStyle: UIFontTextStyle.body)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        let image = UIImageView(image: UIImage(named: "folder"))
        image.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        image.translatesAutoresizingMaskIntoConstraints = false
        addSubview(image)
        
        let chevron = UIImageView(image: UIImage(named: "down-chevron"))
        chevron.frame = CGRect(x: frame.width-20, y: 0, width: 20, height: 10)
        chevron.tintColor = UIColor(red:0.67, green:0.67, blue:0.67, alpha:1)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(chevron)
        
        let viewsDict: [String:UIView] = [
            "superview": self,
            "label": label,
            "folder": image,
            "chevron": chevron
        ]
        
        // THE AUTOLAYOUT CONSTRAINTS
        
        let aConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[superview]-(<=1)-[folder]", options: .alignAllCenterY, metrics: nil, views: viewsDict)
        addConstraints(aConstraints)
        
        let aConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:[superview]-(<=1)-[label]", options: .alignAllCenterY, metrics: nil, views: viewsDict)
        addConstraints(aConstraints2)
        
        let aConstraints3 = NSLayoutConstraint.constraints(withVisualFormat: "H:[superview]-(<=1)-[chevron]", options: .alignAllCenterY, metrics: nil, views: viewsDict)
        addConstraints(aConstraints3)
        
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[folder(==30)]-10-[label]-10-[chevron(==18)]-11-|", options: [], metrics: nil, views: viewsDict)
        addConstraints(hConstraints)
        
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[chevron(==10)]", options: [], metrics: nil, views: viewsDict)
        addConstraints(vConstraints)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideWithAnimation() {
        UIView.animate(withDuration: 0.35, animations: {
            self.alpha = 0
        }, completion: { finished in
            self.isHidden = true
        })
    }
    
    func showWithAnimation() {
        alpha = 0
        isHidden = false
        
        UIView.animate(withDuration: 0.35, animations: {
            self.alpha = 1
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = UIColor(hue:0, saturation:0, brightness:0.27, alpha:1)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = .fetchLighterBackground()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = .fetchLighterBackground()
    }
    
}
