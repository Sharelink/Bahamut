//
//  GameCenterHelper.swift
//  snakevsblock
//
//  Created by Alex Chow on 2017/7/5.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import GameKit

class GameCenterHelper:NSObject,GKGameCenterControllerDelegate {
    private(set) static var gameCenterAvailable = false
    
    static let shared:GameCenterHelper = {
        return GameCenterHelper()
    }()
    
    func authorizeGameCenter(callback:@escaping (UIViewController?,Error?)->Void) {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = { vc,err in
            if localPlayer.isAuthenticated{
                GameCenterHelper.gameCenterAvailable = true
            }
            callback(vc, err)
        }
    }
    
    func showLeaderBoard(vc:UIViewController,boardId:String) {
        let gcvc = GKGameCenterViewController()
        gcvc.viewState = .leaderboards
        gcvc.leaderboardIdentifier = boardId
        gcvc.gameCenterDelegate = self
        vc.present(gcvc, animated: true){}
    }
    
    func reportScoreToGC(boardId:String,newScore:Int,callback:((GKScore,Error?)->Void)? = nil) {
        reportScoreToGC(boardId: boardId, newBigScore: Int64(newScore), callback: callback)
    }
    
    func reportScoreToGC(boardId:String,newBigScore:Int64,callback:((GKScore,Error?)->Void)? = nil) {
        let score = GKScore(leaderboardIdentifier: boardId)
        score.value = newBigScore
        GKScore.report([score], withCompletionHandler: { (err) in
            callback?(score,err)
        })
    }
    
    func loadLocalPlayerScore(boardId:String,callback:@escaping (GKScore?,Error?)->Void) {
        let localPlayer = GKLocalPlayer.localPlayer()
        let board = GKLeaderboard(players: [localPlayer])
        board.identifier = boardId
        board.loadScores { (playersScores, err) in
            callback(playersScores?.first, err)
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
