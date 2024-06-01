//
//  Service.swift
//  Tinodios
//
//  Created by Djaka Permana on 28/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation

public protocol TinodeService {
    
    /**
    Creates an instance with passed `buildLevel`.
    */
    init(buildLevel: BuildLevel)
    
    /**
    Stops current GRPC stream, if opened. Might take some time to take effect.
    */
    func stopStreaming()
    
    
    /**
    Retries latest valid request, and reopens stream if the last one was stopped.

    - returns: Will return `true` if succeed to retry and `false` if fail to retry latest request
    */
    func retryLatestRequest() -> Bool
}
