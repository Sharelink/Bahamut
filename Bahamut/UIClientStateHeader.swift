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
        self.backgroundColor = UIColor(colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        indicator.startAnimating()
        messageLabel.text = NSLocalizedString("CONNECTING", comment: "Connecting")
    }
    
    func setConnectError()
    {
        self.backgroundColor = UIColor(colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        indicator.stopAnimating()
        messageLabel.text = NSLocalizedString("CONNECT_ERROR_TAP_RETRY", comment: "Network Error,Tap Here Retry")
    }

}
