import SwiftUI
import UIKit

// iOS 16 back-deploys: the floor is iOS 16.0, and these are the iOS 17+ (and one 16.4+) APIs the
// app uses. Each falls back where the OS lacks it; on newer systems the behavior is unchanged.
// When the floor reaches iOS 17, delete this file and rename the call sites back (`onChange16`
// to `onChange`, `A11y` to `AccessibilityNotification`, `Haptic` to `sensoryFeedback`, and the
// scroll helpers to the real modifiers).

extension View {
    /// `onChange(of:initial:_:)` (iOS 17+) on the iOS 16 runtime: `(old, new)` on every change,
    /// and `(value, value)` once at appear when `initial` is true.
    @ViewBuilder func onChange16<V: Equatable>(of value: V, initial: Bool = false, _ action: @escaping (_ old: V, _ new: V) -> Void) -> some View {
        if #available(iOS 17, *) {
            onChange(of: value, initial: initial, action)
        } else {
            modifier(Change16(value: value, initial: initial, action: action))
        }
    }

    /// Flash the scroll indicators on appear (iOS 17+); below that, plain scrolling.
    @ViewBuilder func flashIndicators16(onAppear: Bool) -> some View {
        if #available(iOS 17, *) { scrollIndicatorsFlash(onAppear: onAppear) } else { self }
    }

    /// Flash the scroll indicators when `value` changes (iOS 17+); below that, plain scrolling.
    @ViewBuilder func flashIndicators16<V: Equatable>(trigger value: V) -> some View {
        if #available(iOS 17, *) { scrollIndicatorsFlash(trigger: value) } else { self }
    }

    /// No bounce past the content's edge when it all fits (iOS 16.4+); below that, plain scrolling.
    @ViewBuilder func sizeBounce16() -> some View {
        if #available(iOS 16.4, *) { scrollBounceBehavior(.basedOnSize) } else { self }
    }

    /// Keep the scrolled end in view (iOS 17+); below that the top, as a scroll view does.
    @ViewBuilder func defaultAnchorBottom16(_ bottom: Bool) -> some View {
        if #available(iOS 17, *) { defaultScrollAnchor(bottom ? .bottom : .top) } else { self }
    }
}

/// The iOS 16 half of `onChange16`: the iOS 16 spelling (deprecated in iOS 17, the one warning
/// this file adds, by design so the 35 call sites stay clean) with the last value kept, and the
/// `initial` run from appear.
private struct Change16<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: (V, V) -> Void
    @State private var old: V?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if initial { action(value, value) }
                old = value
            }
            .onChange(of: value) { new in
                if let o = old, o != new { action(o, new) }
                old = new
            }
    }
}

/// VoiceOver announcements: SwiftUI's `AccessibilityNotification…post()` (iOS 17+) is this
/// UIAccessibility call, so on every system these speak the same words.
enum A11y {
    static func announce(_ words: String) {
        UIAccessibility.post(notification: .announcement, argument: words)
    }
    static func screenChanged() {
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    static func layoutChanged() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
}

/// The tour's tick and the panel's refusal buzz: `sensoryFeedback` (iOS 17+) plays these same
/// generators, so on every system they feel the same (and stay silent on an iPad, which has no
/// Taptic Engine, as before).
enum Haptic {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
