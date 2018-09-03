//
//  WBViewController.m
//  WBWebView_Example
//
//  Created by penghui8 on 2018/9/3.
//  Copyright © 2018年 彭辉. All rights reserved.
//

#import "WBViewController.h"
#import <WBWebView/WBWebViewController.h>

@interface WBViewController ()

@end

@implementation WBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)webViewAction:(id)sender {
    NSURL *URL = [NSURL URLWithString:@"https://github.com/huipengo/WBWebView"];
    WBWebViewController *rootViewController = [[WBWebViewController alloc] initWithURL:URL];
    [self.navigationController pushViewController:rootViewController animated:YES];
}

@end
