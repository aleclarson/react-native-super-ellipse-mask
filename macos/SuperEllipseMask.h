#import <AppKit/AppKit.h>

@class RCTEventDispatcher;

@interface SuperEllipseMask : NSView

@property (nonatomic, assign) CGFloat topLeft;
@property (nonatomic, assign) CGFloat topRight;
@property (nonatomic, assign) CGFloat bottomRight;
@property (nonatomic, assign) CGFloat bottomLeft;


- (instancetype)initWithFrame:(CGRect)frame
NS_DESIGNATED_INITIALIZER;

@end
