import SwiftUI

// View for displaying the latest Phish setlist in a compact format with swipe navigation
struct LatestSetlistView: View {
    @StateObject private var viewModel = LatestSetlistViewModel()
    
    // Gesture state
    @State private var dragOffset: CGSize = .zero
    @State private var isSwipeInProgress = false
    @State private var isNavigating = false
    @State private var dragRotation: Double = 0
    @State private var swipeDirection: SwipeDirection = .none
    
    private let swipeThreshold: CGFloat = 80
    private let maxRotation: Double = 15
    private let dragResistance: CGFloat = 0.7
    
    enum SwipeDirection {
        case left, right, none
    }
    
    // Computed properties for card position and rotation
    private var cardOffsetX: CGFloat {
        if isNavigating {
            switch swipeDirection {
            case .left:
                return -UIScreen.main.bounds.width * 1.5
            case .right:
                return UIScreen.main.bounds.width * 1.5
            case .none:
                return -UIScreen.main.bounds.width * 1.5 // default to left
            }
        } else {
            return dragOffset.width
        }
    }
    
    private var cardRotation: Double {
        if isNavigating {
            switch swipeDirection {
            case .left:
                return -30
            case .right:
                return 30
            case .none:
                return -30
            }
        } else {
            return dragRotation
        }
    }
    
    private var cardOpacity: Double {
        if isNavigating {
            return 0.0 // Fade out completely when exiting
        } else if isSwipeInProgress {
            return 0.95
        } else {
            return 1.0
        }
    }
    
    private var cardScale: Double {
        if isNavigating {
            return 0.8 // Scale down when exiting
        } else if isSwipeInProgress {
            return 0.95
        } else {
            return 1.0
        }
    }
    
    // New card slide-in animation state
    private var shouldSlideIn: Bool {
        return !isNavigating && dragOffset == .zero && !isSwipeInProgress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                // Loading indicator
                HStack {
                    Spacer()
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if viewModel.isRefreshing {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Refreshing...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Show info
                if let show = viewModel.latestShow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(show.showdate)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        // Show venue info if available from setlist items
                        if let firstItem = viewModel.setlistItems.first {
                            let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                            Text("\(firstItem.venue) - \(firstItem.city)\(stateText)")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Full setlist display
                    if !viewModel.setlistItems.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(viewModel.formattedSetlist.enumerated()), id: \.offset) { index, line in
                                if !line.isEmpty {
                                    SetlistLineView(line, fontSize: .caption)
                                }
                            }
                        }
                        .padding(.top, 0)
                    }
                } else if let errorMessage = viewModel.errorMessage {
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
        .offset(x: cardOffsetX, y: 0)
        .rotationEffect(.degrees(cardRotation))
        .opacity(cardOpacity)
        .scaleEffect(cardScale)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isNavigating)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragRotation)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isNavigating {
                        // Tinder-style horizontal-only movement with resistance
                        let horizontalMovement = value.translation.width * dragResistance
                        
                        // Calculate rotation based on drag distance (Tinder-style)
                        let rotationAmount = (horizontalMovement / UIScreen.main.bounds.width) * maxRotation
                        
                        // Set drag offset to horizontal only, always zero height
                        dragOffset = CGSize(width: horizontalMovement, height: 0)
                        dragRotation = rotationAmount
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
                    guard !isNavigating else { return }
                    
                    let horizontalMovement = value.translation.width
                    let velocity = value.velocity.width
                    
                    // Velocity-based threshold (Tinder-style)
                    let velocityThreshold: CGFloat = 500
                    let shouldSwipe = abs(horizontalMovement) > swipeThreshold || abs(velocity) > velocityThreshold
                    
                    // Handle swipe gestures
                    if shouldSwipe {
                        if horizontalMovement < 0 {
                            // Swipe left - go to previous show (chronologically earlier)
                            if viewModel.canNavigatePrevious {
                                swipeDirection = .left
                                
                                // Trigger smooth slide-off animation
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                                    isNavigating = true
                                }
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // Navigate after animation starts
                                Task {
                                    await viewModel.navigateToPreviousShow()
                                    // Slide new content in from right with smoother transition
                                    await MainActor.run {
                                        // Brief delay to ensure content has updated
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                isNavigating = false
                                                dragOffset = .zero
                                                dragRotation = 0
                                                isSwipeInProgress = false
                                                swipeDirection = .none
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Reset if can't navigate
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    dragOffset = .zero
                                    dragRotation = 0
                                    isSwipeInProgress = false
                                    swipeDirection = .none
                                }
                            }
                        } else {
                            // Swipe right - go to next show (chronologically later)
                            if viewModel.canNavigateNext {
                                swipeDirection = .right
                                
                                // Trigger smooth slide-off animation
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                                    isNavigating = true
                                }
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // Navigate after animation starts
                                Task {
                                    await viewModel.navigateToNextShow()
                                    // Slide new content in from left with smoother transition
                                    await MainActor.run {
                                        // Brief delay to ensure content has updated
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                isNavigating = false
                                                dragOffset = .zero
                                                dragRotation = 0
                                                isSwipeInProgress = false
                                                swipeDirection = .none
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Reset if can't navigate
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    dragOffset = .zero
                                    dragRotation = 0
                                    isSwipeInProgress = false
                                    swipeDirection = .none
                                }
                            }
                        }
                    } else {
                        // Snap back to center (Tinder-style)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            dragOffset = .zero
                            dragRotation = 0
                            isSwipeInProgress = false
                            swipeDirection = .none
                        }
                    }
                }
        )
        .onAppear {
            viewModel.fetchLatestSetlist()
        }
    }
}

#Preview {
    LatestSetlistView()
} 
