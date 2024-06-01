//
//  BBChatGetParticipant.swift
//  BookingUI
//
//  Created by Wira on 03/01/24.
//  Copyright © 2024 Blue Bird Group. All rights reserved.
//

import Foundation

struct BBChatGetParticipant: Codable {
    let callRoomID, chatRoomID, fullName: String

    enum CodingKeys: String, CodingKey {
        case callRoomID = "call_room_id"
        case chatRoomID = "chat_room_id"
        case fullName = "full_name"
    }
}
