//
//  ChatServiceModel.swift
//  Tinodios
//
//  Created by Wira on 03/11/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Combine
import Foundation
import UIKit

public protocol ChatServiceNetworkModel {
    
    func configureUser(completion: ((Bool) -> Void)?)
    func loginOrRegister(userName: String, password: String, fullName: String, completion: @escaping (Bool) -> Void)
    func getParticipant(orderId: String, completion: @escaping ((_ chatroomId: String, _ callroomId: String, _ fullName: String) -> Void))
    func onSignOut()
    func subscribeToken(clientId: String, token: String)
    func setNotifClientIdTinode(clientId: String)
    func handleNotification(_ application: UIApplication.State, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void?)
    func generateSecurityToken(clientId: String, clientSecret: String)
  
}
