//
//  BBChatSubsToken.swift
//  BookingUI
//
//  Created by Wira on 03/01/24.
//  Copyright © 2024 Blue Bird Group. All rights reserved.
//

import Foundation
struct BBChatSubsToken: Codable {
    let stateMessage: String

    enum CodingKeys: String, CodingKey {
        case stateMessage = "state_message"
    }
}
