//
//  ChatViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework
import MJRefresh

class ChatViewController:UIViewController,UUInputFunctionViewDelegate,UUMessageCellDelegate,UITableViewDataSource,UITableViewDelegate,UITextViewDelegate
{
    var shareChat:ShareChatHub!{
        didSet{
            if chatRoomListViewController != nil
            {
                chatRoomListViewController.shareChat = shareChat
            }
            if oldValue != nil
            {
                oldValue.removeObserver(self)
            }
            shareChat.addObserver(self, selector: "chatHubNewMessageChanged:", name: ShareChatHubNewMessageChanged, object: nil)
            shareChat.addObserver(self, selector: "currentChatChanged:", name: ChatHubCurrentChatModelChanged, object: nil)
            shareChat.addObserver(self, selector: "currentChatMessageChanged:", name: ChatHubCurrentChatMessageChanged, object: nil)
            shareChat.currentChatModel = shareChat.getSortChats().first
            chatRoomBadgeValue = shareChat.newMessage
        }
    }
    
    func chatHubNewMessageChanged(a:NSNotification)
    {
        chatRoomBadgeValue = shareChat.newMessage
    }
    
    func currentChatMessageChanged(a:NSNotification)
    {
        self.chatTableView.reloadData()
        self.chatTableViewScrollToBottom()
    }
    
    func currentChatChanged(a:NSNotification)
    {
        chatRoomBadgeValue = shareChat.newMessage
        updateChatTitle()
        refreshMessageList()
        hideRommListContainer()
    }
    
    var head:MJRefreshHeader!
    
    @IBOutlet weak var chatTitle: UINavigationItem!{
        didSet{
            updateChatTitle()
        }
    }
    
    var messageService:MessageService!
    var chatRoomListViewController:ChatRoomListViewController!
    @IBOutlet weak var roomsContainer: UIView!
    @IBOutlet weak var roomContainerTrailiing: NSLayoutConstraint!
    
    var chatRoomBadgeValue:Int!{
        didSet{
            if chatRoomItemBadgeButton != nil
            {
                chatRoomItemBadgeButton.badgeValue =  chatRoomBadgeValue == 0 ? "" : "\(chatRoomBadgeValue)"
            }
        }
    }
    var chatRoomItemBadgeButton:UIButton!
    var chatRoomItem: UIBarButtonItem!
    @IBOutlet weak var chatTableView:UITableView!{
        didSet{
            chatTableView.dataSource = self
            chatTableView.delegate = self
        }
    }
    @IBOutlet weak var bottomConstraint:NSLayoutConstraint!
    var IFView:UUInputFunctionView!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.addInputFunctionView()
        self.initChatRoomListViewController()
        self.initBar()
        self.addRefreshViews()
        ChicagoClient.sharedInstance.addObserver(self, selector: "chicagoClientStateChanged:", name: ChicagoClientStateChanged, object: nil)
    }
    
    deinit{
        if shareChat != nil
        {
            shareChat.removeObserver(self)
        }
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    func chicagoClientStateChanged(aNotification:NSNotification)
    {
        chatTableView.reloadData()
    }
    
    private func initChatRoomListViewController()
    {
        chatRoomListViewController = self.childViewControllers.filter{$0 is ChatRoomListViewController}.first as! ChatRoomListViewController
        chatRoomListViewController.rootController = self
        chatRoomListViewController.shareChat = self.shareChat
        self.view.bringSubviewToFront(roomsContainer)
    }
    
    private func initGesture()
    {
        
    }
    
    func swipeRight(_:UIGestureRecognizer)
    {
        hideRommListContainer()
    }
    
    func swipeLeft(_:UIGestureRecognizer)
    {
        showRoomListContainer()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardChange:", name:UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardChange:", name:UIKeyboardWillHideNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"tableViewScrollToBottom:", name:UIKeyboardDidShowNotification, object:nil)
        shareChat.inChatView = true
        chatTableViewScrollToBottom()
        MobClick.beginLogPageView("ChatView")
    }
    
    override func viewWillDisappear(animated:Bool)
    {
        super.viewWillDisappear(animated)
        shareChat.inChatView = false
        NSNotificationCenter.defaultCenter().removeObserver(self)
        MobClick.endLogPageView("ChatView")
    }
    
    func initBar()
    {
        chatRoomItemBadgeButton = UIButton(type: .System)
        let item = UIBarButtonItem(title: "", style: .Plain, target: self, action: "clickChatRoomItem:")
        item.customView = UIImageView(image: UIImage(named: "internet-group-chat"))
        item.customView?.addSubview(chatRoomItemBadgeButton)
        item.customView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "clickChatRoomItem:"))
        chatRoomItem = item
        self.navigationItem.rightBarButtonItem = chatRoomItem
        chatRoomBadgeValue = self.shareChat.newMessage
    }

    func addRefreshViews()
    {
        let header = MJRefreshNormalHeader(){
            let num = self.shareChat.currentChatModel.loadPreviousMessage()
            if (num > 0) {
                let indexPath =  NSIndexPath(forRow: num, inSection: 0)
                let time = Double(NSEC_PER_SEC) / 10
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64( time)), dispatch_get_main_queue()){
                    self.chatTableView.reloadData()
                    self.chatTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Top, animated:false)
                }
            }else
            {
                self.showToast( NSLocalizedString("NO_MORE_MESSAGE", comment: "No More Message~"))
            }
            self.head.endRefreshing()
        }
        header.setTitle(NSLocalizedString("LOADING",comment:"Loading"), forState: .Pulling)
        header.lastUpdatedTimeLabel?.hidden = true
        head = header
        chatTableView.mj_header = head
    }
    
    func addInputFunctionView()
    {
        IFView = UUInputFunctionView()
        IFView.superVC = self
        IFView.delegate = self
        IFView.TextViewInput.returnKeyType = .Send
        self.view.addSubview(IFView)
    }
    
    func refreshMessageList()
    {
        if chatTableView != nil
        {
            self.shareChat.currentChatModel.loadPreviousMessage()
            self.chatTableView.reloadData()
            self.chatTableViewScrollToBottom()
        }
    }
    
    func updateChatTitle()
    {
        if chatTitle != nil
        {
            chatTitle.title = shareChat?.currentChatModel?.chatTitle ?? ""
        }
    }
    
    func clickChatRoomItem(sender: AnyObject)
    {

        if roomContainerTrailiing.constant > 0
        {
            hideRommListContainer()
        }else
        {
            showRoomListContainer()
        }
    }
    
    func showRoomListContainer()
    {
        if roomContainerTrailiing != nil
        {
            UIView.beginAnimations(nil, context:nil)
            UIView.setAnimationDuration(0.2)
            UIView.setAnimationCurve(.Linear)
            roomContainerTrailiing.constant = roomsContainer.frame.size.width - 13
            self.view.layoutIfNeeded()
            UIView.commitAnimations()
        }
    }
    
    func hideRommListContainer()
    {
        if roomContainerTrailiing != nil
        {
            UIView.beginAnimations(nil, context:nil)
            UIView.setAnimationDuration(0.1)
            UIView.setAnimationCurve(.Linear)
            roomContainerTrailiing.constant = 0
            self.view.layoutIfNeeded()
            
            UIView.commitAnimations()
        }
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
            hideRommListContainer()
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
        if self.shareChat.currentChatModel == nil || self.shareChat.currentChatModel.dataSource.count==0
        {
            return
        }
        let indexPath =  NSIndexPath(forRow:self.shareChat.currentChatModel.dataSource.count - 1, inSection:0)
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
            self.showAlert(NSLocalizedString("SEND_WHITE_SPACE_ERROR", comment:"Can't Send White Space"), msg: nil)
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
        self.shareChat.currentChatModel.addMessage(msgItem)
        self.chatTableView.reloadData()
        self.chatTableViewScrollToBottom()
    }
    
    
    //MARK: chat table view delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return shareChat.currentChatModel == nil ? 0 : 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shareChat.currentChatModel.dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell =  tableView.dequeueReusableCellWithIdentifier("UUMessageCellID") as? UUMessageCell
        if (cell == nil) {
            cell = UUMessageCell(style:UITableViewCellStyle.Default, reuseIdentifier:"UUMessageCellID")
            cell!.delegate = self
        }
        cell!.messageFrame = (self.shareChat.currentChatModel.dataSource[indexPath.row]).msgFrame
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        let cf = self.shareChat.currentChatModel.dataSource[indexPath.row]
        return cf.msgFrame.cellHeight
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if ChicagoClient.sharedInstance.clientState != .Validated
        {
            return 35
        }
        return 0
    }
    
    var stateHeaderView:UIClientStateHeader!{
        didSet{
            stateHeaderView.initHeader()
        }
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cstate = ChicagoClient.sharedInstance.clientState
        if cstate != ChicagoClientState.Validated
        {
            if stateHeaderView == nil
            {
                stateHeaderView = UIClientStateHeader.instanceFromXib()
                stateHeaderView.refresh()
            }
            return stateHeaderView
        }
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        hideRommListContainer()
        hideKeyBoard()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
        hideRommListContainer()
        hideKeyBoard()
    }
    
    func scrollViewWillBeginDragging(scrollView:UIScrollView)
    {
        hideRommListContainer()
        hideKeyBoard()
        hideKeyBoard()
    }
    
    func headImageDidClick(cell:UUMessageCell, userId:String!)
    {
        ServiceContainer.getService(UserService).showUserProfileViewController(self.navigationController!, userId: userId)
    }
    
    static func instanceFromStoryBoard() -> ChatViewController
    {
        return instanceFromStoryBoard("UIMessage", identifier: "ChatViewController") as! ChatViewController
    }
    
}
