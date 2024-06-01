//
//  LoginRegisterEntity.swift
//  Tinodios
//
//  Created by Djaka Permana on 28/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation

public enum ResponseState: String {
    case isSuccess
    case isError
    case unknown
    
    public init(rawValue: String?) {
        switch rawValue {
        case "success":
            self = .isSuccess
        case "error":
            self = .isError
        default:
            self = .unknown
        }
    }
}

public enum ServiceError: Error {
    case alreadyCreated
    case errorParsing
    
    var message: String {
        switch self {
        case .alreadyCreated:
            return "GRPC already created"
        case .errorParsing:
            return "GRPC error parsing"
        default:
            return "GRPC something went wrong"
        }
    }
}

public struct AuthResponse {
    var responseState: ResponseState
    
    init(state_message: String) {
        self.responseState = ResponseState(rawValue: state_message)
    }
    
    internal init?(authResponse: Grpc_RegisterResponse) {
        self.init(
            state_message: authResponse.stateMessage.lowercased()
        )
    }
}
