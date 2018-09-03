//
//  WBWKUIDelegate.h
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/6.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WBWKUIDelegateImpl : NSObject <WKUIDelegate>

@property (nonatomic, copy, nullable) NSString *title;

- (instancetype)init;
- (instancetype)initWithTitle:(NSString*__nullable)title;

@end

NS_ASSUME_NONNULL_END
