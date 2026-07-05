import Foundation
import Observation
import Supabase

@Observable
class AuthManager {
    static let shared = AuthManager()
    
    var currentUser: User? = nil
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    var isLoading = false
    var errorMessage: String? = nil
    
    private init() {}
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthenticationService.shared.login(email: email, password: password)
            let session = try await SupabaseService.shared.client.auth.session
            let authUserID = session.user.id
            
            // Fetch User profile
            let user: User = try await SupabaseService.shared.client
                .from("User")
                .select()
                .eq("id", value: authUserID)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = user
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("Login error: \(error)")
        }
    }
    
    func logout() async {
        isLoading = true
        do {
            try await AuthenticationService.shared.logout()
            await MainActor.run {
                self.currentUser = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Logout error: \(error)")
        }
    }
}
