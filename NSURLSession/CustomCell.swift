//
//  CustomCell.swift
//  NSURLSession
//
//  Created by Waleed Alware on 2/10/16.
//  Copyright © 2016 Waleed Alware. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {
	
	@IBOutlet weak var readButton: UIButton!
	@IBOutlet weak var selectButton: UIButton!
	@IBOutlet weak var fileTitleLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        progressView.progress = 0.0
        progressView.hidden = true
        fileTitleLabel.text = ""
        selectButton.hidden = false
        readButton.hidden = true
    }
	
}
