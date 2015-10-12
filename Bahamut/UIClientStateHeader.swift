//
//  UIClientStateHeader.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

class UIClientStateHeader: UIView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    
    func startConnect()
    {
        indicator.startAnimating()
        messageLabel.text = "Connecting"
    }
    
    func setConnectError()
    {
        indicator.stopAnimating()
        messageLabel.text = "Stupid Network"
    }

}
