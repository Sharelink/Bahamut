//
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

//MARK:NoStatusBarViewController
public class NoStatusBarViewController :UIViewController
{
    public override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

//MARK: instanceFromStoryBoard
extension UIViewController
{
    static func instanceFromStoryBoard(storyBoardName:String,identifier:String) -> UIViewController
    {
        let storyBoard = UIStoryboard(name: storyBoardName, bundle: NSBundle.mainBundle())
        return storyBoard.instantiateViewControllerWithIdentifier(identifier)
    }
}

extension UIViewController
{
    func changeNavigationBarColor()
    {
        self.navigationController?.navigationBar.barTintColor = UIColor.navicationBarColor
        self.navigationController?.navigationBar.tintColor = UIColor.navicationBarTintColor
        
        if let nav = self as? UINavigationController
        {
            nav.navigationBar.barTintColor = UIColor.navicationBarColor
            nav.navigationBar.tintColor = UIColor.navicationBarTintColor
        }
    }
}

@objc
protocol OrientationsNavigationController
{
    func supportedViewOrientations() -> UIInterfaceOrientationMask
}

class UIOrientationsNavigationController: UINavigationController ,OrientationsNavigationController
{
    var lockOrientationPortrait:Bool = false
    func supportedViewOrientations() -> UIInterfaceOrientationMask {
        if lockOrientationPortrait
        {
            return UIInterfaceOrientationMask.Portrait
        }
        return UIInterfaceOrientationMask.All
    }
}