//
//  SaveDeviceTokenResponse.swift
//  Tinodios
//
//  Created by Bluebird Macbook on 01/11/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation

public struct SaveDeviceTokenResponse {
    var responseState: ResponseState
    
    init(state_message: String) {
        self.responseState = ResponseState(rawValue: state_message)
    }
    
    internal init?(response: Grpc_SaveDeviceTokenResponse) {
        self.init(
            state_message: response.stateMessage.lowercased()
        )
    }
}
