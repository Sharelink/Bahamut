//
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

//MARK:NoStatusBarViewController
open class NoStatusBarViewController :UIViewController
{
    open override var prefersStatusBarHidden : Bool {
        return true
    }
}

//MARK: instanceFromStoryBoard
extension UIViewController
{
    static func instanceFromStoryBoard(_ storyBoardName:String,identifier:String,bundle:Bundle = Bundle.main) -> UIViewController
    {
        let storyBoard = UIStoryboard(name: storyBoardName, bundle: bundle)
        return storyBoard.instantiateViewController(withIdentifier: identifier)
    }
}

extension UIViewController
{
    func changeNavigationBarColor()
    {
        self.navigationController?.navigationBar.barTintColor = UIColor.navBarBcgColor
        self.navigationController?.navigationBar.tintColor = UIColor.navBarTintColor
        
        if let nav = self as? UINavigationController
        {
            nav.navigationBar.barTintColor = UIColor.navBarBcgColor
            nav.navigationBar.tintColor = UIColor.navBarTintColor

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
            return UIInterfaceOrientationMask.portrait
        }
        return UIInterfaceOrientationMask.all
    }
}

extension UIViewController{
    func setOverCurrentContext() {
        self.modalPresentationStyle = .overCurrentContext
        self.providesPresentationContextTransitionStyle = true
        self.definesPresentationContext = true
    }
}
