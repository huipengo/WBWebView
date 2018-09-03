//
//  WBWebViewController.m
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/9.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import "WBWebViewController.h"
#import "WBWebViewHelper.h"
#import <StoreKit/StoreKit.h>

#ifndef wb404NotFoundHTMLPath
#define wb404NotFoundHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"WBWebViewController")] pathForResource:@"WebView.bundle/html.bundle/404" ofType:@"html"]
#endif

#ifndef wbNetworkErrorHTMLPath
#define wbNetworkErrorHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"WBWebViewController")] pathForResource:@"WebView.bundle/html.bundle/neterror" ofType:@"html"]
#endif

@interface WBWebViewController () <WBWKNavigationDelegate, SKStoreProductViewControllerDelegate>
{
    NSString *_HTMLString;
    NSURL *_baseURL;
    
    WKWebViewConfiguration *_configuration;
    
    WKWebViewDidReceiveAuthenticationChallengeHandler _challengeHandler;
    WBSecurityPolicy *_securityPolicy;
    
    NSURLRequest *_request;
}

@property (nonatomic, strong, readwrite) WBWebView *webView;

@property(nonatomic, strong) UILabel *backgroundLabel;

/// 进度条
@property (nonatomic, strong, readwrite) UIProgressView *progressView;

/// default NSBundle
@property(strong, nonatomic) NSBundle *resourceBundle;
/// Back bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *backBarButtonItem;
/// Forward bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *forwardBarButtonItem;
/// Refresh bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *refreshBarButtonItem;
/// Stop bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *stopBarButtonItem;
/// Navigation close bar button item.
@property(nonatomic, strong) UIBarButtonItem *navigationCloseBarButtonItem;

@end

@implementation WBWebViewController

#pragma mark -- life cycle
- (instancetype)init {
    if (self = [super init]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    // Set up default values.
    _showBackgroundLabel = YES;
    _showNavigationCloseBarButtonItem = YES;
    _maxAllowedTitleLength = 12;
    _checkUrlCanOpen = YES;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

- (instancetype)initWithURL:(NSURL*)pageURL {
    if(self = [self init]) {
        _URL = pageURL;
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [self init]) {
        _request = request;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL configuration:(WKWebViewConfiguration *)configuration {
    if (self = [self initWithURL:URL]) {
        _configuration = configuration;
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request configuration:(WKWebViewConfiguration *)configuration {
    if (self = [self initWithRequest:request]) {
        _request = request;
        _configuration = configuration;
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    if (self = [self init]) {
        _HTMLString = HTMLString;
        _baseURL = baseURL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self viewConfigure];
    [self loadRequest];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.navigationController) {
        [_progressView removeFromSuperview];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark -- private methods
- (void)viewConfigure {
    [self updateNavigationItems];
    [self setupSubviews];
}

- (void)setupSubviews {
    self.view.backgroundColor = [UIColor whiteColor];
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    
    [self.view addSubview:self.backgroundLabel];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_backgroundLabel(<=width)]" options:0 metrics:@{@"width":@([UIScreen mainScreen].bounds.size.width)} views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];

    CGFloat constant = 44.0f + [[UIApplication sharedApplication] statusBarFrame].size.height + 30.0f;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:constant]];
    
    // Add web view.
    self.webView.frame = self.view.bounds;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide)]];
}

#pragma mark -- WB_WKNavigationDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self didStartLoad];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self didFinishLoad];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self didFailLoadWithError:error];
}

/// 页面加载失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self didFailLoadWithError:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    [WBWebViewHelper webViewController:self webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}

/// 返回内容是否允许加载
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    [self.webView wb_decidePolicyForNavigationResponse:navigationResponse];
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler {
    // !!!: Do add the security policy if using a custom credential.
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if (self.challengeHandler) {
        disposition = self.challengeHandler(webView, challenge, &credential);
        !completionHandler?:completionHandler(disposition, credential);
    }
    else {
        [WBWebViewHelper securityPolicy:self.securityPolicy didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    /// fix白屏问题
    [webView reload];
}

- (void)wb_webView:(WKWebView *)webView progressChanged:(CGFloat)progress {
    self.progressView.progress = progress;
    
    if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
        [self updateFrameOfProgressView];
        [self.navigationController.navigationBar addSubview:self.progressView];
    }
    
    if (progress >= 1.0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressView.hidden = YES;
        });
        
        [self updateNavigationItems];
        [self updateToolbarItems];
    }
}

- (void)wb_scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat top = self.backgroundLabel.frame.origin.y;
    CGFloat alpha = MIN(1.0f, ((- offsetY - top) / top));
    self.backgroundLabel.alpha = alpha;
}

#pragma mark - SKStoreProductViewControllerDelegate.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark --
- (void)didStartLoad {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateNavigationItems];
    [self updateToolbarItems];
}

- (void)didFinishLoad {
    
    [self.removeElementIds enumerateObjectsUsingBlock:^(NSString * _Nonnull elementId, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.webView removeElementById:elementId];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self updateNavigationItemTitle];
    [self updateNavigationItems];
    [self updateToolbarItems];
    [self updateBackgroundLabelText];
}

- (void)didFailLoadWithError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) return;
    
    if (error.code == NSURLErrorCannotFindHost) {// 404
        [self loadURL:[NSURL fileURLWithPath:wb404NotFoundHTMLPath]];
    }
    else {
        [self loadURL:[NSURL fileURLWithPath:wbNetworkErrorHTMLPath]];
    }
    
    if (error.localizedDescription) {
        self.backgroundLabel.text = [NSString stringWithFormat:@"%@", error.localizedDescription];
    }
    [self updateNavigationItems];
    [self updateToolbarItems];
    [self updateNavigationItemTitle];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark -- load request
- (void)loadRequest {
    if (_request) {
        NSMutableURLRequest *__request = [_request mutableCopy];
        [self.webView wb_loadRequestURL:__request];
    }
    else if (_URL) {
        [self loadURL:_URL];
    }
    else if (/*_baseURL && */_HTMLString) {
        [self loadHTMLString:_HTMLString baseURL:_baseURL];
    }
    else {
        // Handle none resource case.
        [self loadURL:[NSURL fileURLWithPath:wb404NotFoundHTMLPath]];
    }
}

- (void)loadURL:(NSURL *)pageURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pageURL];
    request.timeoutInterval = _timeoutInternal;
    request.cachePolicy = _cachePolicy;
    [_webView wb_loadRequestURL:request];
}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    _baseURL = baseURL;
    _HTMLString = HTMLString;
    [self.webView loadHTMLString:HTMLString baseURL:baseURL];
}

#pragma mark -- getter
- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
        _progressView.trackTintColor = [UIColor clearColor];
        _progressView.progressTintColor = [UIColor colorWithRed:51.0f/255.0f green:82.0f/255.0f blue:254.0f/255.0f alpha:1.0f];
    }
    return _progressView;
}

- (UIBarButtonItem *)navigationCloseBarButtonItem {
    if (!_navigationCloseBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"wb_close_black" inBundle:self.resourceBundle compatibleWithTraitCollection:nil];
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(navigationItemHandleClose:)];
        _navigationCloseBarButtonItem.imageInsets = UIEdgeInsetsMake(0.0f, -3.0f, 0.0f, 10.0f);
    }
    return _navigationCloseBarButtonItem;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!_backBarButtonItem) {
        _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:
                              [UIImage imageNamed:@"wb_goback" inBundle:self.resourceBundle compatibleWithTraitCollection:nil]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(goBackClicked:)];
        _backBarButtonItem.width = 18.0f;
    }
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!_forwardBarButtonItem) {
        _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:
                                 [UIImage imageNamed:@"wb_forward" inBundle:self.resourceBundle compatibleWithTraitCollection:nil]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(goForwardClicked:)];
        _forwardBarButtonItem.width = 18.0f;
    }
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!_refreshBarButtonItem) {
        _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    }
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!_stopBarButtonItem) {
        _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    }
    return _stopBarButtonItem;
}

- (NSBundle *)resourceBundle {
    if (!_resourceBundle) {
        NSString *resourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"WebView" ofType:@"bundle"] ;
        if (resourcePath) {
            _resourceBundle = [NSBundle bundleWithPath:resourcePath];
        }
    }
    return _resourceBundle;
}

- (WBWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = _configuration;
        _webView = [[WBWebView alloc] initWithFrame:CGRectZero configuration:configuration];     
        _webView.wb_navigationDelegate = self;
    }
    return _webView;
}

- (UILabel *)backgroundLabel {
    if (!_backgroundLabel) {
        _backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _backgroundLabel.textColor = [UIColor colorWithRed:0.180f green:0.192f blue:0.196f alpha:1.0f];
        _backgroundLabel.font = [UIFont systemFontOfSize:12.0f];
        _backgroundLabel.numberOfLines = 0;
        _backgroundLabel.textAlignment = NSTextAlignmentCenter;
        _backgroundLabel.backgroundColor = [UIColor clearColor];
        _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        _backgroundLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _backgroundLabel;
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender {
    if ([_webView canGoBack]) {
        [_webView goBack];
    }
}

- (void)goForwardClicked:(UIBarButtonItem *)sender {
    if ([_webView canGoForward]) {
        [_webView goForward];
    }
}

- (void)reloadClicked:(UIBarButtonItem *)sender {
    /// 重新加载网页
    //[_webView reload];
    /// 忽略缓存，重新加载服务器最新的网页
    [_webView reloadFromOrigin];
}

- (void)stopClicked:(UIBarButtonItem *)sender {
    [_webView stopLoading];
}

- (void)navigationItemHandleClose:(UIBarButtonItem *)item {
    if ([_webView canGoBack]) {
        [_webView goBack];
        return;
    }
    
    if (self.presentingViewController && self.navigationController.viewControllers.count == 1) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -- setter
- (void)setLoadingProgressColor:(UIColor *)loadingProgressColor {
    _loadingProgressColor = loadingProgressColor;
    self.progressView.progressTintColor = _loadingProgressColor ? _loadingProgressColor : [UIColor colorWithRed:51.0f/255.0f green:82.0f/255.0f blue:254.0f/255.0f alpha:1.0f];
}

- (void)setShowBackgroundLabel:(BOOL)showBackgroundLabel {
    _showBackgroundLabel = showBackgroundLabel;
    self.backgroundLabel.hidden = !showBackgroundLabel;
}

- (void)setTimeoutInternal:(NSTimeInterval)timeoutInternal {
    _timeoutInternal = timeoutInternal;
    NSMutableURLRequest *request = [_request mutableCopy];
    request.timeoutInterval = _timeoutInternal;
    [_webView wb_loadRequestURL:request];
    _request = [request copy];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    _cachePolicy = cachePolicy;
    NSMutableURLRequest *request = [_request mutableCopy];
    request.cachePolicy = _cachePolicy;
    [_webView wb_loadRequestURL:request];
    _request = [request copy];
}

- (void)dealloc {
    [_webView stopLoading];
    _webView.wb_navigationDelegate = nil;
}

@end

@implementation WBWebViewController (items)

#pragma mark -- update
- (void)updateFrameOfProgressView {
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    self.progressView.frame = barFrame;
}

- (void)updateToolbarItems {
    if (!(self.webView.canGoBack || self.webView.canGoForward)) {
        [self.navigationController setToolbarHidden:YES animated:NO];
        return;
    }
    
    self.backBarButtonItem.enabled = self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.webView.canGoForward;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        fixedSpace.width = 35.0f;
        NSArray *items = [NSArray arrayWithObjects:fixedSpace, refreshStopBarButtonItem, fixedSpace, self.backBarButtonItem, fixedSpace, self.forwardBarButtonItem, fixedSpace, nil];
        
        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    }
    else {
        NSArray *items = [NSArray arrayWithObjects: flexibleSpace, self.backBarButtonItem, flexibleSpace, self.forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, fixedSpace, nil];
        
        self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationController.toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
        self.toolbarItems = items;
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
}

- (void)updateNavigationItems {
    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = self.navigationCloseBarButtonItem;
    }
    self.navigationController.interactivePopGestureRecognizer.enabled = !self.webView.canGoBack;
}

- (void)updateNavigationItemTitle {
    NSString *title = self.title;
    title = title.length > 0 ? title : [_webView title];
    if (title.length > _maxAllowedTitleLength) {
        title = [[title substringToIndex:_maxAllowedTitleLength] stringByAppendingString:@"…"];
    }
    self.navigationItem.title = title.length > 0 ? title : @"内容浏览";
}

- (void)updateBackgroundLabelText {
    NSString *bundle = [WBWebViewHelper bundle_name];
    NSString *host   = self.webView.URL.host;
    self.backgroundLabel.text = [NSString stringWithFormat:@"网页由 %@ %@.", host?:bundle, @"提供"];
}

@end

@implementation WBWebViewController (Cookie)

- (NSMutableArray<NSHTTPCookie *> *)sharedHTTPCookieStorage {
    return self.webView.sharedHTTPCookieStorage;
}

- (void)setCookie:(NSHTTPCookie *)cookie {
    [self.webView wb_insertCookie:cookie];
}

- (void)wb_deleteCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler {
    [self.webView wb_deleteCookie:cookie completionHandler:completionHandler];
}

- (void)wb_deleteCookiesByURL:(NSURL *)URL completionHandler:(nullable void (^)(void))completionHandler {
    [self.webView wb_deleteCookiesByURL:URL completionHandler:completionHandler];
}

+ (void)clearAllCookies {
    [WBWebView wb_clearCookies];
}

@end


@implementation WBWebViewController (WebCache)

+ (void)clearWebCacheCompletion:(dispatch_block_t)completion {
    [WBWebViewHelper clearWebCacheCompletion:completion];
}

@end

@implementation WBWebViewController (Security)
- (WKWebViewDidReceiveAuthenticationChallengeHandler)challengeHandler {
    return _challengeHandler;
}

- (WBSecurityPolicy *)securityPolicy {
    return _securityPolicy;
}

- (void)setChallengeHandler:(WKWebViewDidReceiveAuthenticationChallengeHandler)challengeHandler {
    _challengeHandler = [challengeHandler copy];
}

- (void)setSecurityPolicy:(WBSecurityPolicy *)securityPolicy {
    _securityPolicy = securityPolicy;
}
@end
