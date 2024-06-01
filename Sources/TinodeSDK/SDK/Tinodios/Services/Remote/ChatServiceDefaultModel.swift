//
//  ChatServiceDefaultModel.swift
//  Tinodios
//
//  Created by Wira on 03/11/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import UIKit
import Foundation
import TinodeSDK
import PhoneNumberKit
import Combine
import CoreService
import UserService

final class ChatServiceDefaultModel: ChatServiceNetworkModel {
    
    private var cancellables: Set<AnyCancellable> = []
    private let userCacheModel = UserServiceFactory.createUserCacheModel()
    
    public static let buildLevel: BuildLevel = {
        let environment = AppConfiguration.sharedInstance.environment
        
        switch environment {
        case .dev, .staging:
            return .development
        case .production:
            return .production
        case .regress:
            return .staging
        }
    }()
    
    func configureUser(completion: ((Bool) -> Void)? = nil) {
        guard let user = userCacheModel.getCurrentUser() else {
            return
        }

        let username = user.phone.replace(of: "+62", with: "0")
        let password = username
        let fullname = user.name
        let doNothing: (Bool) -> Void = { _ in }

        loginOrRegister(userName: username, password: password, fullName: fullname, completion: completion ?? doNothing)
    }
    
    func loginOrRegister(userName: String, password: String, fullName: String, completion: @escaping (Bool) -> Void) {
        
        doSignInTinode(userName: userName, password: password)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    switch error as? LoginError {
                    case .unauthorize:
                        self.onSignUpTinode(userName: userName, password: password, fullName:fullName) {
                            completion(false)
                        }
                    default:
                        print("SIGN IN TINODE ERROR: ", error.localizedDescription)
                    }
                case .finished:
                    completion(true)
                    print("SIGN IN TINODE: Finish")
                }
            }, receiveValue: {_ in
                self.loginRegisterChatService(userName: userName, password: password, fullName: fullName) {
                    completion(true)
                }
            })
            .store(in: &self.cancellables)
            
    }
    
    
    func loginRegisterChatService(userName: String, password: String, fullName: String, completionLogin: @escaping () -> Void) {
        
        let tinode = Cache.tinode

        let service = AuthService(buildLevel: ChatServiceDefaultModel.buildLevel)
        service.authRequest(userId: userName, tinodeId: tinode.myUid ?? "", fullName: fullName)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.onSignOut()
                case .finished:
                    completionLogin()
                }
            }, receiveValue: { responseState in
                if responseState == .isSuccess {
                    Cache.setUserId(userId: userName)
                    UiUtils.attachToMeTopic(meListener: nil)
                } else {
                    UiUtils.showToast(message: String("Authentication failed"))
                    self.onSignOut()
                }
            })
            .store(in: &self.cancellables)
    }
    
    
    func onSignUpTinode(userName: String, password: String, fullName: String, completion: @escaping() -> Void) {
        let username = userName
        let password = password
        let fullname = fullName
        let avatar: UIImage? = nil
        let creds = [Credential]()
        
        func doSignUp(withPublicCard pub: TheCard, withCredentials creds: [Credential]) -> AnyPublisher<Bool, Error> {
            
            return Future<Bool, Error> { completion in
                
                let tinode = Cache.tinode
                let desc = MetaSetDesc<TheCard, String>(pub: pub, priv: nil)
                desc.attachments = pub.photoRefs

                do {
                    try tinode.connectDefault(inBackground: false)?
                        .thenApply { _ in
                            return Cache.tinode.createAccountBasic(uname: username, pwd: password, login: true, tags: nil, desc: desc, creds: creds)
                        }
                        .thenApply { msg in
                            SharedUtils.saveAuthToken(for: userName, token: tinode.authToken, expires: tinode.authTokenExpires)
                            if let token = tinode.authToken {
                                tinode.setAutoLoginWithToken(token: token)
                            }
                            if let ctrl = msg?.ctrl, ctrl.code >= 300, ctrl.text.contains("validate credentials") {
                                
                                completion(.failure(LoginError.fatalError(ctrl.text)))
                            }

                            completion(.success(true))
                            return nil
                        }
                        .thenCatch { err in
                            if let tinodeErr = err as? TinodeError {
                                if let errorText = tinodeErr.errorDescription, errorText.contains("409") {
                                    completion(.failure(RegisterError.alreadyExist))
                                } else {
                                    completion(.failure(RegisterError.fatalError(tinodeErr.description)))
                                }
                            } else {
                                completion(.failure(RegisterError.fatalError(err.localizedDescription)))
                            }
                            return nil
                        }
                } catch(let error) {
                    Cache.tinode.disconnect()
                    completion(.failure(error))
                }
                
            }.eraseToAnyPublisher()
        }
        
        func onSignUp(withPublicCard pub: TheCard, withCredentials creds: [Credential], completion: @escaping() -> Void) {
            doSignUp(withPublicCard: pub, withCredentials: creds)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        switch error as? RegisterError {
                        case .alreadyExist:
                            //self.loginOrRegister(userName: userName, password: password, fullName: fullName) {}
                            self.loginRegisterChatService(userName: userName, password: password, fullName: fullName) {
                                completion()
                            }
                        default:
                            print("SIGN UP TINODE ERROR: ", error.localizedDescription)
                        }
                    case .finished:
                        print("SIGN UP FINISH")
                    }
                }, receiveValue: { _ in
                    //self.loginOrRegister(userName: userName, password: password, fullName: fullName) {}
                    self.loginRegisterChatService(userName: userName, password: password, fullName: fullName) {
                        completion()
                    }
                })
                .store(in: &self.cancellables)
        }
        
        onSignUp(withPublicCard: TheCard(fn: fullname, avatar: avatar, note: nil), withCredentials: creds, completion: completion)
    }
    
    /// Login to tinode service
    func doSignInTinode(userName: String, password: String) -> AnyPublisher<Bool, Error> {

        return Future<Bool, Error> { completion in
            
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
                                
                                completion(.failure(LoginError.fatalError(ctrl.text)))
                            }

                            completion(.success(true))
                            return nil
                        }, onFailure: { err in

                            Cache.log.error("LoginVC - login failed: %@", err.localizedDescription)

                            if let tinodeErr = err as? TinodeError {
                                Cache.log.error("Login Credentials")
                                
                                if let errorText = tinodeErr.errorDescription, errorText.contains("401") {
                                    completion(.failure(LoginError.unauthorize))
                                } else {
                                    completion(.failure(LoginError.fatalError(err.localizedDescription)))
                                }
                                
                            } else {
                                Cache.log.error("Couldn't connect to server")
                                completion(.failure(LoginError.errorConnection(err.localizedDescription)))
                                Cache.invalidate()
                            }

                            return nil
                        })
                } catch (let error) {
                    completion(.failure(error))
                }
        }.eraseToAnyPublisher()
    }
    
    func getParticipant(orderId: String, completion: @escaping ((String, String, String) -> Void)) {
        let service = ParticipantService(buildLevel: ChatServiceDefaultModel.buildLevel)
        service.getParticipant(orderId: orderId)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Get Participant failed ERROR: ", error.localizedDescription)
                case .finished:
                    print("SIGN UP FINISH")
                }
            }, receiveValue: { response in
                completion(response.chat_room_id, response.call_room_id, response.full_name)
            })
            .store(in: &self.cancellables)
    }
    
    func onSignOut() {
        SharedUtils.removeAuthToken()
        Cache.invalidate()
        Cache.clearUserId()
    }
    
    func subscribeToken(clientId: String, token: String) {
        
        let tinode = Cache.tinode
        if (tinode.myUid == nil) {
            return
        }
        
        guard let recipientId = tinode.myUid else { return }
        let platform = Platform.iOS
        let notifPipeline = NotifPipeline.APNS
        let notifClientId = APIConstants.chatClientID
     
        let service = DeviceTokenService(buildLevel: ChatServiceDefaultModel.buildLevel)
        service.saveToken(recipientId: recipientId, clientId: notifClientId, token: token, platform: platform, notifPipeline: notifPipeline)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("BBChat \(error)")
                case .finished:
                    print("Save token finish")
                }
            }, receiveValue: { response in
                self.setNotifClientIdTinode(clientId: clientId)
                UiUtils.showToast(message: String("Save token successfull"))
            })
            .store(in: &self.cancellables)

    }
    
    func setNotifClientIdTinode(clientId: String) {
        
        let tinode = Cache.tinode
        guard let topic = tinode.getMeTopic() else {
            return
        }
        
        let pub = topic.pub == nil ? TheCard(fn: nil) : topic.pub!.copy()
        if pub.note != clientId {
            pub.note = String(clientId.prefix(UiUtils.kMaxTopicDdescriptionLength))
        }
        UiUtils.setTopicData(forTopic: topic, pub: pub, priv: nil).then(
            onSuccess: { _ in
                return nil
            },
            onFailure: UiUtils.ToastFailureHandler)
        
        return
    }
    
    func handleNotification(_ application: UIApplication.State, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void?) {
        
        let state = application
        guard let topicName = userInfo["topic"] as? String, !topicName.isEmpty else {
            completionHandler(.failed)
            return
        }
        //if state == .background || (state == .inactive && !self.appIsStarting) {
        if state == .background || (state == .inactive) {
            let what = userInfo["what"] as? String
            if what == nil || what == "msg" {
                // New message.
                guard let seq = Int(userInfo["seq"] as? String ?? ""), seq > 0 else {
                    completionHandler(.failed)
                    return
                }
                var keepConnection = false
                if userInfo["webrtc"] != nil {
                    // Video call. Fetch related messages.
                    keepConnection = true
                }
                // Fetch data in the background.
                completionHandler(SharedUtils.fetchData(using: Cache.tinode, for: topicName, seq: seq, keepConnection: keepConnection))
            } else if what == "sub" {
                // New subscription.
                completionHandler(SharedUtils.fetchDesc(using: Cache.tinode, for: topicName))
            } else if what == "read" {
                // Read notification.
                if let seq = Int(userInfo["seq"] as? String ?? ""), seq > 0 {
                    completionHandler(SharedUtils.updateRead(using: Cache.tinode, for: topicName, seq: seq))
                }
            } else {
                Cache.log.error("Invalid 'what' value ['%@'] in push notification for topic '%@'", what!, topicName)
                completionHandler(.failed)
            }
        //} else if state == .inactive && self.appIsStarting {
        } else if state == .inactive {
            // User tapped notification.
            completionHandler(.newData)
        } else {
            // App is active.
            completionHandler(.noData)
        }
    }
    
    func generateSecurityToken(clientId: String, clientSecret: String) {
     
        let service = SecurityService(buildLevel: ChatServiceDefaultModel.buildLevel)
        service.generateNewToken(clientId: clientId, clientSecret: clientSecret)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("error generate token: ", error.localizedDescription)
                case .finished:
                    print("new token finish")
                }
            }, receiveValue: { response in
                
                /// save to cache
                Cache.setToken(value: response)
            })
            .store(in: &self.cancellables)

    }
    
}
