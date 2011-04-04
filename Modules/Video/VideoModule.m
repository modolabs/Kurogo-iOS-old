//
//  VideoModule.m
//  Universitas
//
//  Created by Jim Kang on 3/29/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "VideoModule.h"
#import "VideoListViewController.h"

@implementation VideoModule

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[VideoListViewController alloc]  
               initWithStyle:UITableViewStylePlain] 
              autorelease];        
    } 
    else if ([pageName isEqualToString:LocalPathPageNameSearch]) {        
        // TODO.
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        // TODO.
    }
    return vc;
}

@end
