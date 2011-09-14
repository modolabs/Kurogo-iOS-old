//
//  VideoModule.m
//  Universitas
//
//  Created by Jim Kang on 3/29/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "VideoModule.h"
#import "VideoListViewController.h"

NSString * const KGODataModelNameVideo = @"Video";

@implementation VideoModule

@synthesize dataManager;
//@synthesize currentSearchResults;
@synthesize searchSection;

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
        // FIXME
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        // FIXME
    }
    return vc;
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:KGODataModelNameVideo];
}


#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES; // TODO: Make search optionally not hit network if we can tell it's federated search.
}

- (void)performSearchWithText:(NSString *)searchText 
                       params:(NSDictionary *)params 
                     delegate:(id<KGOSearchResultsHolder>)delegate {
    
    self.searchDelegate = delegate;
//    self.currentSearchResults = nil;
    
    if (!self.dataManager) {
        self.dataManager = [[[VideoDataManager alloc] init] autorelease];
    }
    
    // TODO: Get section
    __block VideoModule *blockSelf = self;
    [self.dataManager requestSearchOfSection:self.searchSection 
                                       query:searchText
                                thenRunBlock:^(id result) {
                                    if ([result isKindOfClass:[NSArray class]])
                                    {
                                        [blockSelf.searchDelegate receivedSearchResults:result
                                                                              forSource:blockSelf.shortName];
                                    }
                                }];
}

- (void)dealloc {
//    [currentSearchResults release];
    [dataManager release];
    [super dealloc];
}

@end
