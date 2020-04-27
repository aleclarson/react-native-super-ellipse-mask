#import <Foundation/Foundation.h>
#import <React/RCTView.h>

@interface SuperEllipseMask : RCTView

@property (nonatomic, assign) CGFloat topLeft;
@property (nonatomic, assign) CGFloat topRight;
@property (nonatomic, assign) CGFloat bottomRight;
@property (nonatomic, assign) CGFloat bottomLeft;

@property (nonatomic, readonly) NSBezierPath *path;

- (instancetype)initWithFrame:(CGRect)frame
NS_DESIGNATED_INITIALIZER;

@end
