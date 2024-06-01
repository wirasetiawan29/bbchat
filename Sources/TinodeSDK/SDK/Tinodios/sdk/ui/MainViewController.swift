//
//  MainViewController.swift
//  Tinodios
//
//  Created by Djaka Permana on 09/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import UIKit
import TinodeSDK
//import TinodiosDB
import PhoneNumberKit
import Combine
import CommonUI
import UserService
import CoreService

enum LoginError: Error {
    case unauthorize
    case fatalError(String)
    case errorConnection(String)
    
    var message: String {
        switch self {
        case .unauthorize:
            return "unauthorize"
        case .fatalError(let error):
            return "Login Error: \(error)"
        case .errorConnection(let error):
            return "Error Connection: \(error)"
        }
    }
}

enum RegisterError: Error {
    case alreadyExist
    case fatalError(String)
    
    var message: String {
        switch self {
        case .alreadyExist:
            return "User already exist"
        case .fatalError(let error):
            return "Error register: \(error)"
        }
    }
}

class MainViewController: BaseViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var orderIdTextField: UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var loginRegisterButton: UIButton!
    @IBOutlet weak var openChatButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var saveTokenButton: UIButton!
    
    private var credMethods: [String] = [Credential.kMethPhone]
    private var avatarReceived: Bool = false
    private var tinode: Tinode!
    static let kTopicUriPrefix = "tinode:topic/"
    private var cancellables: Set<AnyCancellable> = []
    private let chatServiceNetworkModel: ChatServiceNetworkModel = ChatServiceFactory.createChatServiceNetworkModel()
    
    override func viewDidLoad(){
        super.viewDidLoad()

        SharedUtils.removeAuthToken()
        Cache.invalidate()
        
        initialView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title="Main";
    }
    
    private func initialView() {
        usernameTextField.isHidden = false
        usernameTextField.isEnabled = true
        orderIdTextField.isHidden = true
        fullNameTextField.isEnabled = true
        usernameTextField.text = "customer_budi"
        orderIdTextField.text = "room_sore"
        fullNameTextField.text = "Customer Budi"
        
        loginRegisterButton.isEnabled = true
        openChatButton.isEnabled = false
        signOutButton.isEnabled = false
        saveTokenButton.isEnabled = false
        
    }
    
    private func successLoginOrRegisterView() {
        orderIdTextField.isHidden = false
        usernameTextField.isEnabled = false
        loginRegisterButton.isEnabled = false
        openChatButton.isEnabled = true
        signOutButton.isEnabled = true
        saveTokenButton.isEnabled = true
    }
    
    @IBAction func loginRegisterAction(_ sender: Any) {
        
        let userName = usernameTextField.text ?? ""
        let password = userName
        let fullName = fullNameTextField.text ?? ""
        
        if userName.trimmingCharacters(in: .whitespacesAndNewlines).count < 1 {
            UiUtils.showToast(message: String("Minimum character is 1"))
        } else {
            chatServiceNetworkModel.loginOrRegister(userName: userName, password: password, fullName: fullName) {_ in 
                self.successLoginOrRegisterView()
            }
        }
    }
    
    @IBAction func openChat(_ sender: Any) {
        let orderId = orderIdTextField.text ?? ""
        chatServiceNetworkModel.getParticipant(orderId: orderId) { chatroomId, callroomId, fullname in
            self.navigateToChat(chatRoomId: chatroomId, callRoomId: callroomId, fullName: fullname)
        }

    }
    
    private func navigateToChat(chatRoomId: String, callRoomId: String, fullName: String) {
        let messageVC = MessageViewController()
        messageVC.topicName = chatRoomId
        messageVC.callRoomId = callRoomId
        messageVC.fullName = fullName
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    
    @IBAction func saveDeviceToken(_ sender: Any) {
        
        guard let deviceToken = UserServiceFactory.createDeviceTokenModel().getDeviceToken(), !deviceToken.isEmpty else {
            return
        }
        
        chatServiceNetworkModel.subscribeToken(clientId: APIConstants.chatClientID, token: deviceToken)
    }
    
    @IBAction func signOut(_ sender: Any) {
        initialView()
        chatServiceNetworkModel.onSignOut()
    }
    
}
