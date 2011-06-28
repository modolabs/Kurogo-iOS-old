//
//  LinksModule.m
//  Universitas
//
//  Created by Muhammad J Amjad on 6/28/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "LinksModule.h"
#import "LinksTableViewController.h"


@implementation LinksModule


- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        
        LinksTableViewController * linksVC = [[[LinksTableViewController alloc] initWithModuleTag:self.tag] autorelease];
        
        KGORequest *feedRequest = [[KGORequestManager sharedManager] requestWithDelegate:linksVC                          
                                                                                  module:self.tag                            
                                                                                    path:@"index"                           
                                                                                  params:params];
        
        [feedRequest connect];
        feedRequest.expectedResponseType = [NSDictionary class];
        
        vc = linksVC;
    }
    return vc;
}

@end
