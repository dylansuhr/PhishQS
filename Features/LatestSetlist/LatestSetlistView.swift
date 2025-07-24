import SwiftUI

// View for displaying the latest Phish setlist in a compact format
struct LatestSetlistView: View {
    @StateObject private var viewModel = LatestSetlistViewModel()
    
    // Gesture state
    @State private var dragOffset: CGSize = .zero
    @State private var isSwipeInProgress = false
    @State private var swipeDirection: SwipeDirection = .none
    
    // 2-card system state
    @State private var showNextCard = false
    @State private var nextCardContent: (Show, [SetlistItem])? = nil
    @State private var currentCardOffset: CGFloat = 0
    @State private var nextCardOffset: CGFloat = 0
    
    private let swipeThreshold: CGFloat = 80
    
    enum SwipeDirection {
        case left, right, none
    }
    
    // Computed properties for 2-card system
    private var finalCurrentCardOffset: CGFloat {
        return dragOffset.width + currentCardOffset
    }
    
    private var finalNextCardOffset: CGFloat {
        return nextCardOffset
    }
    
    
    var body: some View {
        ZStack {
            // Current card
            CardContentView(
                show: viewModel.latestShow,
                setlistItems: viewModel.setlistItems,
                isLoading: viewModel.isLoading,
                isRefreshing: viewModel.isRefreshing,
                errorMessage: viewModel.errorMessage
            )
            .offset(x: finalCurrentCardOffset, y: 0)
            
            // Next card (only visible during transitions)
            if showNextCard, let nextContent = nextCardContent {
                CardContentView(
                    show: nextContent.0,
                    setlistItems: nextContent.1,
                    isLoading: false,
                    isRefreshing: false,
                    errorMessage: nil
                )
                .offset(x: finalNextCardOffset, y: 0)
            }
        }
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentCardOffset)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: nextCardOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !showNextCard {
                        let horizontalMovement = value.translation.width
                        
                        // Prevent right drag when at latest show
                        if horizontalMovement > 0 && !viewModel.canNavigateNext {
                            return
                        }
                        
                        // Set drag offset to horizontal only, always zero height
                        dragOffset = CGSize(width: horizontalMovement, height: 0)
                        isSwipeInProgress = abs(horizontalMovement) > 15
                        
                        // Track swipe direction for animation
                        if horizontalMovement < -20 {
                            swipeDirection = .left
                        } else if horizontalMovement > 20 {
                            swipeDirection = .right
                        } else {
                            swipeDirection = .none
                        }
                    }
                }
                .onEnded { value in
                    guard !showNextCard else { return }
                    
                    let horizontalMovement = value.translation.width
                    let velocity = value.velocity.width
                    
                    // Velocity-based threshold
                    let velocityThreshold: CGFloat = 500
                    let shouldSwipe = abs(horizontalMovement) > swipeThreshold || abs(velocity) > velocityThreshold
                    
                    // Handle swipe gestures
                    if shouldSwipe {
                        if horizontalMovement < 0 {
                            // Swipe left - go to previous show
                            if viewModel.canNavigatePrevious {
                                swipeDirection = .left
                                performSwipeNavigation(direction: .left)
                            } else {
                                resetSwipe()
                            }
                        } else {
                            // Swipe right - go to next show
                            if viewModel.canNavigateNext {
                                swipeDirection = .right
                                performSwipeNavigation(direction: .right)
                            } else {
                                resetSwipe()
                            }
                        }
                    } else {
                        resetSwipe()
                    }
                }
        )
        .onAppear {
            viewModel.fetchLatestSetlist()
        }
    }
    
    // Clean navigation function with proper state management
    private func performSwipeNavigation(direction: SwipeDirection) {
        Task {
            // Get next show data first
            if direction == .left {
                await viewModel.navigateToPreviousShow()
            } else {
                await viewModel.navigateToNextShow()
            }
            
            await MainActor.run {
                // Set up next card with new content, positioned off-screen
                nextCardContent = (viewModel.latestShow!, viewModel.setlistItems)
                nextCardOffset = direction == .left ? UIScreen.main.bounds.width * 1.5 : -UIScreen.main.bounds.width * 1.5
                showNextCard = true
                
                // Animate both cards
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    // Current card slides off in swipe direction
                    currentCardOffset = direction == .left ? -UIScreen.main.bounds.width * 1.5 : UIScreen.main.bounds.width * 1.5
                    // Next card slides in from opposite side to center
                    nextCardOffset = 0
                }
            }
            
            // Wait for animation to complete
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            await MainActor.run {
                // CRITICAL: Disable animations entirely for cleanup
                var transaction = Transaction()
                transaction.disablesAnimations = true
                
                withTransaction(transaction) {
                    showNextCard = false
                    nextCardContent = nil
                    currentCardOffset = 0
                    nextCardOffset = 0
                    dragOffset = .zero
                    isSwipeInProgress = false
                    swipeDirection = .none
                }
            }
        }
    }
    
    // Clean reset function
    private func resetSwipe() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            dragOffset = .zero
            isSwipeInProgress = false
            swipeDirection = .none
        }
    }
}

// Reusable card content component for 2-card system
struct CardContentView: View {
    let show: Show?
    let setlistItems: [SetlistItem]
    let isLoading: Bool
    let isRefreshing: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Show info
            if let show = show {
                VStack(alignment: .leading, spacing: 4) {
                    Text(show.showdate)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Show venue info if available from setlist items
                    if let firstItem = setlistItems.first {
                        let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                        Text("\(firstItem.venue) - \(firstItem.city)\(stateText)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                // Full setlist display
                if !setlistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(StringFormatters.formatSetlist(setlistItems).enumerated()), id: \.offset) { index, line in
                            if !line.isEmpty {
                                SetlistLineView(line, fontSize: .caption)
                            }
                        }
                    }
                    .padding(.top, 0)
                }
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("No recent shows available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    LatestSetlistView()
} 
