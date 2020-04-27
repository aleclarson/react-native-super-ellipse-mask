#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>

#import "SuperEllipseMask.h"
#import "SuperEllipseMaskManager.h"

@implementation SuperEllipseMaskManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (NSView *)view
{
    return [[SuperEllipseMask alloc] initWithFrame:NSZeroRect];
}

RCT_EXPORT_VIEW_PROPERTY(topLeft, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(topRight, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(bottomRight, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(bottomLeft, CGFloat)

@end
