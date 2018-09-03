//
//  WBWebViewController.h
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/9.
//  Copyright © 2018年 huipengo. All rights reserved.
//  参考：https://github.com/devedbox/AXWebViewController

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "WBWebView.h"
#import "WBSecurityPolicy.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSURLSessionAuthChallengeDisposition (^WKWebViewDidReceiveAuthenticationChallengeHandler)(WKWebView *webView, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential);
API_AVAILABLE(ios(8.0))

@interface WBWebViewController : UIViewController

@property (nonatomic, strong, readonly) WBWebView *webView;

/// Open app link in app store app. Default is NO.
@property(nonatomic, assign) BOOL reviewsAppInAppStore;
/// Max length of title string content. Default is 12.
@property (nonatomic, assign) NSUInteger maxAllowedTitleLength;

/// Time out internal.
@property (nonatomic, assign) NSTimeInterval timeoutInternal;

/// Cache policy.
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

/// The based initialized url of the web view controller if any.
@property (nonatomic, readonly) NSURL *URL;

/**
 progress color
 */
@property (nonatomic, strong) UIColor * _Nullable loadingProgressColor;

/**
 Background Title. default NO
 */
@property (nonatomic, assign) BOOL showBackgroundLabel;

@property (nonatomic, assign) BOOL showNavigationCloseBarButtonItem;

/// Check url can open default YES, only work after iOS 8.
@property (nonatomic, assign) BOOL checkUrlCanOpen API_AVAILABLE(ios(8.0));

@property (nonatomic, strong) NSArray<NSString *> *removeElementIds;


/// Get a instance of `WBWebViewController` by a url.
///
/// @param URL a URL to be loaded.
///
/// @return a instance of `WBWebViewController`.
- (instancetype)initWithURL:(NSURL *)URL;
/// Get a instance of `WBWebViewController` by a url request.
///
/// @param request a URL request to be loaded.
///
/// @return a instance of `WBWebViewController`.
- (instancetype)initWithRequest:(NSURLRequest *)request;

/// Get a instance of `WBWebViewController` by a url and configuration of web view.
///
/// @param URL a URL to be loaded.
/// @param configuration configuration instance of WKWebViewConfiguration to create web view.
///
/// @return a instance of `WBWebViewController`.
- (instancetype)initWithURL:(NSURL *)URL configuration:(WKWebViewConfiguration *)configuration;
/// Get a instance of `WBWebViewController` by a request and configuration of web view.
///
/// @param request a URL request to be loaded.
/// @param configuration configuration instance of WKWebViewConfiguration to create web view.
///
/// @return a instance of `WBWebViewController`.
- (instancetype)initWithRequest:(NSURLRequest *)request configuration:(WKWebViewConfiguration *)configuration;

/// Get a instance of `WBWebViewController` by a HTML string and a base URL.
///
/// @param HTMLString a HTML string object.
/// @param baseURL a baseURL to be loaded.
///
/// @return a instance of `WBWebViewController`.
- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL * _Nullable)baseURL;

/// Load a new url.
///
/// @param URL a new url.
- (void)loadURL:(NSURL *)URL;

/// Load a new html string.
///
/// @param HTMLString a encoded html string.
/// @param baseURL base url of bundle.
- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

@end

@interface WBWebViewController (items)

- (void)updateFrameOfProgressView;

- (void)updateNavigationItems;

- (void)updateToolbarItems;

- (void)updateNavigationItemTitle;

- (void)updateBackgroundLabelText;

@end

@interface WBWebViewController (Cookie)

/**
 读取本地磁盘的cookies，包括WKWebview的cookies和sharedHTTPCookieStorage存储的cookies
 
 @return 返回包含所有的cookies的数组；
 当系统低于 iOS11 时，cookies 将同步NSHTTPCookieStorage的cookies，当系统大于iOS11时，cookies 将同步
 */
- (NSMutableArray<NSHTTPCookie *> *)sharedHTTPCookieStorage;

/**
 提供cookies插入，用于loadRequest 网页之前
 
 @param cookie NSHTTPCookie 类型
 cookie 需要设置 cookie 的name，value，domain，expiresDate（过期时间，当不设置过期时间，cookie将不会自动清除）；
 cookie 设置expiresDate时使用 [cookieProperties setObject:expiresDate forKey:NSHTTPCookieExpires];将不起作用，原因不明；使用 cookieProperties[expiresDate] = expiresDate; 设置cookies 设置时间。
 */
- (void)setCookie:(NSHTTPCookie *)cookie;

/**
 delete cookie
 
 @param cookie cookie
 @param completionHandler call back
 */
- (void)wb_deleteCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler;
- (void)wb_deleteCookiesByURL:(NSURL *)URL completionHandler:(nullable void (^)(void))completionHandler;

/**
 clear all cookies
 */
+ (void)clearAllCookies;

@end

@interface WBWebViewController (WebCache)

/**
 Clear cache data of web view.
 
 @param completion completion block
 */
+ (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;

@end

@interface WBWebViewController (Security)

/// Challenge handler for the credential.
@property(nonatomic, copy,  nullable) WKWebViewDidReceiveAuthenticationChallengeHandler challengeHandler;

/// The security policy used by created session to evaluate server trust for secure connections.
/// `WBWebViewController` uses the `defaultPolicy` unless otherwise specified.
@property(nonatomic, readwrite, nullable) WBSecurityPolicy *securityPolicy;

@end

NS_ASSUME_NONNULL_END

