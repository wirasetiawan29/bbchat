//
//  Login.swift
//  Tinodios
//
//  Created by Bluebird Macbook on 03/07/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation
//import TinodiosDB
import TinodeSDK
import UIKit

class BBChat {
    
    enum DataError: Error {
        case serverError
        case networkError
    }
    
    func initialization() {
        
    }
    
    func doLogin(userName: String, password: String, completion: @escaping (Result<Data, Error>) -> Void) {
        
        let tinode = Cache.tinode
    
        do {
            try tinode.connectDefault(inBackground: false)?
                .thenApply({ _ in
                        return tinode.loginBasic(uname: userName, password: password)
                    })
                .then(
                    onSuccess: { pkt in
                        
                        Cache.log.info("LoginVC - login successful for %@", tinode.myUid!)
                        SharedUtils.saveAuthToken(for: userName, token: tinode.authToken, expires: tinode.authTokenExpires)
                        
                        if let token = tinode.authToken {
                            tinode.setAutoLoginWithToken(token: token)
                        }
                        if let ctrl = pkt?.ctrl, ctrl.code >= 300, ctrl.text.contains("validate credentials") {
                            // getting error
                            return nil
                        }
                        // success
                        let data = Data()
                        completion(.success(data))
                        return nil
                        
                    }, onFailure: { err in
                        
                        Cache.log.error("LoginVC - login failed: %@", err.localizedDescription)
                        var toastMsg: String
                        if let tinodeErr = err as? TinodeError {
                            toastMsg = "Tinode: \(tinodeErr.description)"
                        } else {
                            let (hostName, _) = Tinode.getConnectionParams()
                            toastMsg = String(format: NSLocalizedString("Couldn't connect to server at %@: %@", comment: "Error message"), hostName, err.localizedDescription)
                        }
                        DispatchQueue.main.async {
                            UiUtils.showToast(message: toastMsg)
                        }
                        Cache.invalidate()
                        
                        completion(.failure(DataError.serverError))
                        return nil
                        
                    }).thenFinally {
                        
                        // stop loading
                    }
            
            
            } catch {
                
                Cache.log.error("LoginVC - Failed to connect/login to Tinode: %@", error.localizedDescription)
                tinode.logout()
                
                completion(.failure(DataError.networkError))
            }
    }
    
    func startChat(view: UIViewController, topic: String) {
//        UiUtils.routeToBBMessageVC(with: view, forTopic: topic)
    }
    
    func startCall(topic: String) {
        
    }
    
    func saveDeviceToken(token: String, onSuccess: @escaping ((String)) -> Void, onError: @escaping ((String)) -> Void ) {
        Cache.tinode.setDeviceToken(token: token)
    }
    
    func logout() {
        SharedUtils.removeAuthToken()
        Cache.invalidate()
    }
    
    func handleNotification() {
        
    }
    
    
}
