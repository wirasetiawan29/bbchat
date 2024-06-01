//
//  ChatServiceFactory.swift
//  Tinodios
//
//  Created by Wira on 03/11/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation


public final class ChatServiceFactory {
    
    public static func createChatServiceNetworkModel() -> ChatServiceNetworkModel {
        
        // For GRPC Service uncomment this line
        // return ChatServiceDefaultModel()
         
        return ChatServiceDefaultModelREST()
    }
}
