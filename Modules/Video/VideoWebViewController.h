//
//  VideoWebViewController.h
//  Universitas
//
//  Created by Jim Kang on 4/5/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VideoWebViewController : UIViewController {

}

- (id)initWithURL:(NSURL *)theURL;

@property (nonatomic, retain) NSURL *URL;

@end
