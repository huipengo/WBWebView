//
//  WBWebView.h
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/6.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "WBWKNavigationDelegate.h"
#import "WBWKUIDelegate.h"
#import "WKWebView+Cookie.h"

NS_ASSUME_NONNULL_BEGIN

@interface WBWebView : WKWebView

/*! @abstract The web view's navigation delegate. */
@property (nullable, nonatomic, weak) id <WBWKNavigationDelegate> wb_navigationDelegate;

/// defaults to YES
@property (nonatomic) BOOL allowsInlineMediaPlayback;

/// defaults to YES
@property (nonatomic) BOOL scalesPageToFit;

- (void)wb_loadRequestURL:(NSMutableURLRequest * _Nullable)request;

- (void)wb_decidePolicyForNavigationResponse:(WKNavigationResponse * _Nullable)navigationResponse;

@end

@interface WBWebView (javaScript)

/**
 移出div标签
 
 @param elementId div id
 */
- (void)removeElementById:(NSString * _Nullable)elementId;

- (void)removeElementsByClassName:(NSString * _Nullable)className;

@end

NS_ASSUME_NONNULL_END
