//
//  ItemAvailabilityLibraryAnnotation.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/10/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "ItemAvailabilityLibraryAnnotation.h"


@implementation ItemAvailabilityLibraryAnnotation
@synthesize repoNameToDisplay;
@synthesize repoId;
@synthesize repoType;
@synthesize library = _library;
@synthesize subtitle = _subtitle;

/*
-(id) initWithRepoName:(NSString *)name 
		   identityTag:(NSString *) idTag 
				  type:(NSString *)type
				   lib: (Library *) lib
{
	if (self = [super init]) {
		repoNameToDisplay = [name retain];
		repoId = [idTag retain];
		repoType = [type retain];
		
		_library = [lib retain];
	}
	
	return self;
}
*/

- (id)initWithLibAlias:(LibraryAlias *)libAlias {
    if (self = [super init]) {
        _libAlias = libAlias;
    }
    return self;
}

-(void) dealloc
{
	[_libAlias release];
	[super dealloc];
}

-(CLLocationCoordinate2D) coordinate
{
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = [_libAlias.library.lat doubleValue];
	coordinate.longitude = [_libAlias.library.lon doubleValue];
	
	return coordinate;
}

-(NSString*) title
{
	return repoNameToDisplay;
}

@end
