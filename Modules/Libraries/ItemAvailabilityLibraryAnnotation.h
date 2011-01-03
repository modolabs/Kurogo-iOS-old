//
//  ItemAvailabilityLibraryAnnotation.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/10/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Library.h"
#import <CoreLocation/CoreLocation.h>

@class LibraryAlias;

@interface ItemAvailabilityLibraryAnnotation : NSObject <MKAnnotation> {
	
	//NSString * repoNameToDisplay;
	//NSString * repoId;
	//NSString * repoType;
	
	LibraryAlias* _libAlias;
	
	
	NSString* _subtitle;
}

-(id) initWithLibAlias: (LibraryAlias *) lib;

//@property (nonatomic, readonly) NSString * repoNameToDisplay;
//@property (nonatomic, readonly) NSString * repoId;
//@property (nonatomic, readonly) NSString * repoType;
@property (nonatomic, readonly) LibraryAlias * libAlias;
@property (nonatomic, retain) NSString * subtitle;

@end
