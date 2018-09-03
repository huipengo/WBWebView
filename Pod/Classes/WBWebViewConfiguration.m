//
//  WBWebViewConfiguration.m
//  WBKit_Example
//
//  Created by penghui8 on 2018/7/9.
//  Copyright © 2018年 huipengo. All rights reserved.
//

#import "WBWebViewConfiguration.h"

@implementation WBWebViewConfiguration

+ (instancetype)defaultConfiguration {
    return [[[self class] alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferences.minimumFontSize = 9.0;
        if ([self respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
            [self setAllowsInlineMediaPlayback:YES];
        }
        if (@available(iOS 9.0, *)) {
            if ([self respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {
                [self setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
            }
        } else {
            // Fallback on earlier versions
        }
        
        if (@available(iOS 10.0, *)) {
            if ([self respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]){
                [self setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
            }
        } else if (@available(iOS 9.0, *)) {
            if ( [self respondsToSelector:@selector(setRequiresUserActionForMediaPlayback:)]) {
                [self setRequiresUserActionForMediaPlayback:NO];
            }
        }
    }
    return self;
}

@end
