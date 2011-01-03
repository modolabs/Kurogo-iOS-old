//
//  LibraryAnnotation.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Library.h"
#import <CoreLocation/CoreLocation.h>

@interface LibraryAnnotation : NSObject <MKAnnotation> {

	LibraryAlias* _libAlias;
	
	NSString* _subtitle;
}

-(id) initWithLibrary:(LibraryAlias*) _libAlias;

@property (readonly) LibraryAlias* libAlias;

@property (nonatomic, retain) NSString * subtitle;

@end
