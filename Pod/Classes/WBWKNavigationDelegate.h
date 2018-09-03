//
//  WBWKNavigationDelegate.h
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/6.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WBWKNavigationDelegate <WKNavigationDelegate>

@optional
- (void)wb_webView:(WKWebView *)webView progressChanged:(CGFloat)progress;

- (void)wb_scrollViewDidScroll:(UIScrollView *)scrollView;

@end

@interface WBWKNavigationDelegateImpl : NSObject <WKNavigationDelegate>

@property (nonatomic, weak, nullable) id <WBWKNavigationDelegate> forwardDelegate;

@property (nonatomic, weak) WKWebView *webView;

@end

NS_ASSUME_NONNULL_END
