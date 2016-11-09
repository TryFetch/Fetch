//
//  FetchMediaControls.swift
//  Fetch
//
//  Created by Stephen Radford on 20/06/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class FetchMediaControls: UIView {

    var barsHidden: Bool = false
    
    @IBOutlet weak private var contentView:UIView!
    @IBOutlet weak var topBar: UINavigationBar!
    @IBOutlet weak var btmBar: UIToolbar!
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var playBtn: UIBarButtonItem!
    
    init(frame: CGRect, title: String) {
        
        super.init(frame: frame)
        NSBundle.mainBundle().loadNibNamed("FetchMediaControls", owner: self, options: nil)
        
        topBar.topItem?.title = title
        
        contentView.frame = frame
        contentView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.addSubview(contentView)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout() {
        contentView.frame = frame
    }
    
    // MARK: - Actions
    
    @IBAction func toggleBars(sender: AnyObject) {
        
        barsHidden = !barsHidden
        
        UIView.animateWithDuration(0.25, animations: {
            
            self.topBar?.alpha = (self.barsHidden) ? 0 : 1
            self.btmBar?.alpha = (self.barsHidden) ? 0 : 1
            
            }, completion: { finished in
                
                self.topBar?.hidden = self.barsHidden
                self.btmBar?.hidden = self.barsHidden
                
        })
        
    }

}
