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

-(id) initWithRepoName:(NSString *)name 
		   identityTag:(NSString *) idTag 
				  type:(NSString *)type
				   lib: (Library *) lib
{
	if (self = [super init]) {
		repoNameToDisplay = name;
		repoId = idTag;
		repoType = type;
		
		_library = [lib retain];
	}
	
	return self;
}

-(void) dealloc
{
	[_library dealloc];
	[super dealloc];
}

-(CLLocationCoordinate2D) coordinate
{
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = [_library.lat doubleValue];
	coordinate.longitude = [_library.lon doubleValue];
	
	return coordinate;
}

-(NSString*) title
{
	return repoNameToDisplay;
}

-(NSString*) subtitle
{
	return _subtitle;
}

-(void) setSubtitle:(NSString*)subtitle
{
	[_subtitle release];
	_subtitle = [subtitle retain];
}

@end
