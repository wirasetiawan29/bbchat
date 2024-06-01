//
//  AuthService.swift
//  Tinodios
//
//  Created by Djaka Permana on 29/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation
import GRPC
import NIO
import NIOHPACK
import Combine

protocol AuthServiceProtocol {
    func authRequest(userId: String, tinodeId: String, fullName: String) -> AnyPublisher<ResponseState, Error>
}

public class AuthService: TinodeService {
    
    typealias GetAuthenticationCall = UnaryCall<Grpc_RegisterRequest, Grpc_RegisterResponse>
    
    private let grpcService: Grpc_ChatServiceClient
    private var latestRequest: Grpc_RegisterRequest?
    private var currentCaller: GetAuthenticationCall?
    private var callOptions : CallOptions
    
    public required init(buildLevel: BuildLevel) {
        let configuration = ChannelDataFactory.configurations(for: buildLevel)
        let connection = ClientConnection(configuration: configuration)
        let headers = NIOHPACK.HPACKHeaders(
            [
                ("Authorization", "Bearer " + (Cache.token?.accessToken ?? ""))
            ]
        )

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

extension AuthService: AuthServiceProtocol {
    func authRequest(userId: String, tinodeId: String, fullName: String) -> AnyPublisher<ResponseState, Error> {
        
        return Future<ResponseState, Error> { completion in
            
            var request = Grpc_RegisterRequest()
            request.userID = userId
            request.tinodeID = tinodeId
            request.fullName = fullName
            guard self.currentCaller == nil else {
                return completion(.failure(ServiceError.alreadyCreated))
            }
            
            self.currentCaller = self.grpcService.register(request)
            self.currentCaller?.response.whenComplete ({ result in
                switch result {
                case .success(let response):
                    guard let authResponse = AuthResponse(authResponse: response) else {
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
