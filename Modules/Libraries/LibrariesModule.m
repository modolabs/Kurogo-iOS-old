//
//  LibrariesModule.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/15/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibrariesModule.h"
#import "LibrariesMainViewController.h"


@implementation LibrariesModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = LibrariesTag;
        self.shortName = @"Libraries";
        self.longName = @"Libraries";
        self.iconName = @"libraries"; // needs to be changed
        
        LibrariesMainViewController *aboutVC = [[[LibrariesMainViewController alloc] init] autorelease];
        aboutVC.title = self.longName;
		
        self.viewControllers = [NSArray arrayWithObject:aboutVC];
		
    }
    return self;
}

@end
