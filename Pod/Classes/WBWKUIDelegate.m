//
//  WBWKUIDelegate.m
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/6.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import "WBWKUIDelegate.h"
#import "WBWebViewHelper.h"

@implementation WBWKUIDelegateImpl

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithTitle:(NSString*__nullable)title {
    self = [super init];
    if (self) {
        self.title = title;
    }
    return self;
}

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        if (navigationAction.request) {
            [webView loadRequest:navigationAction.request];
            
        }
    }
    return nil;
}

- (void)webViewDidClose:(WKWebView *)webView {
    
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", @"确定")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction* action)
                         {
                             completionHandler();
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    
    UIViewController *rootController = [self rootController];
    
    [rootController presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", @"确定")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction* action)
                         {
                             completionHandler(YES);
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", @"取消")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* action) {
                                 completionHandler(NO);
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
    [alert addAction:cancel];
    
    UIViewController *rootController = [self rootController];
    
    [rootController presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * result))completionHandler
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:self.title
                                                                   message:prompt
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", @"确定")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction* action)
                         {
                             completionHandler(((UITextField*)alert.textFields[0]).text);
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", @"取消")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* action)
                             {
                                 completionHandler(nil);
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField* textField) {
        textField.text = defaultText;
    }];
    
    UIViewController *rootController = [self rootController];
    [rootController presentViewController:alert animated:YES completion:nil];
}

- (UIViewController *)rootController {
    UIViewController *rootController = [WBWebViewHelper wb_currentTopViewController];
    return rootController;
}

@end
