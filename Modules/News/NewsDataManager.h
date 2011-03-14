#import <Foundation/Foundation.h>
#import "KGORequestManager.h"
#import "NewsCategory.h"

@protocol NewsCategoriesDelegate <NSObject>
+ (void) categoriesUpdated:(NSArray *)categories;
@end

@interface NewsDataManager : NSObject<KGORequestDelegate> {
    id<NewsCategoriesDelegate> categoriesDelegate;
}

@property (nonatomic, retain) id<NewsCategoriesDelegate> categoriesDelegate;

+ (NewsDataManager *)sharedManager;

- (void)requestCategories:(id<NewsCategoriesDelegate>)delegate;

@end
