//
//  RoomResponse.swift
//  Tinodios
//
//  Created by Djaka Permana on 28/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation

public struct CreateRoomResponse {
    var state_message: String
    
    init(state_message: String) {
        self.state_message = state_message
    }
    
    internal init?(createRoomResponse: Grpc_CreateRoomResponse) {
        self.init(
            state_message: createRoomResponse.stateMessage
        )
    }
}
