//
//  InfomationViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class InformationViewController: UIViewController {

    private struct Constants{
        static let SegueShowSignView = "Show Sign View"
    }
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var validateTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveInformationButton: UIButton!
    @IBOutlet weak var getValidateCodeButton: UIButton!
    @IBAction func getValidateCode() {
    }
    @IBAction func saveInformation() {
    }
}
