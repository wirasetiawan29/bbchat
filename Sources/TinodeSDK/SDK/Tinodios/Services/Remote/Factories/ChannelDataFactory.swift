//
//  ChanelDataFactory.swift
//  Tinodios
//
//  Created by Djaka Permana on 28/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation
import GRPC
import NIO
import NIOSSL

/**
Responsible for creating data for building Channel.
*/
internal class ChannelDataFactory {

    internal typealias Address = (host: String, port: Int)
    internal static let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    /**
    Creates address for passed `buildLevel`.
    */
    internal static func address(for buildLevel: BuildLevel) -> Address {

        switch buildLevel {
        case .development:
            return ("34.124.216.166", 6969)

        case .staging:
            return ("34.124.216.166", 6969)

        case .production:
            return ("oapi-chat.bluebird.id", 6969)
        }
    }
    
    
    /**
    Creates certificate for passed `buildLevel`.
    */
    internal static func certificates(for buildLevel: BuildLevel) -> [NIOSSLCertificate]? {
        
        // TODO: Update to corresponding `buildLevel` later.
        
        let resourceName = "star.bluebirdgroup.com.ca-bundle"
        let bundle = Bundle(for: self)

        guard let certificateURL = bundle.url(forResource: resourceName, withExtension: "crt"),
              let certificateString = try? String(contentsOf: certificateURL) else {
            return nil
        }

        let certificateBytes: [UInt8] = Array(certificateString.utf8)
        let certificates = try? NIOSSLCertificate.fromPEMBytes(certificateBytes)
        
        return certificates
    }

    /**
    Create `ClientConnection.Configuration instance for given `BuildLevel`
    */
    internal static func configurations(
        for buildLevel: BuildLevel
    ) -> ClientConnection.Configuration {

        let address = ChannelDataFactory.address(for: buildLevel)
        let configuration = ClientConnection.Configuration(
            target: .hostAndPort(address.host, address.port),
            eventLoopGroup: group
        )

        return configuration
    }

}
