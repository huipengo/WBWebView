//
//  WBWebViewHelper.h
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/9.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBSecurityPolicy.h"
#import <WebKit/WebKit.h>
@class WBWebViewController;

NS_ASSUME_NONNULL_BEGIN

@interface WBWebViewHelper : NSObject

+ (NSString *_Nullable)bundle_name;

+ (void)clearWebCacheCompletion:(dispatch_block_t _Nullable )completion;

+ (void)securityPolicy:(WBSecurityPolicy *_Nullable)securityPolicy didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *_Nullable)challenge completionHandler:(void (^_Nullable)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler;

+ (void)webViewController:(WBWebViewController *_Nullable)webViewController webView:(WKWebView *_Nullable)webView decidePolicyForNavigationAction:(WKNavigationAction *_Nullable)navigationAction decisionHandler:(void (^_Nullable)(WKNavigationActionPolicy))decisionHandler;

+ (UILabel *_Nullable)backgroundLabel;

/**
 *  获取当前最上面活动的控制器
 */
+ (UIViewController *_Nullable)wb_currentTopViewController;

@end

NS_ASSUME_NONNULL_END
