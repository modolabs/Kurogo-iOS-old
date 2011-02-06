#import "HighlightedResultLabel.h"
#import "Foundation+MITAdditions.h"

@implementation HighlightedResultLabel

@synthesize font = _font, boldFont = _boldFont,
textColor = _textColor, highlightedTextColor = _highlightedTextColor,
text = _text;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		self.textColor = [UIColor blackColor];
		self.highlightedTextColor = [UIColor whiteColor];
		self.font = [UIFont systemFontOfSize:17];
		self.boldFont = [UIFont boldSystemFontOfSize:17];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    for (UIView *aView in self.subviews) {
        if ([aView isKindOfClass:[UILabel class]]) {
            [(UILabel *)aView setHighlighted:highlighted];
        }
    }
}

- (void)setSearchTokens:(NSArray *)tokens {
    [_searchTokens release];

    _searchTokens = [[tokens sortedArrayUsingBlock:^(id a, id b, void *context) {
        NSInteger lenA = [(NSString *)a length];
        NSInteger lenB = [(NSString *)b length];
        if (lenA < lenB)
            return NSOrderedDescending; // we want long strings first
        else if (lenA > lenB)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    } context:NULL] retain];
}

- (NSArray *)searchTokens {
    return _searchTokens;
}

- (BOOL)highlighted {
    return _highlighted;
}

static int rangeCompare(const void * a, const void * b) {
    NSRange *rangeA = (NSRange *)a;
    NSRange *rangeB = (NSRange *)b;
    return rangeA->location - rangeB->location;
}


// TODO: add subviews when when searchtokens are set
- (void)layoutSubviews {
    if (!_labels) {
        
        NSInteger numTokens = self.searchTokens.count;
        NSInteger numLetters = self.text.length;
        if (!numLetters) return;
        
        NSRange *foundRanges = malloc(numTokens * sizeof(NSRange));
        NSInteger numFoundRanges = 0;
        
        // create an unordered list of all NSRanges that should be highlighted
        NSString *lcString = [self.text lowercaseString];
        for (NSInteger tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
            NSString *aToken = [[self.searchTokens objectAtIndex:tokenIndex] lowercaseString];
            if (!aToken.length) continue;
            
            NSRange foundRange = [lcString rangeOfString:aToken];
            if (foundRange.location == NSNotFound) {
                continue;
            }
            
            BOOL doesConflict = NO;
            NSInteger endOfFoundRange;
            NSInteger endOfTargetRange;
            for (NSInteger rangeIndex = 0; rangeIndex < numFoundRanges; rangeIndex++) {
                endOfFoundRange = foundRange.location + foundRange.length;
                endOfTargetRange = foundRanges[rangeIndex].location + foundRanges[rangeIndex].length;
                if ((foundRange.location >= foundRanges[rangeIndex].location && foundRange.location < endOfTargetRange) // start of found range is within another found range
                    || (endOfFoundRange >= foundRanges[rangeIndex].location && endOfFoundRange < endOfTargetRange)) // end of found range is within another found range
                {
                    doesConflict = YES;
                    break;
                }
            }
            
            if (!doesConflict) {
                foundRanges[numFoundRanges] = foundRange;
                numFoundRanges++;
            }
        }
        
        NSRange *filteredRanges = malloc(numFoundRanges * sizeof(NSRange));
        for (NSInteger i = 0; i < numFoundRanges; i++) {
            filteredRanges[i] = foundRanges[i];
        }
        free(foundRanges);
        qsort(filteredRanges, numFoundRanges, sizeof(NSRange), rangeCompare);
        
        NSRange currentRange = NSMakeRange(0, 0);
        CGSize size;
        CGFloat currentX = 0;
        NSMutableArray *labels = [NSMutableArray array];
        
        for (NSInteger i = 0; i < numFoundRanges; i++) {
            currentRange.length = filteredRanges[i].location - currentRange.location;

			NSString *string;
			
            if (currentRange.length) {
				string = [self.text substringWithRange:currentRange];
				size = [string sizeWithFont:self.font];
				UILabel *normalLabel = [[[UILabel alloc] initWithFrame:CGRectMake(currentX, 0.0f, size.width, size.height)] autorelease];
				normalLabel.text = string;
				normalLabel.font = self.font;
				normalLabel.textColor = self.textColor;
				normalLabel.highlightedTextColor = self.highlightedTextColor;
				normalLabel.backgroundColor = [UIColor clearColor];
				[labels addObject:normalLabel];
				currentX += size.width;
			}
            
            currentRange = filteredRanges[i];
            
            string = [self.text substringWithRange:filteredRanges[i]];
            size = [string sizeWithFont:self.boldFont];
            UILabel *boldLabel = [[[UILabel alloc] initWithFrame:CGRectMake(currentX, 0.0f, size.width, size.height)] autorelease];
            boldLabel.font = self.boldFont;
            boldLabel.textColor = self.textColor;
            boldLabel.highlightedTextColor = self.highlightedTextColor;
            boldLabel.backgroundColor = [UIColor clearColor];
            boldLabel.text = string;
            [labels addObject:boldLabel];
            currentX += size.width;
            
            currentRange.location = filteredRanges[i].location + filteredRanges[i].length;
        }
        
        free(filteredRanges);
        
        if (currentX < self.frame.size.width && currentRange.location < numLetters) {
            currentRange.length = numLetters - currentRange.location;
            NSString *string = [self.text substringWithRange:currentRange];
            size = [string sizeWithFont:self.font];
            UILabel *normalLabel = [[[UILabel alloc] initWithFrame:CGRectMake(currentX, 0.0f, size.width, size.height)] autorelease];
            normalLabel.text = string;
            normalLabel.font = self.font;
            normalLabel.textColor = self.textColor;
            normalLabel.highlightedTextColor = self.highlightedTextColor;
            normalLabel.backgroundColor = [UIColor clearColor];
            [labels addObject:normalLabel];
            currentX += size.width;
        }
        
        if (currentX >= self.frame.size.width) {
            UILabel *lastLabel = [labels lastObject];
            CGRect frame = lastLabel.frame;
            currentX -= frame.size.width;
            
            NSString *text = lastLabel.text;
            while (text.length > 0) {
                text = [text substringToIndex:text.length - 1];
                size = [[NSString stringWithFormat:@"%@...", text] sizeWithFont:lastLabel.font];
                if (currentX + size.width < self.frame.size.width) {
                    break;
                }
            }
            
            lastLabel.text = [NSString stringWithFormat:@"%@...", text];
            frame.size.width = size.width;
            lastLabel.frame = frame;
        }
        
        _labels = [[NSArray alloc] initWithArray:labels];
    }
    
    for (UILabel *aLabel in _labels) {
        if (![aLabel isDescendantOfView:self]) {
            [self addSubview:aLabel];
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [_labels release];

    self.font = nil;
    self.boldFont = nil;
    self.textColor = nil;
    self.highlightedTextColor = nil;
    
    self.text = nil;
    self.searchTokens = nil;
    
    [super dealloc];
}

@end
