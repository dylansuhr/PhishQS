//
//  PhishQSTests.swift
//  PhishQSTests
//
//  Created by Dylan Suhr on 5/28/25.
//

import Testing
import Foundation
@testable import PhishQS

struct PhishQSTests {

    // MARK: - LatestSetlistViewModel Tests
    
    @Test func testLatestSetlistViewModelSuccess() async throws {
        // Given: Mock API client with test data
        let mockClient = MockPhishAPIClient()
        let viewModel = LatestSetlistViewModel(apiClient: mockClient)
        
        // When: Fetch latest setlist
        await viewModel.fetchLatestSetlist()
        
        // Then: Should have latest show and setlist
        #expect(viewModel.latestShow != nil)
        #expect(viewModel.latestShow?.showdate == "2025-01-28")
        #expect(viewModel.latestShow?.artist_name == "Phish")
        #expect(viewModel.setlistItems.count == 5)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testLatestSetlistViewModelNetworkError() async throws {
        // Given: Mock API client that fails
        let mockClient = MockPhishAPIClient.failing(with: .networkError(URLError(.notConnectedToInternet)))
        let viewModel = LatestSetlistViewModel(apiClient: mockClient)
        
        // When: Fetch latest setlist
        await viewModel.fetchLatestSetlist()
        
        // Then: Should handle error gracefully
        #expect(viewModel.latestShow == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Network error") == true)
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - MonthListViewModel Tests
    
    @Test func testMonthListViewModelSuccess() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        let viewModel = MonthListViewModel(apiClient: mockClient)
        
        // When: Fetch months for 2025
        await viewModel.fetchMonths(for: "2025")
        
        // Then: Should have months from mock data
        #expect(viewModel.months.count == 2) // January and another month from mock data
        #expect(viewModel.months.contains("01")) // January
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - DayListViewModel Tests
    
    @Test func testDayListViewModelSuccess() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        let viewModel = DayListViewModel(apiClient: mockClient)
        
        // When: Fetch days for January 2025
        await viewModel.fetchDays(for: "2025", month: "01")
        
        // Then: Should have days from mock data
        #expect(viewModel.days.count == 2) // 28th and 29th from mock data
        #expect(viewModel.days.contains("28"))
        #expect(viewModel.days.contains("29"))
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - SetlistViewModel Tests
    
    @Test func testSetlistViewModelSuccess() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        let viewModel = SetlistViewModel(apiClient: mockClient)
        
        // When: Fetch setlist for 2025-01-28
        await viewModel.fetchSetlist(for: "2025-01-28")
        
        // Then: Should have formatted setlist
        #expect(viewModel.setlist.count == 5)
        #expect(viewModel.setlist.contains("Sample in a Jar"))
        #expect(viewModel.setlist.contains("Divided Sky ->"))
        #expect(viewModel.setlist.contains("Free"))
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - API Client Tests
    
    @Test func testPhishAPIClientSearchShows() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        
        // When: Search for shows
        let shows = try await mockClient.searchShows(query: "Phish")
        
        // Then: Should return matching shows
        #expect(shows.count > 0)
        #expect(shows.allSatisfy { $0.artist_name == "Phish" })
    }
    
    
    // MARK: - Error Handling Tests
    
    @Test func testAPIClientHandlesInvalidYear() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        
        // When: Fetch shows for invalid year (1999 triggers error in mock)
        do {
            _ = try await mockClient.fetchShows(forYear: "1999")
            #expect(false, "Should have thrown an error")
        } catch {
            // Then: Should throw appropriate error
            #expect(error is APIError)
        }
    }
    
    @Test func testAPIClientHandlesInvalidDate() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        
        // When: Fetch setlist for invalid date (2025-01-01 triggers error in mock)
        do {
            _ = try await mockClient.fetchSetlist(for: "2025-01-01")
            #expect(false, "Should have thrown an error")
        } catch {
            // Then: Should throw appropriate error
            #expect(error is APIError)
        }
    }
}
