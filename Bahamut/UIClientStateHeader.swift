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
    
    static func instanceFromXib() -> UIClientStateHeader
    {
        return Sharelink.mainBundle.loadNibNamed("UIViews", owner: nil, options: nil).filter{$0 is UIClientStateHeader}.first as! UIClientStateHeader
    }

    deinit{
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    func initHeader()
    {
        startConnect()
        ChicagoClient.sharedInstance.addObserver(self, selector: "chicagoClientStateChanged:", name: ChicagoClientStateChanged, object: nil)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "reconnectChicagoClient:"))
    }
    
    func reconnectChicagoClient(_:UIGestureRecognizer)
    {
        ChicagoClient.sharedInstance.reConnect()
    }
    
    func refresh()
    {
        if ChicagoClient.sharedInstance.clientState == .Closed
        {
            self.hidden = true
        }else
        {
            self.hidden = false
        }

        switch ChicagoClient.sharedInstance.clientState
        {
        case .ValidatFailed:
            setValidateFailed()
        case .Connecting:
            startConnect()
        case .Connected:
            setConnected()
        default:
            setConnectError()
            
        }
    }
    
    func chicagoClientStateChanged(aNotification:NSNotification)
    {
        refresh()
    }
    
    private func setConnected()
    {
        self.backgroundColor = UIColor.headerColor
        indicator.startAnimating()
        messageLabel.text = "CONNECTED".localizedString()
    }
    
    private func startConnect()
    {
        self.backgroundColor = UIColor.headerColor
        indicator.startAnimating()
        messageLabel.text = "CONNECTING".localizedString()
    }
    
    private func setConnectError()
    {
        self.backgroundColor = UIColor.headerColor
        indicator.stopAnimating()
        messageLabel.text = "CONNECT_ERROR_TAP_RETRY".localizedString()
    }
    
    private func setValidateFailed()
    {
        self.backgroundColor = UIColor.headerColor
        indicator.stopAnimating()
        messageLabel.text = "CHICAGO_VALIDATE_FAILED".localizedString()
        
    }

}
