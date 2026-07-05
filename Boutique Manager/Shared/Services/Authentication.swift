//
//  Authentication.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 26/06/26.
//

import Foundation
import Supabase

class AuthenticationService {
    static let shared = AuthenticationService()
    
    private init() {}
    
    struct CreateAssociateRequest: Encodable {
        let email: String
        let password: String
        let userProfile: User
    }
    
    /// Calls the Edge Function to create a new associate securely without logging the current manager out
    func createAssociate(user: User, password: String) async throws {
        let request = CreateAssociateRequest(email: user.email, password: password, userProfile: user)
        
        struct EdgeFunctionResponse: Decodable {
            struct AuthUser: Decodable {
                let id: UUID
            }
            let user: AuthUser
        }
        
        do {
            let decoded: EdgeFunctionResponse = try await SupabaseService.shared.client.functions.invoke(
                "create-member",
                options: FunctionInvokeOptions(body: request)
            )
        } catch let FunctionsError.httpError(code, data) {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Edge Function Error (\(code)): \(errorString)")
            } else {
                print("Edge Function Error (\(code)): \(data.count) bytes")
            }
            throw FunctionsError.httpError(code: code, data: data)
        } catch {
            print("Edge Function Unexpected Error: \(error)")
            throw error
        }
    }
    
    /// Standard login for the associate
    func login(email: String, password: String) async throws {
        try await SupabaseService.shared.client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    /// Standard logout
    func logout() async throws {
        try await SupabaseService.shared.client.auth.signOut()
    }
}
