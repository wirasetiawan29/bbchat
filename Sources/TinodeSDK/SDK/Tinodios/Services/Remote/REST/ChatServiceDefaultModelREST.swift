//
//  ChatServiceDefaultModelREST.swift
//  BookingUI
//
//  Created by Wira on 26/12/23.
//  Copyright © 2023 Blue Bird Group. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import ObjectMapper
import BookingEntity
import ProductEntity
import UserEntity
import ProductService
import UserService
import Combine
import TinodeSDK
import UIKit
import CoreService

final class ChatServiceDefaultModelREST: ChatServiceNetworkModel {
    
    private var cancellables: Set<AnyCancellable> = []
    private let userCacheModel = UserServiceFactory.createUserCacheModel()
    private let disposeBag = DisposeBag()
    
    // MARK: - Public Properties
    
    var provider: MoyaProvider<BBChatMoyaTarget>
    
    // MARK: - Public Methods
    
    init(provider: MoyaProvider<BBChatMoyaTarget> = .defaultProvider()) {
        self.provider = provider
    }
    
    // MARK: GENERATE NEW TOKEN

    func generateSecurityToken(clientId: String, clientSecret: String) {
        retrieveSecurityToken(clientId: clientId, clientSecret: clientSecret)
            .subscribe(onNext: { [weak self] token in
                let accessToken = token.accessToken ?? ""
                let expiresIn = Int64(token.expiresIn ?? "0") ?? 0
                let refreshToken = token.refreshToken ?? ""
                let refreshExpiresIn = Int64(token.refreshExpiresIn ?? "0") ?? 0
                
                Cache.setToken(value: Token(accessToken: accessToken,
                                            expiredIn: expiresIn,
                                            refreshToken: refreshToken,
                                            refreshExpiresIn: refreshExpiresIn))
                
            }, onError: { [weak self] error in
                print(error)
            })
            .disposed(by: disposeBag)
    }

    
    private func retrieveSecurityToken(clientId: String, clientSecret: String) -> Observable<BBChatToken> {
        return provider.rx
            .request(BBChatMoyaTarget.generateNewToken(clientId: clientId, clientSecret: clientSecret))
            .asObservable()
            .map(BBChatToken.self)
    }
    
    // MARK: LOGIN / REGISTER
    
    func configureUser(completion: ((Bool) -> Void)? = nil) {
        guard let user = userCacheModel.getCurrentUser() else {
            return
        }

        let phone = user.phone.replace(of: "+62", with: "0")
        let username = phone.replace(of: "+", with: "")
        let password = username
        let fullname = user.name
        let doNothing: (Bool) -> Void = { _ in }
        
        if (Cache.tinode.isConnectionAuthenticated && Cache.alreadyRegistered) {
            completion?(true)
            return
        }

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
    
    private func loginRegisterChatService(userName: String, password: String, fullName: String, completionLogin: @escaping () -> Void) {
        
        let tinode = Cache.tinode
        retrieveLoginOrRegister(recipientId: userName, tinodeId: tinode.myUid ?? "", fullName: fullName)
            .subscribe(onNext: {[weak self] (state: BBChatSubsToken) in
                
                Cache.setUserId(userId: userName)
                Cache.setAlreadyRegistered(value: true)
                UiUtils.attachToMeTopic(meListener: nil)
                
                completionLogin()
                
            }, onError: {[weak self] (error: Error) in
                
                Cache.setAlreadyRegistered(value: false)
                self?.onSignOut()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func retrieveLoginOrRegister(
        recipientId: String,
        tinodeId: String,
        fullName: String
    ) -> Observable<BBChatSubsToken> {
        return provider.rx
            .request(BBChatMoyaTarget.loginOrRegister(
                userName: recipientId,
                tinodeId: tinodeId,
                fullName: fullName))
            .asObservable()
            .map(BBChatSubsToken.self)
    }
    
    
    // MARK: SAVE DEVICE TOKEN
    
    func subscribeToken(clientId: String, token: String) {
        
        let tinode = Cache.tinode
        if (tinode.myUid == nil) {
            return
        }
        
        guard let recipientId = tinode.myUid else { return }
        let platform = Platform.iOS
        let notifPipeline = NotifPipeline.APNS
        let notifClientId = APIConstants.chatClientID
        
        retrieveToken(recipientId: recipientId, clientId: notifClientId, token: token, platform: platform, notifPipeline: notifPipeline)
            .subscribe(onNext: {[weak self] (state: BBChatSubsToken) in
                
                if state.stateMessage == "success" {
                    self?.setNotifClientIdTinode(clientId: clientId)
                } else {
                    print(state.stateMessage)
                }
               
                
            }, onError: {[weak self] (error: Error) in
               print(error)
            })
            .disposed(by: disposeBag)

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
    
    private func retrieveToken(
        recipientId: String,
        clientId: String,
        token: String,
        platform: Platform,
        notifPipeline: NotifPipeline
    ) -> Observable<BBChatSubsToken> {
        return provider.rx
            .request(BBChatMoyaTarget.subscribeToken(
                recipientId: recipientId,
                clientId: clientId,
                token: token,
                platform: platform,
                notifPipeline: notifPipeline))
            .asObservable()
            .map(BBChatSubsToken.self)
    }
    
    
    
    // MARK: GET PARTICIPANT
    
    func getParticipant(orderId: String, completion: @escaping ((String, String, String) -> Void)) {
        
        retrieveParticipant(orderId: orderId)
            .subscribe(onNext: {[weak self] (participant: BBChatGetParticipant) in
                completion(participant.chatRoomID, participant.callRoomID, participant.fullName)
            }, onError: {[weak self] (error: Error) in
                completion("", "", "")
               print(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func retrieveParticipant(orderId: String) -> Observable<BBChatGetParticipant> {
        return provider.rx
            .request(BBChatMoyaTarget.getParticipant(orderId: orderId))
            .asObservable()
            .map(BBChatGetParticipant.self)
    }
    
    // MARK: LOGOUT
    
    func onSignOut() {
        SharedUtils.removeAuthToken()
        Cache.invalidate()
        Cache.clearUserId()
    }
    
    // MARK: HANDLE NOTIFICATION
    
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
    
}
