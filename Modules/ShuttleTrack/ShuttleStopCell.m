
#import "ShuttleStopCell.h"
#import "ShuttleStop.h"
#import "MITUIConstants.h"

@implementation ShuttleStopCell
@synthesize urlForImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


-(void) setShuttleInfo:(ShuttleStop*)shuttleStop image:(UIImage *)image
{
	_shuttleNameLabel.text = shuttleStop.title;
	
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"h:mm a"];
	
	_shuttleTimeLabel.text = [formatter stringFromDate:shuttleStop.nextScheduledDate];

	if (shuttleStop.upcoming) 
	{
		//NSURL *urlLink = [NSURL URLWithString:urlLinkForImage];
		// NSData *data = [NSData dataWithContentsOfURL:urlLink];
		//_shuttleStopImageView.image = [[UIImage alloc] initWithData:data];
		
		//self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height + 12.0);
		
		if (image != nil)
			_shuttleStopImageView.image = image;
		else
		_shuttleStopImageView.image = [UIImage imageNamed:@"shuttle-stop-dot-next.png"] ;
		
		_shuttleTimeLabel.textColor = SEARCH_BAR_TINT_COLOR;
        _shuttleTimeLabel.font = [UIFont boldSystemFontOfSize:16.0];
		_shuttleNextLabel.text = @"Arriving next at: ";
		
		_shuttleStopImageView.frame = CGRectMake(_shuttleStopImageView.frame.origin.x, _shuttleStopImageView.frame.origin.y + 5, _shuttleStopImageView.frame.size.width, _shuttleStopImageView.frame.size.height);
		_shuttleNameLabel.frame = CGRectMake(_shuttleNameLabel.frame.origin.x, _shuttleNameLabel.frame.origin.y + 5, _shuttleNameLabel.frame.size.width, _shuttleNameLabel.frame.size.height);
		_shuttleNextLabel.frame = CGRectMake(_shuttleNextLabel.frame.origin.x, _shuttleNextLabel.frame.origin.y + 5, _shuttleNextLabel.frame.size.width, _shuttleNextLabel.frame.size.height);
		_shuttleTimeLabel.frame = CGRectMake(_shuttleTimeLabel.frame.origin.x, _shuttleTimeLabel.frame.origin.y + 5, _shuttleTimeLabel.frame.size.width, _shuttleTimeLabel.frame.size.height);

	}
	else 
	{
		//_shuttleStopImageView.image = [UIImage imageNamed:@"shuttle-stop-dot.png"];
		_shuttleTimeLabel.textColor = [UIColor blackColor];
        _shuttleTimeLabel.font = [UIFont systemFontOfSize:16.0];
		_shuttleNameLabel.frame = CGRectMake(_shuttleNameLabel.frame.origin.x, _shuttleNameLabel.frame.origin.y - 5, _shuttleNameLabel.frame.size.width, _shuttleNameLabel.frame.size.height);
	}
}

@end
