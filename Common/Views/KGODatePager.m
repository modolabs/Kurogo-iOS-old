#import "KGODatePager.h"
#import "KGOTheme.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"

@implementation KGODatePager

@synthesize delegate, contentsController;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        self.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForDatePager];
        self.incrementUnit = NSDayCalendarUnit;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{    
    self = [super initWithFrame:frame];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        self.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForDatePager];
        self.incrementUnit = NSDayCalendarUnit;
    }
    return self;
}

- (void)dealloc {
    [_dateFormatter release];
    [super dealloc];
}

// TODO: get config values for assets
- (void)layoutSubviews {

    if (!nextButton) {
        UIImage *dropShadowImage = [[[KGOTheme sharedTheme] backgroundImageForSearchBarDropShadow] stretchableImageWithLeftCapWidth:5
                                                                                                                       topCapHeight:5];
        if (dropShadowImage) {
            UIImageView *dropShadow = [[[UIImageView alloc] initWithImage:dropShadowImage] autorelease];
            dropShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            dropShadow.frame = CGRectMake(0, self.frame.size.height, dropShadow.frame.size.width, dropShadow.frame.size.height);
            [self addSubview:dropShadow];
            self.clipsToBounds = NO;
        }
        
        // arrow buttons
        nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonImage = [UIImage imageWithPathName:@"common/subheadbar_button_next"];
        
        CGFloat halfHeight = floor(self.frame.size.height / 2);
        CGFloat originX = self.frame.size.width - halfHeight;
        
        nextButton.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        nextButton.center = CGPointMake(originX, halfHeight);
        [nextButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [nextButton setBackgroundImage:[UIImage imageWithPathName:@"common/subheadbar_button_next_pressed"] forState:UIControlStateHighlighted];
        [nextButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:nextButton];
        originX -= buttonImage.size.width;
        
        prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonImage = [UIImage imageWithPathName:@"common/subheadbar_button_previous"];
        prevButton.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        prevButton.center = CGPointMake(originX, halfHeight);
        [prevButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [prevButton setBackgroundImage:[UIImage imageWithPathName:@"common/subheadbar_button_previous_pressed"] forState:UIControlStateHighlighted];
        [prevButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:prevButton];
        
        // calendar button
        buttonImage = [UIImage imageWithPathName:@"common/subheadbar_button"];
        calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        calendarButton.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        calendarButton.center = CGPointMake(halfHeight, halfHeight);
        [calendarButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [calendarButton setBackgroundImage:[UIImage imageWithPathName:@"common/subheadbar_button_pressed"] forState:UIControlEventTouchUpInside];
        [calendarButton setImage:[UIImage imageWithPathName:@"common/subheadbar_calendar"] forState:UIControlStateNormal];
        [calendarButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:calendarButton];
        
        // date label
        dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // TODO: make this configurable or use system font
        dateButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18.0];
        dateButton.titleLabel.textColor = [UIColor whiteColor];
        dateButton.titleLabel.textAlignment = UITextAlignmentCenter;
        dateButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        
        NSString *dateText = [_dateFormatter stringFromDate:_displayDate];
        [dateButton setTitle:dateText forState:UIControlStateNormal];

        // width of date label should be such that when date label is centered, it doesn't overlap the prev/next buttons
        CGFloat dateButtonWidth = 2 * prevButton.frame.origin.x - self.frame.size.width;
        CGFloat xOrigin = floor((self.frame.size.width - dateButtonWidth) / 2);
        dateButton.frame = CGRectMake(xOrigin, 0.0, dateButtonWidth, self.frame.size.height);

        [dateButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:dateButton];
    }
    
}

- (void)buttonPressed:(id)sender {
    if (sender == calendarButton || sender == dateButton) {
        DatePickerViewController *pickerVC = [[[DatePickerViewController alloc] init] autorelease];
        pickerVC.delegate = self;
        pickerVC.date = self.date;
        
        [self.contentsController presentModalViewController:pickerVC animated:YES];
        
    } else {
        // previous or next date
        NSInteger offset = (sender == prevButton) ? -1 : 1;
        NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
        if (_incrementUnit & NSDayCalendarUnit)   [components setDay:offset];
        if (_incrementUnit & NSWeekCalendarUnit)  [components setWeek:offset];
        if (_incrementUnit & NSMonthCalendarUnit) [components setMonth:offset];
        if (_incrementUnit & NSYearCalendarUnit)  [components setYear:offset];
        
        self.date = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self.date options:0];
    }
}


- (NSDate *)displayDate {
    return _displayDate;
}

- (void)setDisplayDate:(NSDate *)aDate {
    if (![_displayDate isEqualToDate:aDate]) {
        [_displayDate release];
        _displayDate = [aDate retain];
        
        NSString *dateText = [_dateFormatter stringFromDate:_displayDate];
        [dateButton setTitle:dateText forState:UIControlStateNormal];
    }
}

- (NSDate *)date {
    return _date;
}

- (void)setDate:(NSDate *)aDate {
    if (![_date isEqualToDate:aDate]) {
        [_date release];
        _date = [aDate retain];
        self.displayDate = aDate;
        [self.delegate pager:self didSelectDate:_date];
    }
}

- (NSCalendarUnit)incrementUnit {
    return _incrementUnit;
}

- (void)setIncrementUnit:(NSCalendarUnit)unitFlags {
    _incrementUnit = unitFlags;
    if (_incrementUnit & NSDayCalendarUnit)        [_dateFormatter setDateFormat:@"EEEE M/d"];
    else if (_incrementUnit & NSWeekCalendarUnit)  [_dateFormatter setDateFormat:@"EEEE M/d"];
    else if (_incrementUnit & NSMonthCalendarUnit) [_dateFormatter setDateFormat:@"yyyy MMM"];
    else if (_incrementUnit & NSYearCalendarUnit)  [_dateFormatter setDateFormat:@"yyyy"];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

#pragma mark DatePickerViewControllerDelegate functions

- (void)datePickerViewControllerDidCancel:(DatePickerViewController *)controller {
    self.displayDate = self.date;
    [self.contentsController dismissModalViewControllerAnimated:YES];
}

- (void)datePickerViewController:(DatePickerViewController *)controller didSelectDate:(NSDate *)date {
    self.date = date;
    
    [self.contentsController dismissModalViewControllerAnimated:YES];
}

- (void)datePickerViewController:(DatePickerViewController *)controller valueChanged:(NSDate *)date {
    self.displayDate = date;
}


@end
