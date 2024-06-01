//
//  TokenService.swift
//  BookingUI
//
//  Created by Bluebird Macbook on 11/12/23.
//  Copyright © 2023 Blue Bird Group. All rights reserved.
//

import Foundation
import GRPC
import NIO
import NIOHPACK
import Combine

protocol SecurityServiceProtocol {
    func generateNewToken(
        clientId: String,
        clientSecret: String
    ) -> AnyPublisher<Token, Error>
}

public class SecurityService: TinodeService {
    
    typealias SecurityCall = UnaryCall<Grpc_GenerateTokenRequest, Grpc_GenerateTokenResponse>
    
    private let grpcService: Grpc_ChatServiceClient
    private var latestRequest: Grpc_GenerateTokenRequest?
    private var currentCaller: SecurityCall?
    private var callOptions : CallOptions
    
    public required init(buildLevel: BuildLevel) {
        let configuration = ChannelDataFactory.configurations(for: buildLevel)
        let connection = ClientConnection(configuration: configuration)
        let headers = NIOHPACK.HPACKHeaders()

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

extension SecurityService: SecurityServiceProtocol {
    func generateNewToken(
        clientId: String,
        clientSecret: String
    ) -> AnyPublisher<Token, Error> {
        
        return Future<Token, Error> { completion in
            
            var request = Grpc_GenerateTokenRequest()
            request.clientID = clientId
            request.clientSecret = clientSecret
        
            guard self.currentCaller == nil else {
                return completion(.failure(ServiceError.alreadyCreated))
            }
            
            self.currentCaller = self.grpcService.generateToken(request)
            self.currentCaller?.response.whenComplete ({ result in
                switch result {
                case .success(let response):
                    guard let res = Token(response: response) else {
                        return completion(.failure(ServiceError.errorParsing))
                    }
                    
                    /// change this until response backend is better result
                    completion(.success(res))
                    
                case .failure(let failure):
                    completion(.failure(failure))
                }

                self.resetCaller()
            })
        }.eraseToAnyPublisher()
    }
}

