//
//  LibraryAnnotation.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryAnnotation.h"


@implementation LibraryAnnotation
@synthesize library = _library;

-(id) initWithLibrary:(Library*)library
{
	if (self = [super init]) {
		_library = [library retain];
	}
	
	return self;
}

-(void) dealloc
{
	[_library release];
	
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
	return _library.name;
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
