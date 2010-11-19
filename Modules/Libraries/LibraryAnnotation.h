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

	Library* _library;
	
	NSString* _subtitle;
}

-(id) initWithLibrary:(Library*) library;

@property (readonly) Library* library;

-(void) setSubtitle:(NSString*) subtitle;

@end
