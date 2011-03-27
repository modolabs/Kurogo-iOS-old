//
//  AdmissionsModule.m
//  Universitas
//
//  Created by Muhammad J Amjad on 3/27/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "AdmissionsModule.h"
#import "AdmissionsViewController.h"

@implementation AdmissionsModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[AdmissionsViewController alloc] initWithStyle:UITableViewStyleGrouped moduleTag:AdmissionsTag] autorelease];
    }
    return vc;
}
@end
