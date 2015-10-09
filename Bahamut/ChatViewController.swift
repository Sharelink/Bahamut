//
//  ChatViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import MJRefresh
import ChatFramework

class UUMsgItem
{
    init()
    {
        frame = UUMessageFrame()
        uimsg = UUMessage()
        dic = [NSObject : AnyObject]()
        msgFrom = .Me
    }
    private(set) var dic:[NSObject : AnyObject]!
    private var frame:UUMessageFrame!
    private var uimsg:UUMessage!
    var msgFrame:UUMessageFrame{
        uimsg.setWithDict(dic)
        frame.message = uimsg
        return frame
    }
    
    var previousTime:String!{
        didSet{
            uimsg.minuteOffSetStart(previousTime, end: timeString)
            frame.showTime = uimsg.showDateLabel
        }
    }
    
    var nick:String!{
        didSet{
            dic.updateValue(nick, forKey: "strName")
        }
    }
    
    var msgFrom:UUMessageFrom{
        didSet{
            dic.updateValue(msgFrom.rawValue, forKey: "from")
        }
    }
    
    var timeString:String!{
        didSet{
            uimsg.minuteOffSetStart(previousTime, end: timeString)
            frame.showTime = uimsg.showDateLabel
            dic.updateValue(timeString, forKey: "strTime")
        }
    }
    
    var headIcon:String!{
        didSet{
            dic.updateValue(headIcon, forKey: "strIcon")
        }
    }
    
    var msgType:UUMessageType = .Text{
        didSet{
            dic.updateValue(msgType.rawValue, forKey: "type")
        }
    }
    
}

class UUMsgTextItem: UUMsgItem
{
    override init()
    {
        super.init()
        self.msgType = .Text
    }
    
    var message:String!{
        didSet{
            dic.updateValue(message, forKey: "strContent")
        }
    }
}

class UUMsgVoiceItem: UUMsgItem
{
    override init()
    {
        super.init()
        self.msgType = .Voice
    }
    
    var voice:NSData!{
        didSet{
            dic.updateValue(voice, forKey: "voice")
        }
    }
    
    var voiceTimeSec:Int = 0{
        didSet{
            dic.updateValue("\(voiceTimeSec)", forKey: "strVoiceTime")
        }
    }
}

class UUmsgPictureItem: UUMsgItem
{
    override init()
    {
        super.init()
        self.msgType = .Picture
    }
    
    var image:UIImage!{
        didSet{
            dic.updateValue(image, forKey: "picture")
        }
    }
}

class ChatModel
{
    
    init()
    {
        dataSource = NSMutableArray();
    }
    var previousTime:String!
    var myIcon:String!
    func addMessage(newMsg:UUMsgItem)
    {
        newMsg.timeString = NSDate().description
        newMsg.previousTime = previousTime
        if newMsg.msgFrame.showTime
        {
            previousTime = newMsg.timeString
        }
        dataSource.addObject(newMsg)
    }
    
    private(set) var dataSource:NSMutableArray!
}

@objc class ChatViewController:UIViewController,UUInputFunctionViewDelegate,UUMessageCellDelegate,UITableViewDataSource,UITableViewDelegate
{
    
    var head:MJRefreshHeader!
    var chatModel:ChatModel!{
        didSet{
            
        }
    }
    
    @IBOutlet weak var chatTableView:UITableView!{
        didSet{
            chatTableView.dataSource = self
            chatTableView.delegate = self
        }
    }
    @IBOutlet weak var bottomConstraint:NSLayoutConstraint!
    var IFView:UUInputFunctionView!

    override  func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.initBar()
        self.addRefreshViews()
        self.loadBaseViewsAndData()
    }
    
    override func viewDidAppear(animated:Bool)
    {
        
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardChange:", name:UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardChange:", name:UIKeyboardWillHideNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"tableViewScrollToBottom:", name:UIKeyboardDidShowNotification, object:nil)
    }
    
    override func viewWillDisappear(animated:Bool)
    {
        
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func initBar()
    {
        
    }
    
    func addRefreshViews()
    {
        let pageNum =  3
        let header = MJRefreshNormalHeader(){
            if (self.chatModel.dataSource.count > pageNum) {
                let indexPath =  NSIndexPath(forRow: pageNum, inSection: 0)
                let time = Double(NSEC_PER_SEC) / 10
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64( time)), dispatch_get_main_queue()){
                    self.chatTableView.reloadData()
                    self.chatTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Top, animated:false)
                }
            }
            self.head.endRefreshing()
        }
        header.setTitle("Loading", forState: MJRefreshStatePulling)
        header.lastUpdatedTimeLabel?.hidden = true
        head = header
        chatTableView.header = head
    }
    
    func loadBaseViewsAndData()
    {
        IFView = UUInputFunctionView()
        IFView.superVC = self
        IFView.delegate = self
        self.view.addSubview(IFView)
        self.chatTableView.reloadData()
        self.chatTableViewScrollToBottom()
    }
    
    func keyboardChange(notification:NSNotification)
    {
        var userInfo =  notification.userInfo!
        
        var animationDuration:NSTimeInterval
        var animationCurve:UIViewAnimationCurve
        var keyboardEndFrame:CGRect!
        
        let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! Int
        
        animationCurve = UIViewAnimationCurve(rawValue: curve)!
        
        animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        keyboardEndFrame = userInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        
        UIView.beginAnimations(nil, context:nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        
        
        //adjust ChatTableView's height
        if (notification.name == UIKeyboardWillShowNotification) {
            self.bottomConstraint.constant = keyboardEndFrame.size.height + 40
        }else{
            self.bottomConstraint.constant = 40
        }
        
        self.view.layoutIfNeeded()
        
        
        //adjust UUInputFunctionView's originPoint
        
        var newFrame =  IFView.frame
        newFrame.origin.y = keyboardEndFrame.origin.y - newFrame.size.height
        IFView.frame = newFrame
        
        UIView.commitAnimations()
        
    }
    
    //tableView Scroll to bottom
    func chatTableViewScrollToBottom()
    {
        if self.chatModel.dataSource.count==0
        {
            return
        }
        let indexPath =  NSIndexPath(forRow:self.chatModel.dataSource.count - 1, inSection:0)
        chatTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
    }
    
    func tableViewScrollToBottom(notification:NSNotification)
    {
        chatTableViewScrollToBottom()
    }
    
    //MARK: UUInputViewDelegate
    func UUInputFunctionViewSend(funcView: UUInputFunctionView!, sendMessage message: String!)
    {
        
        if String.isNullOrWhiteSpace(message)
        {
            chatTableView.makeToast(message: "Can't Send White Space", duration: 1.0, position: HRToastPositionCenter)
            funcView.TextViewInput.text = ""
            return
        }
        let msg = UUMsgTextItem()
        msg.message = message
        msg.msgFrom = .Me
        funcView.TextViewInput.text = ""
        funcView.changeSendBtnWithPhoto(true)
        dealTheFunctionData(msg)
    }
    
    func UUInputFunctionViewSend(funcView: UUInputFunctionView!, sendPicture image: UIImage!)
    {
        let msg = UUmsgPictureItem()
        msg.image = image
        msg.msgFrom = .Me
        dealTheFunctionData(msg)
    }
    
    func UUInputFunctionViewSend(funcView: UUInputFunctionView!, sendVoice voice: NSData!, time second: Int)
    {
        let msg = UUMsgVoiceItem()
        msg.voiceTimeSec = second
        msg.voice = voice
        dealTheFunctionData(msg)
    }
    
    func dealTheFunctionData(msgItem:UUMsgItem)
    {
        self.chatModel.addMessage(msgItem)
        self.chatTableView.reloadData()
        self.chatTableViewScrollToBottom()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatModel.dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell =  tableView.dequeueReusableCellWithIdentifier("UUMessageCellID") as? UUMessageCell
        if (cell == nil) {
            cell = UUMessageCell(style:UITableViewCellStyle.Default, reuseIdentifier:"UUMessageCellID")
            cell!.delegate = self
        }
        cell!.messageFrame = (self.chatModel.dataSource[indexPath.row] as! UUMsgItem).msgFrame
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        if let cf = self.chatModel.dataSource[indexPath.row] as? UUMsgItem
        {
            return cf.msgFrame.cellHeight
        }
        return 0.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.view.endEditing(true)    
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(scrollView:UIScrollView)
    {
        self.view.endEditing(true)
    }
    
    func headImageDidClick(cell:UUMessageCell, userId:String!)
    {
        
    }
    
    static func instanceFromStoryBoard() -> ChatViewController
    {
        return instanceFromStoryBoard("UIMessage", identifier: "ChatViewController") as! ChatViewController
    }
    
}
