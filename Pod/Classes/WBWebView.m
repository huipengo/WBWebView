//
//  WBWebView.m
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/6.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import "WBWebView.h"
#import "WBWKUIDelegate.h"
#import "WBWebViewConfiguration.h"

static NSString * const wbEstimatedProgressKeyPath       = @"estimatedProgress";
static NSString * const wbScrollViewContentOffsetKeyPath = @"scrollView.contentOffset";

@interface WBWebView () <WKUIDelegate, WKNavigationDelegate>

@property (nonatomic,strong) WBWKUIDelegateImpl *wb_wkUIDelegateImpl;
@property (nonatomic,strong) WBWKNavigationDelegateImpl *wb_wkNavigationDelegateImpl;

@end

@implementation WBWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    if (!configuration) {
        configuration = [WBWebViewConfiguration defaultConfiguration];
    }
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self viewConfigure];
    }
    return self;
}

- (void)viewConfigure {    
    /// 设置代理
    self.UIDelegate = self.wb_wkUIDelegateImpl;
    self.navigationDelegate = self.wb_wkNavigationDelegateImpl;
        
    self.allowsBackForwardNavigationGestures = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    /// 添加进度监听
    [self addObserver:self forKeyPath:wbEstimatedProgressKeyPath options:(NSKeyValueObservingOptionNew) context:nil];
    [self addObserver:self forKeyPath:wbScrollViewContentOffsetKeyPath options:(NSKeyValueObservingOptionNew) context:nil];
    
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStore = self.configuration.websiteDataStore.httpCookieStore;
        [self wb_syncCookieStore:cookieStore];
    }
}

- (void)wb_loadRequestURL:(NSMutableURLRequest * _Nullable)request {
    NSString *domain = request.URL.host;

    if (domain) {
        /** 插入cookies JS */
        [self.configuration.userContentController addUserScript:[self wb_searchCookieForUserScriptWithDomain:domain]];
        /** 插入cookies PHP */
        [request setValue:[self wb_phpCookieStringWithDomain:domain] forHTTPHeaderField:@"Cookie"];
    }
    
    [self loadRequest:request];
}

- (void)wb_decidePolicyForNavigationResponse:(WKNavigationResponse * _Nullable)navigationResponse {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
    if (@available(iOS 11.0, *)) {
        /// 浏览器自动存储cookie
    }
    else {
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                for (NSHTTPCookie *cookie in cookies) {
                    [self wb_insertCookie:cookie];
                }
            } @catch (NSException *e) {
                NSLog(@"failed: %@", e);
            } @finally {
                
            }
        });
    }
}

#pragma mark -- KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:wbEstimatedProgressKeyPath]) {
        CGFloat progress = [change[NSKeyValueChangeNewKey] floatValue];
        if (self.wb_wkNavigationDelegateImpl.forwardDelegate && [self.wb_wkNavigationDelegateImpl.forwardDelegate respondsToSelector:@selector(wb_webView:progressChanged:)]) {
            [self.wb_wkNavigationDelegateImpl.forwardDelegate wb_webView:self progressChanged:progress];
        }
    }
    else if ([keyPath isEqualToString:wbScrollViewContentOffsetKeyPath]) {
        if (self.wb_wkNavigationDelegateImpl.forwardDelegate && [self.wb_wkNavigationDelegateImpl.forwardDelegate respondsToSelector:@selector(wb_scrollViewDidScroll:)]) {
            [self.wb_wkNavigationDelegateImpl.forwardDelegate wb_scrollViewDidScroll:self.scrollView];
        }
    }
}

#pragma mark --
- (void)setWb_navigationDelegate:(id<WBWKNavigationDelegate>)wb_navigationDelegate {
    _wb_navigationDelegate = wb_navigationDelegate;
    self.wb_wkNavigationDelegateImpl.forwardDelegate = wb_navigationDelegate;
}

- (void)setAllowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback {
    _allowsInlineMediaPlayback = allowsInlineMediaPlayback;
    [self.configuration setAllowsInlineMediaPlayback:allowsInlineMediaPlayback];
}

- (void)setScalesPageToFit:(BOOL)scalesPageToFit {
    if (_scalesPageToFit == scalesPageToFit) return;
    NSString *jScript = @"var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(meta);";
    
    if(scalesPageToFit) {
        WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
        [self.configuration.userContentController addUserScript:wkUScript];
    }
    else {
        NSMutableArray* array = [NSMutableArray arrayWithArray:self.configuration.userContentController.userScripts];
        for (WKUserScript *wkUScript in array) {
            if ([wkUScript.source isEqual:jScript]) {
                [array removeObject:wkUScript];
                break;
            }
        }
        for (WKUserScript *wkUScript in array) {
            [self.configuration.userContentController addUserScript:wkUScript];
        }
    }
    _scalesPageToFit = scalesPageToFit;
}

#pragma mark -- getter
- (WBWKUIDelegateImpl *)wb_wkUIDelegateImpl {
    if (!_wb_wkUIDelegateImpl) {
        _wb_wkUIDelegateImpl = [[WBWKUIDelegateImpl alloc] init];
    }
    return _wb_wkUIDelegateImpl;
}

- (WBWKNavigationDelegateImpl *)wb_wkNavigationDelegateImpl {
    if (!_wb_wkNavigationDelegateImpl) {
        _wb_wkNavigationDelegateImpl = [[WBWKNavigationDelegateImpl alloc] init];
    }
    return _wb_wkNavigationDelegateImpl;
}

#pragma mark -- dealloc
- (void)dealloc {
    
    [self removeObserver:self forKeyPath:wbEstimatedProgressKeyPath];
    [self removeObserver:self forKeyPath:wbScrollViewContentOffsetKeyPath];
    
    [self stopLoading];
    
    self.UIDelegate = nil;
    self.navigationDelegate = nil;
    
    [WBWebView wb_clearCookies];
}

@end


@implementation WBWebView (javaScript)

/**
 移出div标签
 
 @param elementId div id
 */
- (void)removeElementById:(NSString * _Nullable)elementId {
    NSString *javaScript = [NSString stringWithFormat:@"document.getElementById('%@').style.display='none';document.getElementById('%@').parentNode.removeChild(document.getElementById('%@'))", elementId, elementId, elementId];
    [self evaluateJavaScript:javaScript completionHandler:^(id _Nullable json, NSError * _Nullable error) {
        NSLog(@"json is %@, error is %@",json, error);
    }];
}

- (void)removeElementsByClassName:(NSString * _Nullable)className {
    NSString *javaScript = [NSString stringWithFormat:@"document.documentElement.getElementsByClassName('%@')[0].style.display='none'",className];
    [self evaluateJavaScript:javaScript completionHandler:^(id _Nullable json, NSError * _Nullable error) {
        NSLog(@"json is %@, error is %@",json, error);
    }];
}

@end
