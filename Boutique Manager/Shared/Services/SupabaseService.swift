//
//  SupabaseService.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 26/06/26.
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient
    
    private init() {
        guard let fileURL = Bundle.main.url(forResource: "Keys", withExtension: "txt"),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            fatalError("Could not find Keys.txt or read its contents. Make sure it is added to the target's Copy Bundle Resources phase.")
        }
        
        var anonKey = ""
        var projectUrl = ""
        
        for line in content.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                if parts[0] == "anon_key" {
                    anonKey = parts[1]
                } else if parts[0] == "project_url" {
                    projectUrl = parts[1]
                }
            }
        }
        
        var urlString = projectUrl
        if !urlString.hasPrefix("http") {
            urlString = "https://\(projectUrl).supabase.co"
        }
        
        guard let url = URL(string: urlString) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
