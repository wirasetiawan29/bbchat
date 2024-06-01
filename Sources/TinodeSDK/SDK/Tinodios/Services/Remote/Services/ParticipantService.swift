//
//  ParticipantService.swift
//  Tinodios
//
//  Created by Djaka Permana on 01/09/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation
import GRPC
import NIO
import NIOHPACK
import Combine

protocol ParticipantServiceProtocol {
    func getParticipant(orderId: String) -> AnyPublisher<ParticipantResponse, Error>
}

public class ParticipantService: TinodeService {
    
    typealias GetParticipantCall = UnaryCall<Grpc_GetParticipantsRequest, Grpc_GetParticipantsResponse>
    
    private let grpcService: Grpc_ChatServiceClient
    private var latestRequest: Grpc_GetParticipantsRequest?
    private var currentCaller: GetParticipantCall?
    private var callOptions : CallOptions
    
    public required init(buildLevel: BuildLevel) {
        let configuration = ChannelDataFactory.configurations(for: buildLevel)
        let connection = ClientConnection(configuration: configuration)
        let headers = NIOHPACK.HPACKHeaders(
            [ 
                ("userId", Cache.getUserId()),
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

extension ParticipantService: ParticipantServiceProtocol {
    func getParticipant(orderId: String) -> AnyPublisher<ParticipantResponse, Error> {
        
        return Future<ParticipantResponse, Error> { completion in
            
            var request = Grpc_GetParticipantsRequest()
            request.orderID = orderId
            
            guard self.currentCaller == nil else {
                return completion(.failure(ServiceError.alreadyCreated))
            }
            
            self.currentCaller = self.grpcService.getParticipants(request)
            self.currentCaller?.response.whenComplete ({ result in
                switch result {
                case .success(let response):
                    guard let participant = ParticipantResponse(createParticipantResponse: response) else {
                        return completion(.failure(ServiceError.errorParsing))
                    }
                    
                    /// change this until response backend is better result
                    completion(.success(participant))
                    
                case .failure(let failure):
                    completion(.failure(failure))
                }

                self.resetCaller()
            })
        }.eraseToAnyPublisher()
    }
}
