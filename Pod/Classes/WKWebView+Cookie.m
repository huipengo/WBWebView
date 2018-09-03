//
//  WKWebView+Cookie.m
//  WBKit_Example
//
//  Created by penghui8 on 2018/8/30.
//  Copyright © 2018年 huipengo. All rights reserved.
//  参考：https://github.com/llyouss/PAWeView

#import "WKWebView+Cookie.h"

/** static NSString * const wbWKCookiesKey = @"com.weibo.biz.cookies"; */

@implementation WKWebView (Cookie)

- (void)wb_syncCookieStore:(WKHTTPCookieStore *)cookieStore API_AVAILABLE(macosx(10.13), ios(11.0))
{
    NSMutableArray *cookies = self.sharedHTTPCookieStorage;
    
    if (cookies.count == 0) { return; }
    
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStore setCookie:cookie completionHandler:^{ }];
    }
}

- (void)wb_insertCookie:(NSHTTPCookie *)cookie
{
    @autoreleasepool {
        
        if (@available(iOS 11.0, *)) {
            WKHTTPCookieStore *cookieStore = self.configuration.websiteDataStore.httpCookieStore;
            [cookieStore setCookie:cookie completionHandler:^{ }];
        }
        
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        
        /**
        [self deleteLocalCookie:cookie completion:^(NSMutableArray<NSHTTPCookie *> *cookies) {
            [cookies addObject:cookie];
            [WKWebView saveLocalCookies:cookies];
        }];
        */
    }
}

- (NSMutableArray<NSHTTPCookie *> *)sharedHTTPCookieStorage {
    @autoreleasepool {
        NSMutableArray *cookiesArray = [NSMutableArray array];
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in cookieStorage.cookies) {
            [cookiesArray addObject:cookie];
        }
        
        /** 获取自定义存储的cookies */
        /**
        NSArray<NSHTTPCookie *> *tempCookies = [self localCookies];
        NSMutableArray<NSHTTPCookie *> *localCookies = [NSMutableArray arrayWithArray:tempCookies];
        
        /// 删除过期的cookie
        [tempCookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull cookie, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!cookie.expiresDate) {
                [cookiesArray addObject:cookie];
            }
            else {
                if ([cookie.expiresDate compare:self.currentTime]) {
                    [cookiesArray addObject:cookie];
                }
                else {
                    [localCookies removeObject:cookie];
                }
            }
        }];
                
        /// 存储最新有效的cookies
        [WKWebView saveLocalCookies:localCookies];
        */
        
        return cookiesArray;
    }
}

+ (void)wb_clearCookies
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0.0f];
    if (@available(iOS 11.0, *)) {
        NSSet *websiteDataTypes = [NSSet setWithObject:WKWebsiteDataTypeCookies];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:date completionHandler:^{ }];
    }
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] removeCookiesSinceDate:date];
    
    /** [self saveLocalCookies:@[]]; */
}

- (void)wb_deleteCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler;
{
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStore = self.configuration.websiteDataStore.httpCookieStore;
        [cookieStore deleteCookie:cookie completionHandler:nil];
    }
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    
    /**
    [self deleteLocalCookie:cookie completion:^(NSMutableArray<NSHTTPCookie *> *cookies) {
        [WKWebView saveLocalCookies:cookies];
    }];*/
    
    !completionHandler ?: completionHandler();
}

- (void)wb_deleteCookiesByURL:(NSURL *)URL completionHandler:(nullable void (^)(void))completionHandler {
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStore = self.configuration.websiteDataStore.httpCookieStore;
        [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * cookies) {
            for (NSHTTPCookie *cookie in cookies) {
                NSURL *domainURL = [NSURL URLWithString:cookie.domain];
                if ([domainURL.host isEqualToString:URL.host]) {
                    [cookieStore deleteCookie:cookie completionHandler:nil];
                }
            }
        }];
    }
    
    NSHTTPCookieStorage *cookiesStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookiesStore.cookies) {
        NSURL *domainURL = [NSURL URLWithString:cookie.domain];
        if ([domainURL.host isEqualToString:URL.host]) {
            [cookiesStore deleteCookie:cookie];
        }
    }
    
    
    /** [self wb_deleteLocalCookieByURL:URL]; */
    
    !completionHandler ?: completionHandler();
}

/** js获取domain的cookie */
- (NSString *)wb_jsCookieStringWithDomain:(NSString *)domain {
    @autoreleasepool {
        NSMutableString *cookieSting = [NSMutableString string];
        NSArray *cookieStorage = self.sharedHTTPCookieStorage;
        for (NSHTTPCookie *cookie in cookieStorage) {
            if ([domain containsString:cookie.domain]) {
                [cookieSting appendString:[NSString stringWithFormat:@"document.cookie = '%@=%@';",cookie.name,cookie.value]];
            }
        }
        return cookieSting;
    }
}

- (WKUserScript *)wb_searchCookieForUserScriptWithDomain:(NSString *)domain {
    NSString *cookie = [self wb_jsCookieStringWithDomain:domain];
    WKUserScript * cookieScript = [[WKUserScript alloc] initWithSource:cookie injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    return cookieScript;
}

- (NSString *)wb_phpCookieStringWithDomain:(NSString *)domain {
    @autoreleasepool {
        NSMutableString *cookieSting = [NSMutableString string];
        NSArray *cookieStorage = self.sharedHTTPCookieStorage;
        for (NSHTTPCookie *cookie in cookieStorage) {
            if ([domain containsString:cookie.domain]) {
                [cookieSting appendString:[NSString stringWithFormat:@"%@ = %@;",cookie.name,cookie.value]];
            }
        }
        if (cookieSting.length > 1) {
            [cookieSting deleteCharactersInRange:NSMakeRange(cookieSting.length - 1, 1)];
        }
        
        return (NSString *)cookieSting;
    }
}

- (NSDate *)currentTime {
    return [NSDate dateWithTimeIntervalSinceNow:0.0f];
}

#pragma mark -- local cookie
/**
- (NSArray<NSHTTPCookie *> *)localCookies {
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:[self cookiesData]];
    return cookies;
}

- (NSData *)cookiesData {
    NSData *cookiesData = [[NSUserDefaults standardUserDefaults] objectForKey:wbWKCookiesKey];
    return cookiesData;
}

+ (void)saveLocalCookies:(NSArray<NSHTTPCookie *> *)cookies {
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject:cookies];
    [[NSUserDefaults standardUserDefaults] setObject:cookiesData forKey:wbWKCookiesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)deleteLocalCookie:(NSHTTPCookie *)cookie completion:(void(^)(NSMutableArray<NSHTTPCookie *> *cookies))completion {
    NSArray<NSHTTPCookie *> *tempCookies = [self localCookies];
    NSMutableArray<NSHTTPCookie *> *localCookies = [NSMutableArray arrayWithArray:tempCookies];
    
    [tempCookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cookie.name isEqualToString:obj.name] && [cookie.domain isEqualToString:obj.domain]) {
            [localCookies removeObject:obj];
            *stop = YES;
        }
    }];
    
    !completion?:completion(localCookies);
}

- (void)wb_deleteLocalCookieByURL:(NSURL *)URL {
    NSArray<NSHTTPCookie *> *tempCookies = [self localCookies];
    NSMutableArray<NSHTTPCookie *> *localCookies = [NSMutableArray arrayWithArray:tempCookies];
    
    [tempCookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSURL *domainURL = [NSURL URLWithString:obj.domain];
        if ([URL.host isEqualToString:domainURL.host]) {
            [localCookies removeObject:obj];
            *stop = YES;
        }
    }];
    
    [WKWebView saveLocalCookies:localCookies];
}
*/

@end
