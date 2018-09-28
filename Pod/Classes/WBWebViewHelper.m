//
//  WBWebViewHelper.m
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/9.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import "WBWebViewHelper.h"
#include <pthread/pthread.h>
#import "WBWebViewController.h"
#import <StoreKit/StoreKit.h>

/// URL key for 404 not found page.
static NSString *const wb404NotFoundURLKey = @"wb_404_not_found";
/// URL key for network error page.
static NSString *const wbNetworkErrorURLKey = @"wb_network_error";

@implementation WBWebViewHelper

+ (NSString *_Nullable)bundle_name {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundle = ([infoDictionary objectForKey:@"CFBundleDisplayName"]?:[infoDictionary objectForKey:@"CFBundleName"])?:[infoDictionary objectForKey:@"CFBundleIdentifier"];
    return bundle;
}

+ (void)clearWebCacheCompletion:(dispatch_block_t _Nullable )completion {
    if (@available(iOS 9.0, *)) {
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:completion];
    } else {
        NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
        NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
        NSString *webKitFolderInCaches = [NSString stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
        NSString *webKitFolderInCachesfs = [NSString stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
        
        NSError *error;
        /* iOS8.0 WebView Cache path */
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
        
        /* iOS7.0 WebView Cache path */
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];
        if (completion) {
            completion();
        }
    }
}

+ (void)securityPolicy:(WBSecurityPolicy *_Nullable)securityPolicy didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *_Nullable)challenge completionHandler:(void (^_Nullable)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if (credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    !completionHandler?:completionHandler(disposition, credential);
}

+ (void)webViewController:(WBWebViewController *_Nullable)webViewController webView:(WKWebView *_Nullable)webView decidePolicyForNavigationAction:(WKNavigationAction *_Nullable)navigationAction decisionHandler:(void (^_Nullable)(WKNavigationActionPolicy))decisionHandler {
    // Disable all the '_blank' target in page's target.
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
    // Resolve URL. Fixs the issue: https://github.com/devedbox/AXWebViewController/issues/7
    // !!!: Fixed url handleing of navigation request instead of main url.
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:navigationAction.request.URL.absoluteString];
    // For appstore and system defines. This action will jump to AppStore app or the system apps.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:components.URL.absoluteString]) {
        if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/'"] evaluateWithObject:components.URL.absoluteString] && !webViewController.reviewsAppInAppStore) {
            SKStoreProductViewController *productVC = [[SKStoreProductViewController alloc] init];
            productVC.delegate = (id<SKStoreProductViewControllerDelegate>)webViewController;
            NSError *error;
            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"id[1-9]\\d*" options:NSRegularExpressionCaseInsensitive error:&error];
            NSTextCheckingResult *result = [regex firstMatchInString:components.URL.absoluteString options:NSMatchingReportCompletion range:NSMakeRange(0, components.URL.absoluteString.length)];
            
            if (!error && result) {
                NSRange range = NSMakeRange(result.range.location+2, result.range.length-2);
                [productVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @([[components.URL.absoluteString substringWithRange:range] integerValue])} completionBlock:^(BOOL result, NSError * _Nullable error) {
                    
                }];
                [webViewController presentViewController:productVC animated:YES completion:NULL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        [self wb_applicationOpenURL:components.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'"] evaluateWithObject:components.scheme]) {// For any other schema but not `https`、`http` and `file`.
        if (@available(iOS 8.0, *)) { // openURL if ios version is low then 8 , app will crash
            if (!webViewController.checkUrlCanOpen || [[UIApplication sharedApplication] canOpenURL:components.URL]) {
                [self wb_applicationOpenURL:components.URL];
            }
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
                [[UIApplication sharedApplication] openURL:components.URL];
            }
        }
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // URL actions for 404 and Errors:
    if ([[NSPredicate predicateWithFormat:@"SELF ENDSWITH[cd] %@ OR SELF ENDSWITH[cd] %@", wb404NotFoundURLKey, wbNetworkErrorURLKey] evaluateWithObject:components.URL.absoluteString]) {
        // Reload the original URL.
        [webViewController loadURL:webViewController.URL];
    }
    else if (navigationAction.navigationType == WKNavigationTypeBackForward) {
        [webView reload];
    }
    
    // Update the items.
    [webViewController updateNavigationItems];
    [webViewController updateToolbarItems];
    // Call the decision handler to allow to load web page.
    decisionHandler(WKNavigationActionPolicyAllow);
}

+ (UILabel *_Nullable)backgroundLabel {
    UILabel *_backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _backgroundLabel.textColor = [UIColor colorWithRed:0.180f green:0.192f blue:0.196f alpha:1.0f];
    _backgroundLabel.font = [UIFont systemFontOfSize:12.0f];
    _backgroundLabel.numberOfLines = 0;
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.backgroundColor = [UIColor clearColor];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = false;
    return _backgroundLabel;
}

#pragma mark --
/**
 *  获取当前最上面活动的控制器
 */
+ (UIViewController *_Nullable)wb_currentTopViewController {
    UIViewController *result = nil;
    
    static pthread_mutex_t pLock;
    pthread_mutex_init(&pLock, NULL);
    pthread_mutex_lock(&pLock);
    
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    
    if (window) {
        NSArray *subviews = [window subviews];
        if (subviews && subviews.count > 0) {
            UIView *frontView = [subviews firstObject];
            id nextResponder = [frontView nextResponder];
            if ([nextResponder isKindOfClass:[UIViewController class]]) {
                result = nextResponder;
            }
            else {
                result = window.rootViewController;
            }
        }
    }
    
    UIViewController *viewController = [self wb_topViewControllerWithRootViewController:result];
    
    pthread_mutex_unlock(&pLock);
    
    return viewController;
}

+ (UIViewController *)wb_topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self wb_topViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self wb_topViewControllerWithRootViewController:navigationController.topViewController];
    }
    else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        if ([presentedViewController isKindOfClass:[UIAlertController class]]) {
            return rootViewController;
        }
        return [self wb_topViewControllerWithRootViewController:presentedViewController];
    }
    else {
        return rootViewController;
    }
}

+ (void)wb_applicationOpenURL:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
        if (canOpen) {
            if (@available(iOS 10.0, *)) {
                NSDictionary *options = @{};
                [[UIApplication sharedApplication] openURL:url options:options completionHandler:^(BOOL success) {}];
            }
            else {
                [[UIApplication sharedApplication] openURL:url];
            };
        }
    });
}

@end
