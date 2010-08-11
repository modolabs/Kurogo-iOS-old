#import "MITCalendarEvent.h"
#import "EventCategory.h"
#import "CalendarDataManager.h"
#import "CoreDataManager.h"

@implementation MITCalendarEvent 

@dynamic location;
@dynamic latitude;
@dynamic longitude;
@dynamic shortloc;
@dynamic start;
@dynamic end;
@dynamic eventID;
@dynamic title;
@dynamic phone;
@dynamic summary;
@dynamic url;
@dynamic ticketUrl;
@dynamic email;
@dynamic categories;
@dynamic lastUpdated;
@dynamic isRegular;

- (NSString *)subtitle
{
	NSString *dateString = [self dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
	
	if (self.shortloc) {
		return [NSString stringWithFormat:@"%@ | %@", dateString, self.shortloc];
	} else {
		return dateString;
	}	
}

- (NSString *)dateStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle separator:(NSString *)separator {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSMutableArray *parts = [NSMutableArray arrayWithCapacity:2];
	if (dateStyle != NSDateFormatterNoStyle) {
		
		[formatter setDateStyle:dateStyle];
		
		NSString *dateString = [formatter stringFromDate:self.start];
		if ([self.end timeIntervalSinceDate:self.start] >= 86400.0) {
			dateString = [NSString stringWithFormat:@"%@-%@", dateString, [formatter stringFromDate:self.end]];
		}
		
		[parts addObject:dateString];
		[formatter setDateStyle:NSDateFormatterNoStyle];
	}
	
	if (timeStyle != NSDateFormatterNoStyle) {
		[formatter setTimeStyle:timeStyle];
		NSString *timeString = nil;
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *startComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.start];
		NSDateComponents *endComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.end];
		
		
		NSTimeInterval interval = [self.end timeIntervalSinceDate:self.start];
	
		if (startComps.hour == 0 && startComps.minute == 0 && endComps.hour == 0 && endComps.minute == 0) {
			timeString = [NSString string];
		} else if (interval == 0) {
			timeString = [formatter stringFromDate:self.start];
		} else if (interval == 86340.0) { // seconds between 12:00am and 11:59pm
			timeString = [NSString stringWithString:@"All day"];
		} else if ((int)interval%86400 <= 60) {
			timeString = [formatter stringFromDate:self.start];
		}else if ((int)(interval)%86400 > 86330)  {// if the interval is almost a multiple of 24 hrs
			timeString = [NSString stringWithString:@"All day"];
		}
		else {
			timeString = [NSString stringWithFormat:@"%@-%@", [formatter stringFromDate:self.start], [formatter stringFromDate:self.end]];
		}

		[parts addObject:timeString];
	}
	
	[formatter release];
	
	return [parts componentsJoinedByString:separator];
}

- (BOOL)hasCoords
{
    return ([self.latitude doubleValue] != 0);
}

- (void)updateWithDict:(NSDictionary *)dict
{
	self.eventID = [NSNumber numberWithInt:[[dict objectForKey:@"id"] intValue]];	
	self.start = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"start"] doubleValue]];
	self.end = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"end"] doubleValue]];
	
	
	NSDictionary *contactInfo; // to be extracted from the "custom" trumba fields
	BOOL contactInfoAvailable = NO;
	NSString *locationDetail;
	BOOL locationDetailAvailable = NO;

	NSMutableString *description = [NSMutableString string];
	// formatting the string to be html friendly
	if ([dict objectForKey:@"description"])
		description = [NSMutableString stringWithFormat:@"%@<br /><br />",[dict objectForKey:@"description"]];
	
	
	NSDictionary *customDict = nil;
	
	
	 if (customDict = [dict objectForKey:@"custom"]) 
	 {
	 NSArray *fields = nil;
	 fields = [customDict allKeys];
	 
	 for (int j=0; j <[fields count]; j++)
	 {
	 NSString *fieldKeyString = [fields objectAtIndex:j];
	 
	 NSString *fieldValueString= [[customDict objectForKey:fieldKeyString] description];
	 fieldKeyString = [fieldKeyString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
	 fieldValueString = [fieldValueString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
	 
	 if (![fieldKeyString isEqualToString:@"Location"] && 
		 ![fieldKeyString isEqualToString:@"Event Type"] &&
		 ![fieldKeyString isEqualToString:@"Contact Info"] &&
		 ![fieldKeyString isEqualToString:@"Ticket Web Link"] &&
		 ![fieldKeyString isEqualToString:@"Gazette Classification"]) 
	 {
	 
	 fieldKeyString = [NSString stringWithFormat:@"<b><u>%@</b></u>", fieldKeyString];
	 [description appendString:fieldKeyString];
	 [description appendString:@": "];
	 [description appendString:fieldValueString];
	 description = [NSMutableString stringWithFormat:@"%@<br /><br />", description];
	 
	 }
	 }
	 
	 // use this oppoprtunity to extract contact info as well
	 if ([customDict objectForKey:@"\"Contact Info\""]) {
	 contactInfoAvailable = YES;
	 contactInfo = [customDict objectForKey:@"\"Contact Info\""];
	 }
	 
	 if ([customDict objectForKey:@"\"Location\""]) {
	 locationDetailAvailable = YES;
	 locationDetail = [customDict objectForKey:@"\"Location\""];
	 }
	 }

	self.title = [dict objectForKey:@"title"];	
	// optional strings
	NSString *maybeValue = [dict objectForKey:@"shortloc"];
	if (maybeValue.length > 0) {
		self.shortloc = maybeValue;
	}
	maybeValue = [dict objectForKey:@"location"];
	if (maybeValue.length > 0) {
		self.location = maybeValue;
	}
	
    // TODO: all fields below have conditional values that
    // are unconditionally overridden.  figure out which
    // values to use or get rid of the conditional statements.
    
	// Contact Info
	if (contactInfoAvailable == YES) {
		NSString *phoneNumber;
		if ([contactInfo valueForKey:@"phone"]) {
			
			// Only providing one phone number (the first) in case there are more coming in from the data-feed
			if ([[contactInfo valueForKey:@"phone"] class] == [NSArray class])
				phoneNumber =  [[[contactInfo valueForKey:@"phone"] objectAtIndex:0]description];
			
			phoneNumber = [[contactInfo valueForKey:@"phone"] description];
			NSArray *phoneNumberArray = [phoneNumber componentsSeparatedByString:@"\""];
			
			if ([phoneNumberArray count] == 3) {
				phoneNumber = [phoneNumberArray objectAtIndex:1];
				
				if (phoneNumber.length == 8) {
					phoneNumber = [NSString stringWithFormat:@"617-%@", phoneNumber];
				} else {
					// i'm seeing a lot of events use slashes to separate area code, not sure why
					phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"." withString:@"-"];
				}
				self.phone = phoneNumber;
			}
		}
		
		NSString *urlLink;
		if ([contactInfo valueForKey:@"url"]) {
			
			// Only providing one url-link (the first) in case there are more coming in from the data-feed
			if ([[contactInfo valueForKey:@"url"] class] == [NSArray class])
				urlLink =  [[[contactInfo valueForKey:@"url"] objectAtIndex:0]description];
			
			urlLink = [[contactInfo valueForKey:@"url"] description];
			NSArray *urlLinkArray = [urlLink componentsSeparatedByString:@"\""];
			
			if ([urlLinkArray count] == 3) {
				urlLink = [urlLinkArray objectAtIndex:1];
				self.url = urlLink;
			}
		}

		NSString *emailAdd;
		if ([contactInfo valueForKey:@"email"]) {
			
			// Only providing one url-link (the first) in case there are more coming in from the data-feed
			if ([[contactInfo valueForKey:@"email"] class] == [NSArray class])
				emailAdd =  [[[contactInfo valueForKey:@"email"] objectAtIndex:0]description];
			
			emailAdd = [[contactInfo valueForKey:@"email"] description];
			NSArray *emailArray = [emailAdd componentsSeparatedByString:@"\""];
			
			if ([emailArray count] == 3) {
				emailAdd = [emailArray objectAtIndex:1];
				self.email = emailAdd;
			}
		}
		
		NSMutableString *customContactText = [NSMutableString string];
		if ([contactInfo valueForKey:@"text"]) {
			
			// Only providing one url-link (the first) in case there are more coming in from the data-feed
			if ([[contactInfo valueForKey:@"text"] class] == [NSArray class])
			{
				for (int ind=0; ind < [[contactInfo valueForKey:@"text"] count]; ind++) {
					NSString *stringText = [[contactInfo valueForKey:@"text"] objectAtIndex:ind];
					NSArray *stringArray = [stringText componentsSeparatedByString:@"\""];
					
					if ([stringArray count] == 3)
						[customContactText appendString:stringText];
				}
				
			}
			
			else {
				NSString *stringText = [[contactInfo valueForKey:@"text"] description];
				NSArray *stringArray = [stringText componentsSeparatedByString:@"\""];
				
				if ([stringArray count] == 3)
					[customContactText appendString:stringText];
			}
			
			if ([customContactText length] > 0) {
			NSString *fieldName = [NSString stringWithFormat:@"<b><u>%@</b></u>", @"More Information"];

			[description appendString:fieldName];
			[description appendString:@": "];
			[description appendString:customContactText];
			description = [NSMutableString stringWithFormat:@"%@<br /><br />", description];
			}
		}		
	}

		self.summary = description;
	
	if ([dict objectForKey:@"url"]) {
		self.url = [dict objectForKey:@"url"];
	}

	if ([customDict objectForKey:@"\"Ticket Web Link\""]) {
		self.ticketUrl = [customDict objectForKey:@"\"Ticket Web Link\""];
	}
	
	if (locationDetailAvailable == YES) {
		NSArray *locDet = [locationDetail componentsSeparatedByString:@"<"];
		NSArray *latArray;
		NSArray *lonArray;
		int indexLat = [locDet indexOfObject:@"/Latitude>"];
		int indexLong = [locDet indexOfObject:@"/Longitude>"];
		
		if (indexLat > 0 && indexLong > 0)
		{
			latArray = [[locDet objectAtIndex:indexLat-1] componentsSeparatedByString:@">"];
			lonArray = [[locDet objectAtIndex:indexLong-1] componentsSeparatedByString:@">"];
			
			NSString *lat = (NSString *)[latArray objectAtIndex:1];
			NSString *lon = (NSString *)[lonArray objectAtIndex:1];
			
			self.latitude = [NSNumber numberWithDouble:[lat doubleValue]];
			self.longitude = [NSNumber numberWithDouble:[lon doubleValue]];
		}
		
	}
	
	if (customDict = [dict objectForKey:@"custom"]) 
	{
		NSArray *customFields = nil;
		
		customFields = [customDict allKeys];

		NSString *gazetteClassification = @"\"Gazette Classification\"";
		NSString *classificationString = [customDict objectForKey:gazetteClassification];
		
		NSArray *classificationArray = [classificationString componentsSeparatedByString: @"\\, "];
		
		for (int i=0; i < [classificationArray count]; i++) {
			NSString *catName	= [classificationArray objectAtIndex:i];
			
			NSString *subcat = [catName substringFromIndex:1];
			NSInteger cat_id = [[CalendarDataManager idForCategory:subcat] integerValue];
			EventCategory *category = [CalendarDataManager categoryWithID:cat_id];
			
			if (category.title == nil) {
                category.title = catName;
            }
			
            [self addCategory:category];
			
		}
	}
    
    self.lastUpdated = [NSDate date];
	[CoreDataManager saveData];
}

- (void)addCategory:(EventCategory *)category
{
    if (![self.categories containsObject:category]) {
        [self addCategoriesObject:category];
        
        NSInteger catID = [category.catID intValue];
        if (catID == kCalendarExhibitCategoryID
            || catID == kCalendarAcademicCategoryID
            || catID == kCalendarHolidayCategoryID) {
            
            self.isRegular = [NSNumber numberWithBool:NO];
        }
        
        [CoreDataManager saveData];
    }
}

/*
 - (NSString *)description
 {
 return self.title;
 }
 */
@end
