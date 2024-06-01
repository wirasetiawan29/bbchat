//
//  GenerateTokenResponse.swift
//  BookingUI
//
//  Created by Bluebird Macbook on 11/12/23.
//  Copyright © 2023 Blue Bird Group. All rights reserved.
//

import Foundation

public struct Token {
    public var accessToken: String
    public var expiredIn: Int64
    public var refreshToken: String
    public var refreshExpiresIn: Int64
    
    public init(accessToken: String, expiredIn: Int64, refreshToken: String, refreshExpiresIn: Int64) {
        self.accessToken = accessToken
        self.expiredIn = expiredIn
        self.refreshToken = refreshToken
        self.refreshExpiresIn = refreshExpiresIn
    }
    
    internal init?(response: Grpc_GenerateTokenResponse) {
        self.init(
            accessToken: response.accessToken,
            expiredIn: response.expiresIn,
            refreshToken: "",
            refreshExpiresIn: 0
        )
    }
}
