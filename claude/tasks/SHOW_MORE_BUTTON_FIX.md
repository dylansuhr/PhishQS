# Show More Button Cold-Start Stickiness Fix

## Date
December 30, 2025

## Summary
Fixed a ~2 second delay ("stickiness") on the first tap of any "Show More" button after a fresh build. However, this fix reintroduced a previously-solved "blank screen on collapse" bug.

---

## The Original Bug

### Symptoms
- First tap on any "Show More" button after fresh build had ~2 second delay
- Subsequent taps were instant (100% smooth)
- Persisted through app close/reopen
- Only happened once per fresh build/install

### Root Cause
The `withAnimation` block in SwiftUI has significant cold-start overhead on first use. This appears to be Swift runtime initialization for the animation system.

Secondary contributor: `ScrollViewReader` also has lazy initialization overhead.

### Affected Files
- `Features/Dashboard/LongestSongsCard.swift`
- `Features/Dashboard/RarestSongsCard.swift`
- `Features/Dashboard/MostCommonSongsNotPlayedCard.swift`

---

## What We Changed

### Commit
`67a6a8e Fix cold-start stickiness on Show More buttons`

### Changes Made
1. **Removed `ScrollViewReader`** - Was wrapping the card content
2. **Removed `withAnimation`** - Was wrapping `isExpanded.toggle()`
3. **Changed `Button` to `.onTapGesture`** - Slightly snappier response
4. **Removed scroll-to-top logic** - Required `ScrollViewReader` which we removed

### Before (caused stickiness)
```swift
var body: some View {
    ScrollViewReader { proxy in
        MetricCard("...") {
            // content...
            Button(action: {
                hapticGenerator.impactOccurred()
                let willCollapse = isExpanded
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                    if willCollapse {
                        // scroll-to-top logic using proxy.scrollTo()
                    }
                }
            }) {
                // button content
            }
        }
        .id("cardId")
    }
}
```

### After (no stickiness, but no animation)
```swift
var body: some View {
    MetricCard("...") {
        // content...
        HStack { /* button content */ }
            .onTapGesture {
                hapticGenerator.impactOccurred()
                isExpanded.toggle()
            }
    }
    .id("cardId")
}
```

---

## Bug We Reintroduced

### The Blank Screen Bug
When tapping "Show Less" to collapse an expanded card, the screen goes blank momentarily because:
1. The expanded content collapses
2. The user's scroll position is now in empty space below the collapsed card
3. Without scroll-to-top, user sees blank area

### Original Fix (Commit `e603950`)
```
🎯 Implement professional state-driven accordion scroll behavior

- Add state-driven scroll control for all tour statistics cards
- Implement adaptive timing calculation based on content size
- Eliminate blank screen issues when collapsing expanded accordions
- ScrollViewReader with anchor positioning for smooth scrolling
```

The original fix used `ScrollViewReader` with `proxy.scrollTo("cardId", anchor: .top)` to scroll the card back into view after collapsing.

---

## How to Revert to Pre-Fix State

### Target Commit: `8f30d1c`
This is the commit immediately before our stickiness fix. It has:
- Working animations on expand/collapse
- Working scroll-to-top (no blank screen on collapse)
- The ~2 second first-tap stickiness bug

### Option 1: Revert Only Our Commit (Recommended)
This creates a new commit that undoes our changes without affecting other work:
```bash
git revert 67a6a8e
```

### Option 2: Restore Just the Three Files
If other commits have been made since, restore only the affected files:
```bash
git checkout 8f30d1c -- Features/Dashboard/LongestSongsCard.swift
git checkout 8f30d1c -- Features/Dashboard/RarestSongsCard.swift
git checkout 8f30d1c -- Features/Dashboard/MostCommonSongsNotPlayedCard.swift
git add .
git commit -m "Revert Show More button changes to restore collapse behavior"
```

### Option 3: Hard Reset (Destructive - Use with Caution)
Only if no other work has been done since our commit:
```bash
git reset --hard 8f30d1c
git push --force  # DANGER: Rewrites remote history
```

### Commits Reference
| Commit | Description | State |
|--------|-------------|-------|
| `67a6a8e` | Our stickiness fix | No stickiness, but blank screen on collapse, no animation |
| `8f30d1c` | Before our fix | Has stickiness, but animations and collapse work correctly |

---

## Plan Going Forward

### Option A: Revert (Accept Stickiness)
**Pros:** Blank screen bug stays fixed, animations work
**Cons:** ~2 second first-tap delay remains
**Effort:** Minimal - just revert

### Option B: Pre-warm `withAnimation` at App Launch
Try triggering a dummy `withAnimation` call during app startup to warm up the animation system before user interacts.

**Implementation:**
```swift
// In App.swift or TourDashboardView.swift onAppear
@State private var animationWarmup = false

.onAppear {
    // Pre-warm animation system
    withAnimation(.easeInOut(duration: 0.01)) {
        animationWarmup.toggle()
    }
}
```

**Status:** We tried this - it did NOT work. The warmup needs to happen in the same view context as the actual animation.

### Option C: Use `.animation()` Modifier Instead
Replace `withAnimation` block with `.animation()` modifier on the content.

**Implementation:**
```swift
VStack {
    ForEach(...) { ... }
}
.animation(.easeInOut(duration: 0.3), value: isExpanded)
```

**Pros:** May have different initialization characteristics
**Cons:** Less control over what animates
**Status:** Not yet tested

### Option D: Keep Fix, Re-implement Scroll-to-Top Without ScrollViewReader
Use `GeometryReader` and `ScrollView` programmatic scrolling instead.

**Implementation approach:**
1. Use `GeometryReader` to track card position
2. On collapse, use `UIScrollView` or `ScrollViewProxy` alternative
3. May require wrapping parent ScrollView

**Pros:** Fixes both bugs
**Cons:** Complex, may introduce new issues
**Status:** Not yet attempted

### Option E: Hybrid Approach
Keep `ScrollViewReader` but remove only `withAnimation`:

```swift
ScrollViewReader { proxy in
    MetricCard("...") {
        HStack { ... }
            .onTapGesture {
                hapticGenerator.impactOccurred()
                let willCollapse = isExpanded
                isExpanded.toggle()  // No withAnimation

                if willCollapse {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        proxy.scrollTo("cardId", anchor: .top)
                    }
                }
            }
    }
}
```

**Pros:** May fix stickiness while keeping scroll-to-top
**Cons:** `ScrollViewReader` itself may still cause some delay
**Status:** Not yet tested - RECOMMENDED NEXT STEP

---

## Testing Checklist

When testing any fix:

1. [ ] Fresh build (Cmd+Shift+K to clean, then Cmd+R)
2. [ ] First tap on "Show More" - check for stickiness
3. [ ] Second tap - should be smooth
4. [ ] Expand card, scroll down, tap "Show Less" - check for blank screen
5. [ ] Test all three cards: Longest Songs, Biggest Song Gaps, Most Common Not Played
6. [ ] Test after app close/reopen (should still be smooth)

---

## Related Commits

| Commit | Description |
|--------|-------------|
| `67a6a8e` | Our fix - removed ScrollViewReader/withAnimation (current) |
| `8f30d1c` | State before our fix |
| `e603950` | Original blank screen fix (ScrollViewReader + scroll-to-top) |
| `ec3802a` | Earlier attempt: Pre-warm animation system (didn't work) |

---

## Recommendation

**Try Option E first** (Hybrid Approach) - keep `ScrollViewReader` for scroll-to-top but remove `withAnimation`. This tests whether `ScrollViewReader` alone causes stickiness or if it was specifically `withAnimation`.

If Option E still has stickiness, then either:
- Accept the stickiness (revert to `8f30d1c`)
- Accept no animation but fix blank screen with Option D
- Try Option C (`.animation()` modifier)
