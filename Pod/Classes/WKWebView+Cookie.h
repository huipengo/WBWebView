//
//  WKWebView+Cookie.h
//  WBKit_Example
//
//  Created by penghui8 on 2018/8/30.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (Cookie)


/**
 iOS11 同步cookies

 @param cookieStroe WKHTTPCookieStore
 */
- (void)wb_syncCookieStore:(WKHTTPCookieStore * _Nullable)cookieStroe API_AVAILABLE(macosx(10.13), ios(11.0));


/**
 存储cookie

 @param cookie cookie
 */
- (void)wb_insertCookie:(NSHTTPCookie * _Nullable)cookie;


/**
 获取本地磁盘的cookies

 @return cookies
 */
- (NSMutableArray<NSHTTPCookie *> * _Nullable)sharedHTTPCookieStorage;


/**
 清除cookies
 */
+ (void)wb_clearCookies;


/**
 删除一个cookie

 @param cookie cookie
 @param completionHandler call back
 */
- (void)wb_deleteCookie:(NSHTTPCookie * _Nullable)cookie completionHandler:(void (^_Nullable)(void))completionHandler;


/**
 删除一个cookie

 @param URL URL
 @param completionHandler call back
 */
- (void)wb_deleteCookiesByURL:(NSURL * _Nullable)URL completionHandler:(void (^_Nullable)(void))completionHandler;


/**
 js获取domain的cookie

 @param domain domain
 @return cookie string
 */
- (NSString * _Nullable)wb_jsCookieStringWithDomain:(NSString * _Nullable)domain;

- (WKUserScript * _Nullable)wb_searchCookieForUserScriptWithDomain:(NSString * _Nullable)domain;


/**
 PHP 获取domain的cookie

 @param domain domain
 @return cookie string
 */
- (NSString * _Nullable)wb_phpCookieStringWithDomain:(NSString * _Nullable)domain;

@end
