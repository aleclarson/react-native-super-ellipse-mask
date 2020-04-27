#import <QuartzCore/QuartzCore.h>
#import <React/NSView+React.h>
#import <React/RCTBorderDrawing.h>
#import <React/NSBezierPath+CGPath.h>
#import <React/UIImageUtils.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

#import "SuperEllipseMask.h"

const CGFloat coeff = 1.28195;

@implementation SuperEllipseMask
{
    CAShapeLayer *_mask;
    NSBezierPath *_path;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _mask = [CAShapeLayer new];
        _mask.frame = frame;
        _mask.fillColor = [NSColor blackColor].CGColor;
        
        [self ensureLayerExists];
        self.layer.opaque = false;
        self.layer.mask = _mask;
    }
    
    return self;
}

- (NSBezierPath *)path
{
    if (_path == nil) {
        _path = [self createSuperEllipsePath:self.bounds radii:self.cornerRadii];
    }
    return _path;
}

#pragma mark - setTopLeft, setTopRight, etc

#define setCornerRadius(GET, SET) \
  - (void)set##SET:(CGFloat)value \
  { \
      if (_##GET == value) { \
          return; \
      } \
      _##GET = value;  \
      _path = nil;  \
  }

setCornerRadius(topLeft, TopLeft)
setCornerRadius(topRight, TopRight)
setCornerRadius(bottomLeft, BottomLeft)
setCornerRadius(bottomRight, BottomRight)

#pragma mark - Overrides

// @override
- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];

    _mask.frame = self.bounds;
    _path = nil;
    [self.layer setNeedsDisplay];
}

// @override
- (NSImage *)createBorderImage:(NSSize)size
                   cornerRadii:(RCTCornerRadii)cornerRadii
                  borderInsets:(NSEdgeInsets)borderInsets
                  borderColors:(RCTBorderColors)borderColors
{
    if (!RCTBorderColorsAreEqual(borderColors) || !RCTBorderInsetsAreEqual(borderInsets)) {
      RCTLogWarn(@"Unsupported border style. Border must have equal colors and widths.");
      return nil;
    }

    NSColor *bgColor = self.backgroundColor;
    BOOL opaque =
      bgColor.alphaComponent == 1.0 &&
        (self.clipsToBounds ||
          !RCTCornerRadiiAreAboveThreshold(cornerRadii));

    UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0);

    CGFloat borderWidth = borderInsets.top;
    NSColor *borderColor = borderColors.top
      ? [NSColor colorWithCGColor:borderColors.top]
      : NSColor.clearColor;

    // The area within the border, excluding the border width.
    NSRect borderRect = {
      {borderWidth, borderWidth},
      {size.width - borderWidth, size.height - borderWidth}
    };

    // TODO: Is this the proper equation for border-radius scaling?
    CGFloat scale = borderRect.size.width / size.width;
    RCTCornerRadii radii = [self cornerRadiiWithSize:borderRect.size
                                               radii:(RCTCornerRadii){
                                                 _topLeft * scale,
                                                 _topRight * scale,
                                                 _bottomLeft * scale,
                                                 _bottomRight * scale,
                                               }];

    if (bgColor.alphaComponent > 0) {
      NSBezierPath *fillPath = self.path;
      
      // The background path is slightly inset from the masking path
      // to ensure the fill color mixes w/ the border color properly.
      // But this improvement is only possible with opaque borders.
      if (borderColor.alphaComponent == 1.0) {
        CGFloat inset = borderWidth / 2;
        NSRect fillRect = {
          {inset, inset},
          {size.width - inset, size.height - inset}
        };

        fillPath = [self createSuperEllipsePath:fillRect radii:radii];
      }

      [bgColor setFill];
      [fillPath fill];
    }
  
    // The border outline is identical to the masking path.
    NSBezierPath *borderPath = [NSBezierPath bezierPath];
    [borderPath appendBezierPath:self.path];

    // Clip the border-enclosed area.
    NSBezierPath *clipPath = [self createSuperEllipsePath:borderRect radii:radii];
    [borderPath appendBezierPath:[clipPath bezierPathByReversingPath]];

    // Fill the border.
    [borderColor setFill];
    [borderPath fill];

    NSImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// @override
- (void)updateClippingForLayer:(CALayer *)layer
{
    if (self.clipsToBounds) {
        CGMutablePathRef cgPath = CGPathCreateMutable();
        [self.path applyToCGPath:cgPath];

        _mask.path = cgPath;
        CGPathRelease(cgPath);

        layer.mask = _mask;
    } else {
        layer.mask = nil;
    }
}

// @override
- (RCTCornerRadii)cornerRadii
{
    return [self cornerRadiiWithSize:self.bounds.size];
}

#pragma mark - Corner logic

- (RCTCornerRadii)cornerRadiiWithSize:(NSSize)size
{
  RCTCornerRadii radii = {_topLeft, _topRight, _bottomLeft, _bottomRight};
  return [self cornerRadiiWithSize:size radii:radii];
}

- (RCTCornerRadii)cornerRadiiWithSize:(NSSize)size
                                radii:(RCTCornerRadii)radii
{
    CGFloat w = size.width;
    CGFloat h = size.height;

    CGFloat topLeft = radii.topLeft * coeff;
    CGFloat topRight = radii.topRight * coeff;
    CGFloat bottomLeft = radii.bottomLeft * coeff;
    CGFloat bottomRight = radii.bottomRight * coeff;

    CGFloat x;

    // topRight
    x = MIN(topRight, MIN(w, h));
    topRight = x / coeff;

    // bottomRight
    x = MIN(bottomRight, MIN(w, h - x));
    bottomRight = x / coeff;

    // bottomLeft
    x = MIN(bottomLeft, MIN(w - x, h));
    bottomLeft = x / coeff;

    // topLeft
    x = MIN(topLeft, MIN(w - radii.topRight * coeff, h - x));
    topLeft = x / coeff;

    return (RCTCornerRadii){
        topLeft,
        topRight,
        bottomLeft,
        bottomRight,
    };
}

#pragma mark - Path creation

- (NSBezierPath *)createSuperEllipsePath:(NSRect)rect radii:(RCTCornerRadii)radii
{
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;

    CGFloat topLeft = radii.topLeft;
    CGFloat topRight = radii.topRight;
    CGFloat bottomLeft = radii.bottomLeft;
    CGFloat bottomRight = radii.bottomRight;

    NSBezierPath *path = [NSBezierPath new];

    CGPoint last = CGPointMake(width, y);
    // edit path
    [path moveToPoint:CGPointMake(x + topLeft * coeff, last.y)];

    // top
    [path lineToPoint:CGPointMake(last.x - topRight * coeff, last.y)];

    last = CGPointMake(last.x - topRight * coeff, last.y);
    // top right c1
    [path curveToPoint:CGPointMake(last.x + topRight * 0.77037, last.y + topRight * 0.13357)
         controlPoint1:CGPointMake(last.x + topRight * 0.44576, last.y)
         controlPoint2:CGPointMake(last.x + topRight * 0.6074, last.y + topRight * 0.04641)];
    // top right c2
    last = CGPointMake(last.x + topRight * 0.77037, last.y + topRight * 0.13357);
    [path curveToPoint:CGPointMake(last.x + topRight * 0.37801, last.y + topRight * 0.37801)
         controlPoint1:CGPointMake(last.x + topRight * 0.16296, last.y + topRight * 0.08715)
         controlPoint2:CGPointMake(last.x + topRight * 0.290086, last.y + topRight * 0.2150)];
    // top right c3
    last = CGPointMake(last.x + topRight * 0.37801, last.y + topRight * 0.37801);
    [path curveToPoint:CGPointMake(last.x + topRight * 0.13357, last.y + topRight * 0.77037)
         controlPoint1:CGPointMake(last.x + topRight * 0.08715, last.y + topRight * 0.16296)
         controlPoint2:CGPointMake(last.x + topRight * 0.13357, last.y + topRight * 0.32461)];

    last = CGPointMake(width, height);
    // right
    [path lineToPoint:CGPointMake(last.x, last.y - bottomRight * coeff)];

    last = CGPointMake(last.x, last.y - bottomRight * coeff);
    // bottom right c1
    [path curveToPoint:CGPointMake(last.x - bottomRight * 0.13357, last.y + bottomRight * 0.77037)
         controlPoint1:CGPointMake(last.x, last.y + bottomRight * 0.44576)
         controlPoint2:CGPointMake(last.x - bottomRight * 0.04641, last.y + bottomRight * 0.6074)];
    // bottom right c2
    last = CGPointMake(last.x - bottomRight * 0.13357, last.y + bottomRight * 0.77037);
    [path curveToPoint:CGPointMake(last.x - bottomRight * 0.37801, last.y + bottomRight * 0.37801)
         controlPoint1:CGPointMake(last.x - bottomRight * 0.08715, last.y + bottomRight * 0.16296)
         controlPoint2:CGPointMake(last.x - bottomRight * 0.21505, last.y + bottomRight * 0.290086)];
    // bottom right c3
    last = CGPointMake(last.x - bottomRight * 0.37801, last.y + bottomRight * 0.37801);
    [path curveToPoint:CGPointMake(last.x - bottomRight * 0.77037, last.y + bottomRight * 0.13357)
         controlPoint1:CGPointMake(last.x - bottomRight * 0.16296, last.y + bottomRight * 0.08715)
         controlPoint2:CGPointMake(last.x - bottomRight * 0.32461, last.y + bottomRight * 0.13357)];

    last = CGPointMake(x, height);
    // bottom
    [path lineToPoint:CGPointMake(last.x + bottomLeft * coeff, last.y)];

    last = CGPointMake(last.x + bottomLeft * coeff, last.y);
    // bottom left c1
    [path curveToPoint:CGPointMake(last.x - bottomLeft * 0.77037, last.y - bottomLeft * 0.13357)
         controlPoint1:CGPointMake(last.x - bottomLeft * 0.44576, last.y)
         controlPoint2:CGPointMake(last.x - bottomLeft * 0.6074, last.y - bottomLeft * 0.04641)];
    // bottom left c2
    last = CGPointMake(last.x - bottomLeft * 0.77037, last.y - bottomLeft * 0.13357);
    [path curveToPoint:CGPointMake(last.x - bottomLeft * 0.37801, last.y - bottomLeft * 0.37801)
         controlPoint1:CGPointMake(last.x - bottomLeft * 0.16296, last.y - bottomLeft * 0.08715)
         controlPoint2:CGPointMake(last.x - bottomLeft * 0.290086, last.y - bottomLeft * 0.2150)];
    // bottom left c3
    last = CGPointMake(last.x - bottomLeft * 0.37801, last.y - bottomLeft * 0.37801);
    [path curveToPoint:CGPointMake(last.x - bottomLeft * 0.13357, last.y - bottomLeft * 0.77037)
         controlPoint1:CGPointMake(last.x - bottomLeft * 0.08715, last.y - bottomLeft * 0.16296)
         controlPoint2:CGPointMake(last.x - bottomLeft * 0.13357, last.y - bottomLeft * 0.32461)];

    // left
    [path lineToPoint:CGPointMake(x, y + topLeft * coeff)];

    last = CGPointMake(x, y + topLeft * coeff);
    // top left c1
    [path curveToPoint:CGPointMake(last.x + topLeft * 0.13357, last.y - topLeft * 0.77037)
         controlPoint1:CGPointMake(last.x, last.y - topLeft * 0.44576)
         controlPoint2:CGPointMake(last.x + topLeft * 0.04641, last.y - topLeft * 0.6074)];
    // top left c2
    last = CGPointMake(last.x + topLeft * 0.13357, last.y - topLeft * 0.77037);
    [path curveToPoint:CGPointMake(last.x + topLeft * 0.37801, last.y - topLeft * 0.37801)
         controlPoint1:CGPointMake(last.x + topLeft * 0.08715, last.y - topLeft * 0.16296)
         controlPoint2:CGPointMake(last.x + topLeft * 0.21505, last.y - topLeft * 0.290086)];
    // top left c3
    last = CGPointMake(last.x + topLeft * 0.37801, last.y - topLeft * 0.37801);
    [path curveToPoint:CGPointMake(last.x + topLeft * 0.77037, last.y - topLeft * 0.13357)
         controlPoint1:CGPointMake(last.x + topLeft * 0.16296, last.y - topLeft * 0.08715)
         controlPoint2:CGPointMake(last.x + topLeft * 0.32461, last.y - topLeft * 0.13357)];


    [path closePath];
    return path;
}

@end
