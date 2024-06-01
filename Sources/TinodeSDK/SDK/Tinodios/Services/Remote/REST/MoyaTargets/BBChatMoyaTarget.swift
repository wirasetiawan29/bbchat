//
//  BBChatMoyaTarget.swift
//  BookingUI
//
//  Created by Wira on 26/12/23.
//  Copyright © 2023 Blue Bird Group. All rights reserved.
//

import Foundation
import Moya
import LocationEntity
import UserService
import CoreService

enum BBChatMoyaTarget {
    
    case generateNewToken(clientId: String, clientSecret: String)
    case getParticipant(orderId: String)
    case subscribeToken(
        recipientId: String,
        clientId: String,
        token: String,
        platform: Platform,
        notifPipeline: NotifPipeline)
    case loginOrRegister(userName: String, tinodeId: String, fullName: String)
    
}

extension BBChatMoyaTarget: TargetType {
    
    var baseURL: URL {
        
        switch AppConfiguration.sharedInstance.environment {
        case .dev:
            return URL(string: "https://dev-oapi-chat.bluebird.id")!
        case .staging:
            return URL(string: "https://dev-oapi-chat.bluebird.id")!
        case .production:
            return URL(string: "https://oapi-chat.bluebird.id")!
        case .regress:
            return URL(string: "https://dev-oapi-chat.bluebird.id")!
        }
        
    }
    
    var mockURL: URL {
        
        if let validUrl = URL(string: APIConstants.mrgMockBaseURL) {
            return validUrl
        }
        return NSURL() as URL
    }
    
    var useMockServer: Bool {
        return false
    }
    
    var headers: [String: String]? {
        
        var defaultHeaders = getDefaultHeaders(authenticated: true)
        
        switch self {
        case .getParticipant(_):
            
            defaultHeaders["grpc-metadata-userid"] = Cache.getUserId()
            defaultHeaders["Authorization"] = "Bearer " + (Cache.token?.accessToken ?? "")
            
            return defaultHeaders
            
        case .subscribeToken(_, _, _, _, _):
            
            defaultHeaders["Authorization"] = "Bearer " + (Cache.token?.accessToken ?? "")
            
            return defaultHeaders
            
        case .loginOrRegister(_, _, _):
            
            defaultHeaders["Authorization"] = "Bearer " + (Cache.token?.accessToken ?? "")
            
            return defaultHeaders
            
        default:
            return defaultHeaders
        }
        
    }
    
    var path: String {
        
        switch self {
            
        case .generateNewToken(_, _):
            return "/chat-service/token/auth"
            
        case .subscribeToken(_, _, _, _, _):
            return "/chat-service/save-device-token"
            
        case .getParticipant(let orderId):
            return "/chat-service/participants/\(orderId)"
            
        case .loginOrRegister(_, _, _):
            return "/chat-service/register"
        }
        
        
    }
    
    var method: Moya.Method {
        
        switch self {
            
        case .generateNewToken, .loginOrRegister(_, _, _), .subscribeToken(_, _, _, _, _):
            return .post
            
        case .getParticipant(_):
            return .get
            
        default:
            return .get
        }
    }
    
    var parameterEncoding: ParameterEncoding {
        
        switch self {
            
        case .generateNewToken, .subscribeToken(_, _, _, _, _):
            return JSONEncoding.default
            
        case .getParticipant(_):
            return URLEncoding.default
            
        default:
            return JSONEncoding.default
        }
    }
    
    var parameters: [String: Any] {
        
        switch self {
            
        case .getParticipant(_):
            return [:]
            
        case .subscribeToken(let recipientId,
                             let clientId, 
                             let token,
                             let platform,
                             let notifPipeline):
            
            return [
                "recipient_id": recipientId,
                   "client_id": clientId,
                   "token": token,
                "platform": Int(platform.rawValue),
                "notif_pipeline": notifPipeline.rawValue
            ]
            
            
            
        case .generateNewToken(let clientId, let clientSecret):
            return [ "client_id": clientId,
                     "client_secret": clientSecret,
            ]
            
        case .loginOrRegister(let userName, let tinodeId, let fullName):
            return [ "user_id": userName,
                     "tinode_id": tinodeId,
                     "full_name": fullName
            ]
            
        }
    }
    
    var task: Task {
        return .requestParameters(parameters: parameters, encoding: parameterEncoding)
    }
    
    var sampleData: Data {
        
        switch self {
        case .generateNewToken(_, _):
            return Data()
            
        default:
            return Data()
        }
    }
    
}
