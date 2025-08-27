//
//  GapChartAPITester.swift
//  PhishQS
//
//  Created by Claude on 8/27/25.
//

import Foundation

/// Temporary testing class to discover gap chart API endpoints
class GapChartAPITester {
    
    private let baseURL = "https://api.phish.net/v5"
    private let apiKey = Secrets.value(for: "PhishNetAPIKey")
    
    /// Test potential gap chart API endpoints to see if any exist
    func testGapChartEndpoints(for showDate: String) async {
        let potentialEndpoints = [
            "/setlists/gap-chart/\(showDate).json",
            "/shows/\(showDate)/gaps.json",
            "/setlists/\(showDate)/gaps.json",
            "/gap-chart/\(showDate).json",
            "/setlists/get/\(showDate).json?include_gaps=true",
            "/setlists/show/\(showDate).json?gaps=true"
        ]
        
        print("🔍 Testing Gap Chart API Endpoints for \(showDate)")
        print("=" * 50)
        
        for endpoint in potentialEndpoints {
            await testEndpoint(endpoint)
        }
        
        print("=" * 50)
        print("✅ Gap Chart API endpoint testing complete")
    }
    
    /// Test a specific endpoint and report results
    private func testEndpoint(_ endpoint: String) async {
        guard let url = URL(string: "\(baseURL)\(endpoint)?apikey=\(apiKey)") else {
            print("❌ Invalid URL: \(endpoint)")
            return
        }
        
        do {
            let request = URLRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ \(endpoint) - Invalid response")
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                print("✅ \(endpoint) - SUCCESS! (Response size: \(data.count) bytes)")
                
                // Try to parse as JSON to see structure
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                    if let dict = jsonObject as? [String: Any] {
                        print("   📋 Response keys: \(Array(dict.keys).joined(separator: ", "))")
                        
                        // Look for gap-related fields
                        let gapKeys = dict.keys.filter { key in
                            key.lowercased().contains("gap") || 
                            key.lowercased().contains("last") ||
                            key.lowercased().contains("previous")
                        }
                        
                        if !gapKeys.isEmpty {
                            print("   🎯 Gap-related keys found: \(gapKeys.joined(separator: ", "))")
                        }
                    }
                }
                
            case 403:
                print("🚫 \(endpoint) - 403 Forbidden (may need different permissions)")
                
            case 404:
                print("📭 \(endpoint) - 404 Not Found (endpoint doesn't exist)")
                
            default:
                print("⚠️  \(endpoint) - HTTP \(httpResponse.statusCode)")
            }
            
        } catch {
            print("💥 \(endpoint) - Error: \(error.localizedDescription)")
        }
    }
}

// Extension to repeat strings (for formatting)
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}