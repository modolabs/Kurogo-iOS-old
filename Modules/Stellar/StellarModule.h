//
//  StellarAppDelegate.h
//  Stellar
//
//  Created by Brian Patt on 12/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MITModule.h"

@interface StellarModule : MITModule {

	UINavigationController *navigationController;
}

@property (nonatomic, retain) UINavigationController *navigationController;

@end

