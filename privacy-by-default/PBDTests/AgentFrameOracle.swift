import XCTest
import UIKit
import CoreGraphics
@testable import PBD

/// **What reaches the agent, for a controller hierarchy the test builds.**
///
/// Shared because the assertions worth making are about the transmitted frame
/// rather than about the arrays the policy returns. The arrays are the
/// mechanism; two policies can return quite different arrays and put the same
/// pixels on the wire, and every surprise in this example has been the policy
/// answering correctly while the frame disagreed.
@MainActor
enum AgentFrameOracle {

    /// Renders the frame the SDK would transmit for `window`, with `policy`
    /// answering for every controller in `tracked`.
    static func frame(
        of window: UIWindow,
        tracked: [UIViewController],
        policy: RedactByDefaultDelegate?
    ) throws -> CGImage {

        let delegate = Delegate(window: window, policy: policy)
        let redaction = CBIOUIKitRedaction(delegate: delegate, webViewRedaction: nil)
        let source = CBIOUIKitFrameSource(delegate: delegate, redaction: redaction)

        tracked.forEach { redaction.register($0) }
        redaction.show()
        source.capturingWillStart()

        let deadline = Date(timeIntervalSinceNow: 2)
        while !source.isNewFrameAvailable() && deadline.timeIntervalSinceNow > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        guard let frame = source.newFrame(1), let image = frame.cgImage
            else { throw Failure.noFrame }

        redaction.hide()
        source.capturingWillStop()
        tracked.forEach { redaction.unregisterViewController($0) }

        return image
    }

    /// Every controller under this one, the way the SDK tracks them.
    static func everyController(from root: UIViewController) -> [UIViewController] {
        var found = [root] + root.children.flatMap { everyController(from: $0) }
        if let presented = root.presentedViewController {
            found += everyController(from: presented)
        }
        return found
    }

    enum Failure: Error { case noFrame }

    private final class Delegate: NSObject, CBIOUIKitRedactionDelegate, CBIOUIKitFrameSourceDelegate {

        let window: UIWindow
        let policy: RedactByDefaultDelegate?

        init(window: UIWindow, policy: RedactByDefaultDelegate?) {
            self.window = window
            self.policy = policy
        }

        func redactedViews(for viewController: UIViewController) -> [UIView] {
            policy?.cobrowseRedactedViews(for: viewController) ?? []
        }

        func unredactedViews(for viewController: UIViewController) -> [UIView] {
            policy?.cobrowseUnredactedViews(for: viewController) ?? []
        }

        func shouldCapture(_ window: UIWindow) -> Bool { window === self.window }
    }
}

extension CGImage {

    /// Whether every pixel in this region is black, which is what a covered
    /// region looks like on the wire.
    ///
    /// The region is in the window's POINTS and the frame is in pixels, so it
    /// is scaled here. Passing an unscaled rect samples the wrong part of the
    /// image and, on a mostly-empty window, reads black wherever you point it.
    ///
    /// Inset by a pixel, because a cover's edge antialiases against what is
    /// behind it and a one-pixel fringe is not a leak.
    func isBlack(in region: CGRect, of window: UIWindow) throws -> Bool {
        try pixels(in: scale(region, to: window)).allSatisfy {
            $0.red < 24 && $0.green < 24 && $0.blue < 24
        }
    }

    /// The opposite question, asked separately so a test can prove its own
    /// fixture rendered before trusting a black result.
    func hasAnyColour(in region: CGRect, of window: UIWindow) throws -> Bool {
        try isBlack(in: region, of: window) == false
    }

    private func scale(_ region: CGRect, to window: UIWindow) -> CGRect {
        guard window.bounds.width > 0 else { return region }
        let factor = CGFloat(width) / window.bounds.width
        return region.applying(CGAffineTransform(scaleX: factor, y: factor))
    }

    struct Pixel { let red, green, blue: UInt8 }

    func pixels(in region: CGRect) throws -> [Pixel] {

        let wanted = region.insetBy(dx: 1, dy: 1).integral
            .intersection(CGRect(x: 0, y: 0, width: width, height: height))

        guard wanted.isEmpty == false, wanted.width >= 1, wanted.height >= 1
            else { throw Sampling.regionOffFrame(region) }

        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &bytes, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw Sampling.noContext }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        var found: [Pixel] = []
        for y in Int(wanted.minY) ..< Int(wanted.maxY) {
            for x in Int(wanted.minX) ..< Int(wanted.maxX) {
                let offset = y * bytesPerRow + x * 4
                found.append(Pixel(red: bytes[offset], green: bytes[offset + 1], blue: bytes[offset + 2]))
            }
        }
        return found
    }

    enum Sampling: Error {
        case regionOffFrame(CGRect)
        case noContext
    }
}
