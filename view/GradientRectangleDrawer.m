#import "GradientRectangleDrawer.h"

#import "LogManager.h"

@interface GradientRectangleDrawer (PrivateMethods)

- (void) initGradientColors;

@end


@implementation GradientRectangleDrawer

- (instancetype) initWithColorPalette:(NSColorList *)colorPaletteVal {
  if (self = [super init]) {
    [self setColorPalette: colorPaletteVal];
    [self setColorGradient: 0.5f];
  }
  
  return self;
}

- (void) dealloc {
  [colorPalette release];

  free(gradientColors);
  
  NSAssert(drawBitmap==nil, @"Bitmap should be nil.");

  [super dealloc];
}


- (NSImage *)drawImageOfGradientRectangleWithColor:(NSUInteger)colorIndex
                                            inRect:(NSRect)bounds {
  [self setupBitmap: bounds];
  
  [self drawGradientFilledRect: bounds colorIndex: colorIndex];
  
  return [self createImageFromBitmap];
}


- (void) setColorPalette:(NSColorList *)colorPaletteVal {
  if (colorPaletteVal != colorPalette) {
    [colorPalette release];
    colorPalette = [colorPaletteVal retain];

    if (colorPalette != nil) {
      NSAssert(colorPalette.allKeys.count > 0, @"Cannot set an invalid color palette.");
      initGradientColors = YES;
    }
  }
}

- (NSColorList *)colorPalette {
  return colorPalette;
}


- (void) setColorGradient:(float)gradient {
  NSAssert(gradient >= 0 && gradient <= 1, @"Invalid gradient value.");
  
  if (gradient != colorGradient) {
    colorGradient = gradient;

    if (colorPalette != nil) {
      initGradientColors = YES;
    }
  }
}

- (float) colorGradient {
  return colorGradient;
}

- (void) setupBitmap:(NSRect)bounds {
  NSAssert(drawBitmap == nil, @"Bitmap should be nil.");

  bitmapBounds = bounds;
  drawBitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                       pixelsWide: (int) bitmapBounds.size.width
                                                       pixelsHigh: (int) bitmapBounds.size.height
                                                    bitsPerSample: 8
                                                  samplesPerPixel: 3
                                                         hasAlpha: NO
                                                         isPlanar: NO
                                                   colorSpaceName: NSDeviceRGBColorSpace
                                                      bytesPerRow: 0
                                                     bitsPerPixel: 32];

  if (initGradientColors) {
    [self initGradientColors];
    initGradientColors = NO;
  }
}

- (void)releaseBitmap {
  [drawBitmap release];
  drawBitmap = nil;
}

- (NSImage *)createImageFromBitmap {
  NSImage  *image = [[[NSImage alloc] initWithSize: bitmapBounds.size] autorelease];
  [image addRepresentation: drawBitmap];

  [drawBitmap release];
  drawBitmap = nil;

  return image;
}

- (UInt32) intValueForColor: (NSColor *)color {
  color = [color colorUsingColorSpace: NSColorSpace.deviceRGBColorSpace];
  return CFSwapInt32BigToHost(((UInt32)(color.redComponent * 255) & 0xFF) << 24 |
                              ((UInt32)(color.greenComponent * 255) & 0xFF) << 16 |
                              ((UInt32)(color.blueComponent * 255) & 0xFF) << 8);
}


- (void) drawBasicFilledRect:(NSRect)rect intColor:(UInt32)intColor {
  UInt32  *data = (UInt32 *)drawBitmap.bitmapData;
  
  int  x0 = (int)(rect.origin.x + 0.5f);
  int  y0 = (int)(rect.origin.y + 0.5f); 
  int  height = (int)(rect.origin.y + rect.size.height + 0.5f) - y0;
  int  width = (int)(rect.origin.x + rect.size.width + 0.5f) - x0;
  int  bitmapWidth = (int)drawBitmap.bytesPerRow / sizeof(UInt32);
  int  bitmapHeight = (int)drawBitmap.pixelsHigh;
  
  for (int y = 0; y < height; y++) {
    int  pos = x0 + (bitmapHeight - y0 - y - 1) * bitmapWidth;
    for (int x = 0; x < width; x++) {
      data[pos] = intColor;
      pos++;
    }
  }
}


- (void) drawGradientFilledRect:(NSRect)rect colorIndex:(NSUInteger)colorIndex {
  UInt32  *intColors = &gradientColors[colorIndex * 256];
  UInt32  intColor;
  int  gradient;
  
  UInt32  *data = (UInt32 *)drawBitmap.bitmapData;
  UInt32  *pos;
  UInt32  *poslim;

  int  x0 = (int)(rect.origin.x + 0.5f);
  int  y0 = (int)(rect.origin.y + 0.5f);
  int  width = (int)(rect.origin.x + rect.size.width + 0.5f) - x0;
  int  height = (int)(rect.origin.y + rect.size.height + 0.5f) - y0;
  int  bitmapWidth = (int)drawBitmap.bytesPerRow / sizeof(UInt32);
  int  bitmapHeight = (int)drawBitmap.pixelsHigh;
 
  if (height <= 0 || width <= 0) {
    os_log(LogManager.defaultLogManager.mainLog,
           "Height and width should both be positive: x=%f, y=%f, w=%f, h=%f",
           rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    return;
  }
 
  // Horizontal lines
  for (int y = 0; y < height; y++) {
    gradient = 256 * (y0 + y + 0.5f - rect.origin.y) / rect.size.height;
    // Check for out of bounds, rarely happens but can due to rounding errors.
    intColor = intColors[ MIN(255, MAX(0, gradient)) ];
    
    int  x = (height - y - 1) * width / height; // Maximum x.
    pos = &data[ (bitmapHeight - y0 - y - 1) * bitmapWidth + x0 ];
    poslim = pos + x;
    while (pos < poslim) {
      *pos = intColor;
      pos++;
    }
  }
  
  // Vertical lines
  for (int x = 0; x < width; x++) {
    gradient = 256 * (1 - (x0 + x + 0.5f - rect.origin.x) / rect.size.width);
    // Check for out of bounds, rarely happens but can due to rounding errors.
    intColor = intColors[ MIN(255, MAX(0, gradient)) ];
    
    int  y = (width - x - 1) * height / width; // Minimum y.
    pos = &data[ (bitmapHeight - y0 - height) * bitmapWidth + x + x0 ];
    poslim = pos + bitmapWidth * (height - y);
    while (pos < poslim) {
      *pos = intColor;
      pos += bitmapWidth;
    }
  }
}

- (void) drawFlatFilledRect:(NSRect)rect colorIndex:(NSUInteger)colorIndex {
  if (rect.size.width <= 0 || rect.size.height <= 0) {
    return;
  }

  UInt32 intColor = gradientColors[colorIndex * 256 + 128];
  [self drawBasicFilledRect: rect intColor: intColor];
}

- (void) drawBorderedRect:(NSRect)rect intColor:(UInt32)intColor {
  if (rect.size.width <= 1 || rect.size.height <= 1) {
    return;
  }

  CGFloat lineWidth = 1.0;
  [self drawBasicFilledRect: NSMakeRect(NSMinX(rect), NSMinY(rect), NSWidth(rect), lineWidth)
                    intColor: intColor];
  [self drawBasicFilledRect: NSMakeRect(NSMinX(rect), NSMaxY(rect) - lineWidth,
                                        NSWidth(rect), lineWidth)
                    intColor: intColor];
  [self drawBasicFilledRect: NSMakeRect(NSMinX(rect), NSMinY(rect), lineWidth, NSHeight(rect))
                    intColor: intColor];
  [self drawBasicFilledRect: NSMakeRect(NSMaxX(rect) - lineWidth, NSMinY(rect),
                                        lineWidth, NSHeight(rect))
                    intColor: intColor];
}

- (void) drawLabel:(NSString *)label
          sizeText:(NSString *)sizeText
            inRect:(NSRect)rect
       asContainer:(BOOL)asContainer {
  if (label.length == 0 || rect.size.width < (asContainer ? 64 : 38) ||
      rect.size.height < (asContainer ? 24 : 20)) {
    return;
  }

  CGFloat inset = asContainer ? 4.0 : 3.0;
  NSRect textRect = NSInsetRect(rect, inset, inset);
  if (asContainer) {
    NSRect headerRect = NSMakeRect(NSMinX(rect), NSMaxY(rect) - 20.0,
                                   NSWidth(rect), 20.0);
    [self drawBasicFilledRect: headerRect
                      intColor: [self intValueForColor:
                                 [NSColor colorWithDeviceRed: 0.88
                                                       green: 0.81
                                                        blue: 0.70
                                                       alpha: 1.0]]];
    textRect = NSMakeRect(NSMinX(rect) + inset, NSMaxY(rect) - 18.0,
                          MAX(0, NSWidth(rect) - inset * 2), 14.0);
  }
  BOOL showInlineSize = asContainer && sizeText.length > 0 && rect.size.width >= 110;
  BOOL showSize = !asContainer && sizeText.length > 0 && rect.size.width >= 70 && rect.size.height >= 32;
  NSString *text = (showInlineSize
                    ? [NSString stringWithFormat: @"%@ • %@", label, sizeText]
                    : (showSize ? [NSString stringWithFormat: @"%@\n%@", label, sizeText] : label));

  NSFont *font = [NSFont systemFontOfSize: (asContainer ? 11.0 : 10.0)
                                   weight: (asContainer ? NSFontWeightSemibold : NSFontWeightRegular)];
  NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
  paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
  paragraphStyle.alignment = (!asContainer && rect.size.width >= 120 && rect.size.height >= 48
                              ? NSTextAlignmentCenter
                              : NSTextAlignmentLeft);

  NSDictionary *attributes = @{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite: 0.05 alpha: 0.92],
    NSParagraphStyleAttributeName: paragraphStyle
  };
  NSAttributedString *attributedText = [[[NSAttributedString alloc] initWithString: text
                                                                            attributes: attributes]
                                         autorelease];

  if (!asContainer && paragraphStyle.alignment == NSTextAlignmentCenter) {
    NSSize textSize = [attributedText boundingRectWithSize: textRect.size
                                                   options: NSStringDrawingUsesLineFragmentOrigin].size;
    textRect.origin.y = NSMidY(rect) - MIN(NSHeight(textRect), textSize.height) / 2.0;
  }

  NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep: drawBitmap];
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext: graphicsContext];
  NSRectClip(textRect);
  [attributedText drawInRect: textRect];
  [NSGraphicsContext restoreGraphicsState];
}

@end // @implementation GradientRectangleDrawer


@implementation GradientRectangleDrawer (PrivateMethods)

- (void) initGradientColors {
  NSAssert(colorPalette != nil, @"Color palette must be set.");
  free(gradientColors);

  NSArray  *colorKeys = colorPalette.allKeys;
  _numGradientColors = colorKeys.count;
  gradientColors = malloc(sizeof(UInt32) * self.numGradientColors * 256);
  NSAssert(gradientColors != NULL, @"Failed to malloc gradientColors."); 
  
  NSAutoreleasePool  *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
  
  UInt32  *pos = gradientColors;
  
  for (int i = 0; i < self.numGradientColors; i++) {
    NSColor  *color = [colorPalette colorWithKey: colorKeys[i]];
    
    // Maybe not needed, but there is no harm. It guarantees that getHue:saturation:brightness:alpha
    // can be invoked.
    color = [color colorUsingColorSpace: NSColorSpace.deviceRGBColorSpace];
    
    CGFloat  hue, saturation, brightness, alpha;
    [color getHue: &hue saturation: &saturation brightness: &brightness alpha: &alpha];

    NSColor  *modColor;

    // Darker colors
    for (int j = 0; j < 128; j++) {
      float  adjust = colorGradient * (float)(128-j) / 128;
      modColor = [NSColor colorWithDeviceHue: hue
                                  saturation: saturation
                                  brightness: brightness * ( 1 - adjust)
                                       alpha: alpha];
                   
      *pos++ = CFSwapInt32BigToHost(((UInt32)(modColor.redComponent * 255) & 0xFF) << 24 |
                                    ((UInt32)(modColor.greenComponent * 255) & 0xFF) << 16 |
                                    ((UInt32)(modColor.blueComponent * 255) & 0xFF) << 8);
    }
    
    // Lighter colors
    for (int j = 0; j < 128; j++) {
      float  adjust = colorGradient * (float)j / 128;
      
      // First ramp up brightness, then decrease saturation 
      float dif = 1 - brightness;
      float absAdjust = (dif + saturation) * adjust;

      if (absAdjust < dif) {
        modColor = [NSColor colorWithDeviceHue: hue
                                    saturation: saturation
                                    brightness: brightness + absAdjust
                                         alpha: alpha];
      }
      else {
        modColor = [NSColor colorWithDeviceHue: hue
                                    saturation: saturation + dif - absAdjust
                                    brightness: 1.0f
                                         alpha: alpha];
      }
      
      *pos++ = CFSwapInt32BigToHost(((UInt32)(modColor.redComponent * 255) & 0xFF) << 24 |
                                    ((UInt32)(modColor.greenComponent * 255) & 0xFF) << 16 |
                                    ((UInt32)(modColor.blueComponent * 255) & 0xFF) << 8);
    }
  }
  
  [localAutoreleasePool release];
}

@end // @implementation GradientRectangleDrawer (PrivateMethods)
