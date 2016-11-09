//
//  AnswerViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 20/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class AnswerViewController: UIViewController {

    var faq: FAQ!
    
    @IBOutlet weak var answer: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = faq.question
        answer.text = faq.answer
        
        answer.textContainerInset = UIEdgeInsetsMake(10, 7, 10, 7)
    }

}
