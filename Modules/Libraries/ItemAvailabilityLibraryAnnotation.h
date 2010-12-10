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


@interface ItemAvailabilityLibraryAnnotation : NSObject <MKAnnotation> {
	
	NSString * repoNameToDisplay;
	NSString * repoId;
	NSString * repoType;
	
	Library* _library;
	
	
	NSString* _subtitle;
}

-(id) initWithRepoName:(NSString *)name 
		   identityTag:(NSString *) idTag 
				  type:(NSString *)type
				   lib: (Library *) lib;

@property (readonly) NSString * repoNameToDisplay;
@property (readonly) NSString * repoId;
@property (readonly) NSString * repoType;
@property (readonly) Library* library;


-(void) setSubtitle:(NSString*) subtitle;

@end
