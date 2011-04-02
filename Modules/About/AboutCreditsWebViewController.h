//
//  AboutCreditsWebViewController.h
//  Universitas
//
//  Created by Muhammad J Amjad on 4/1/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KGOWebViewController.h"


@interface AboutCreditsWebViewController : KGOWebViewController {
    
    NSString * creditsHTMLString;
    
}

@property (nonatomic, assign) NSString * creditsHTMLString;

@end
