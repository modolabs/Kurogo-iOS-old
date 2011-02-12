#import <UIKit/UIKit.h>

@class DatePickerViewController;

@protocol DatePickerViewControllerDelegate<NSObject>

- (void)datePickerViewControllerDidCancel:(DatePickerViewController *)controller;
- (void)datePickerViewController:(DatePickerViewController *)controller didSelectDate:(NSDate *)date;
- (void)datePickerViewController:(DatePickerViewController *)controller valueChanged:(NSDate *)date;

@end


@interface DatePickerViewController : UIViewController {
    
    NSDate *_date;
    id<DatePickerViewControllerDelegate> delegate;
    
    UIDatePicker *datePicker;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *doneButton;
}

- (void)navBarButtonPressed:(id)sender;

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, assign) id<DatePickerViewControllerDelegate> delegate;
@property (nonatomic, retain) UIDatePicker *datePicker;

@end
