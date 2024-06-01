//
//  ErrorFactory.swift
//  Tinodios
//
//  Created by Djaka Permana on 28/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation

internal class ErrorFactory {

    static private let errorDomain = "GRPC.ErrorFactory"
    static private let errorCode = -1010
    
    static internal func uncreachableServerError() -> Error {
        
        return NSError(
            domain: errorDomain,
            code: errorCode,
            userInfo: [
                NSLocalizedDescriptionKey: "Failed to reach server, please try again later."
            ])
    }
}
