//
//  DeviceTokenService.swift
//  Tinodios
//
//  Created by Bluebird Macbook on 01/11/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation
import GRPC
import NIO
import NIOHPACK
import Combine

protocol DeviceTokenServiceProtocol {
    func saveToken(
        recipientId: String,
        clientId: String,
        token: String,
        platform: Platform,
        notifPipeline: NotifPipeline
    ) -> AnyPublisher<ResponseState, Error>
}

public class DeviceTokenService: TinodeService {
    
    typealias SaveDeviceTokenCall = UnaryCall<Grpc_SaveDeviceTokenRequest, Grpc_SaveDeviceTokenResponse>
    
    private let grpcService: Grpc_ChatServiceClient
    private var latestRequest: Grpc_SaveDeviceTokenRequest?
    private var currentCaller: SaveDeviceTokenCall?
    private var callOptions : CallOptions
    
    public required init(buildLevel: BuildLevel) {
        let configuration = ChannelDataFactory.configurations(for: buildLevel)
        let connection = ClientConnection(configuration: configuration)
        var headers = NIOHPACK.HPACKHeaders()
        headers.add(name: "Authorization", value: "Bearer " + (Cache.token?.accessToken ?? ""))

        callOptions = CallOptions(
            customMetadata: headers,
            timeLimit: TimeLimit.timeout(TimeAmount.nanoseconds(.max))
        )

        grpcService = Grpc_ChatServiceClient(
            channel: connection,
            defaultCallOptions: callOptions
        )
    }
    
    public func stopStreaming() {
        fatalError()
    }
    
    public func retryLatestRequest() -> Bool {
        fatalError()
    }
    
    private func resetCaller() {
        
        currentCaller?.cancel(promise: nil)
        currentCaller = nil
    }
}

extension DeviceTokenService: DeviceTokenServiceProtocol {
    func saveToken(
        recipientId: String,
        clientId: String,
        token: String,
        platform: Platform,
        notifPipeline: NotifPipeline
    ) -> AnyPublisher<ResponseState, Error> {
        
        return Future<ResponseState, Error> { completion in
            
            var request = Grpc_SaveDeviceTokenRequest()
            request.recipientID = recipientId
            request.clientID = clientId
            request.token = token
            request.platform = platform.rawValue
            request.notifPipeline = notifPipeline.rawValue
        
            guard self.currentCaller == nil else {
                return completion(.failure(ServiceError.alreadyCreated))
            }
            
            self.currentCaller = self.grpcService.saveDeviceToken(request)
            self.currentCaller?.response.whenComplete ({ result in
                switch result {
                case .success(let response):
                    guard let _ = SaveDeviceTokenResponse(response: response) else {
                        return completion(.failure(ServiceError.errorParsing))
                    }
                    
                    /// change this until response backend is better result
                    completion(.success(.isSuccess))
                    
                case .failure(let failure):
                    completion(.failure(failure))
                }

                self.resetCaller()
            })
        }.eraseToAnyPublisher()
    }
}

