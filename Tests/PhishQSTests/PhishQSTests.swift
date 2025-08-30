//
//  PhishQSTests.swift
//  PhishQSTests
//
//  Created by Dylan Suhr on 5/28/25.
//

import XCTest
import Foundation
@testable import PhishQS

class PhishQSTests: XCTestCase {

    // MARK: - LatestSetlistViewModel Tests
    
    func testLatestSetlistViewModelSuccess() async throws {
        // Given: Mock API client with test data
        let mockClient = MockPhishAPIClient()
        let viewModel = LatestSetlistViewModel(apiClient: mockClient)
        
        // When: Fetch latest setlist
        await viewModel.fetchLatestSetlist()
        
        // Then: Should have latest show and setlist
        XCTAssertNotNil(viewModel.latestShow)
        XCTAssertEqual(viewModel.latestShow?.showdate, "2025-01-28")
        XCTAssertEqual(viewModel.latestShow?.artist_name, "Phish")
        XCTAssertEqual(viewModel.setlistItems.count, 5)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLatestSetlistViewModelNetworkError() async throws {
        // Given: Mock API client that fails
        let mockClient = MockPhishAPIClient.failing(with: .networkError(URLError(.notConnectedToInternet)))
        let viewModel = LatestSetlistViewModel(apiClient: mockClient)
        
        // When: Fetch latest setlist
        await viewModel.fetchLatestSetlist()
        
        // Then: Should handle error gracefully
        XCTAssertNil(viewModel.latestShow)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Network error") == true)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - MonthListViewModel Tests
    
    func testMonthListViewModelSuccess() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        let viewModel = MonthListViewModel(apiClient: mockClient)
        
        // When: Fetch months for 2025
        await viewModel.fetchMonths(for: "2025")
        
        // Then: Should have months from mock data
        XCTAssertEqual(viewModel.months.count, 2) // January and another month from mock data
        XCTAssertTrue(viewModel.months.contains("01")) // January
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - DayListViewModel Tests
    
    func testDayListViewModelSuccess() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        let viewModel = DayListViewModel(apiClient: mockClient)
        
        // When: Fetch days for January 2025
        await viewModel.fetchDays(for: "2025", month: "01")
        
        // Then: Should have days from mock data
        XCTAssertEqual(viewModel.days.count, 2) // 28th and 29th from mock data
        XCTAssertTrue(viewModel.days.contains("28"))
        XCTAssertTrue(viewModel.days.contains("29"))
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - SetlistViewModel Tests
    
    func testSetlistViewModelSuccess() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        let viewModel = SetlistViewModel(apiClient: mockClient)
        
        // When: Fetch setlist for 2025-01-28
        await viewModel.fetchSetlist(for: "2025-01-28")
        
        // Then: Should have formatted setlist
        XCTAssertEqual(viewModel.setlist.count, 5)
        XCTAssertTrue(viewModel.setlist.contains("Sample in a Jar"))
        XCTAssertTrue(viewModel.setlist.contains("Divided Sky ->"))
        XCTAssertTrue(viewModel.setlist.contains("Free"))
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - API Client Tests
    
    func testPhishAPIClientSearchShows() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        
        // When: Search for shows
        let shows = try await mockClient.searchShows(query: "Phish")
        
        // Then: Should return matching shows
        XCTAssertGreaterThan(shows.count, 0)
        XCTAssertTrue(shows.allSatisfy { $0.artist_name == "Phish" })
    }
    
    
    // MARK: - Error Handling Tests
    
    func testAPIClientHandlesInvalidYear() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        
        // When: Fetch shows for invalid year (1999 triggers error in mock)
        do {
            _ = try await mockClient.fetchShows(forYear: "1999")
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Should throw appropriate error
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testAPIClientHandlesInvalidDate() async throws {
        // Given: Mock API client
        let mockClient = MockPhishAPIClient()
        
        // When: Fetch setlist for invalid date (2025-01-01 triggers error in mock)
        do {
            _ = try await mockClient.fetchSetlist(for: "2025-01-01")
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Should throw appropriate error
            XCTAssertTrue(error is APIError)
        }
    }
}
