//
//  BBChatToken.swift
//  BookingUI
//
//  Created by Wira on 27/12/23.
//  Copyright © 2023 Blue Bird Group. All rights reserved.
//

import Foundation

public struct BBChatToken: Codable {
    
    public let accessToken, refreshToken, expiresIn, refreshExpiresIn: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case refreshExpiresIn = "refresh_expires_in"
    }
}
