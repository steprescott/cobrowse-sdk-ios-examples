//
//  PBDTests-Bridging-Header.h
//  PBDTests
//

// The SDK's frame source and redaction engine, redeclared.
//
// Neither is in CobrowseSDK's public headers, but both are exported classes in
// the binary the app already links. So declaring the interfaces here is enough
// for the tests to drive the real thing. The alternative is asserting what the
// policy RETURNS, which is a weaker claim: the question that matters is what
// reaches the agent, and only a rendered frame answers it.
//
// If a future SDK version changes these signatures the tests fail to build,
// which is the right failure: a silently-wrong oracle is the thing to avoid.

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@protocol CBIOUIKitRedactionDelegate <NSObject>
- (nonnull NSArray<UIView *> *)redactedViewsForViewController:(nonnull UIViewController *)viewController;
- (nonnull NSArray<UIView *> *)unredactedViewsForViewController:(nonnull UIViewController *)viewController;
@end

@protocol CBIOUIKitFrameSourceDelegate <NSObject>
- (bool)shouldCaptureWindow:(nonnull UIWindow *)window;
@end

@interface CBIOFrame : NSObject
@property (nullable, readonly) CGImageRef CGImage;
@end

@interface CBIOUIKitRedaction : NSObject
@property BOOL isActive;
- (nonnull instancetype)initWithDelegate:(nonnull __weak id<CBIOUIKitRedactionDelegate>)delegate
                        webViewRedaction:(nullable id)webViewRedaction;
- (void)registerViewController:(nonnull UIViewController *)viewController;
- (void)unregisterViewController:(nonnull UIViewController *)viewController;
- (void)show;
- (void)hide;
@end

@interface CBIOUIKitFrameSource : NSObject
- (nonnull instancetype)initWithDelegate:(nonnull __weak id<CBIOUIKitFrameSourceDelegate>)delegate
                               redaction:(nullable CBIOUIKitRedaction *)redaction;
- (void)capturingWillStart;
- (void)capturingWillStop;
- (BOOL)isNewFrameAvailable;
- (nullable CBIOFrame *)newFrame:(CGFloat)scale;
+ (NSInteger)renderMethod;
@end
