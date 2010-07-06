//
//  diningTempAppDelegate.h
//  diningTemp
//
//  Created by Muhammad Amjad on 6/23/10.
//  Copyright Modo Labs 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface diningTempAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UINavigationController *navController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;


@end

