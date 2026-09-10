// GrandSniffer modification: changed from GrandPerspective on 2026-09-10. Copyright (C) 2026 Michael Y. Qiu. See LICENSE and Credits.rtf.

#import "TreeDrawer.h"

#import "DirectoryItem.h"
#import "FileItemMapping.h"
#import "FileItemMappingScheme.h"
#import "FilteredTreeGuide.h"
#import "GradientRectangleDrawer.h"
#import "TreeDrawerSettings.h"


@interface TreeDrawer (PrivateMethods)

- (void) colorSchemeChanged:(NSNotification *)notification;
- (void) updateColorMapper:(BOOL)forceRedraw;
- (void) updateColorMapperForSettings:(TreeDrawerSettings *)settings;
- (NSColor *) labelColorForBackgroundColor:(NSColor *)backgroundColor;

@end // @interface TreeDrawer (PrivateMethod)

@implementation TreeDrawer

// Overrides designated initialiser of base class
- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
                     colorPalette:(NSColorList *)colorPalette {
  TreeDrawerSettings  *settings = [[[TreeDrawerSettings alloc] init] autorelease];
  if (colorPalette) {
    settings = [settings settingsWithChangedColorPalette: colorPalette];
  }

  return [self initWithScanTree: scanTreeVal treeDrawerSettings: settings];
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
               treeDrawerSettings:(TreeDrawerSettings *)settings {
  if (self = [super initWithScanTree: scanTreeVal
                        colorPalette: settings.colorPalette]) {
    [self updateSettings: settings];
    
    freeSpaceColor = [rectangleDrawer intValueForColor: NSColor.blackColor];
    usedSpaceColor = [rectangleDrawer intValueForColor: NSColor.darkGrayColor];
    visibleTreeBackgroundColor = [rectangleDrawer intValueForColor: NSColor.grayColor];
    directoryFillColor = [rectangleDrawer intValueForColor:
                          [NSColor colorWithDeviceRed: 0.74
                                                green: 0.62
                                                 blue: 0.47
                                                alpha: 1.0]];
  }
  return self;
}

- (void) dealloc {
  [NSNotificationCenter.defaultCenter removeObserver: self];

  [_colorMapper release];
  [_colorScheme release];

  [super dealloc];
}


- (void) setColorScheme:(NSObject <FileItemMappingScheme> *)colorScheme {
  if (colorScheme != _colorScheme) {
    NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;

    [nc removeObserver: self
                  name: MappingSchemeChangedEvent
                object: _colorScheme];

    [_colorScheme release];
    _colorScheme = [colorScheme retain];

    [nc addObserver: self
           selector: @selector(colorSchemeChanged:)
               name: MappingSchemeChangedEvent
             object: _colorScheme];

    if (!colorScheme.dependsOnTreeDrawerSettings) {
      [self updateColorMapper: NO];
    }
  }
}


- (void) setMaskTest:(FileItemTest *)maskTest {
  [treeGuide setFileItemTest: maskTest];
}

- (FileItemTest *)maskTest {
  return treeGuide.fileItemTest;
}


- (void) updateSettings:(TreeDrawerSettings *)settings {
  [super updateSettings: settings];

  if (self.colorScheme != settings.colorScheme) {
    self.colorScheme = settings.colorScheme;
  }

  if (self.colorScheme.dependsOnTreeDrawerSettings) {
    [self updateColorMapperForSettings: settings];
  }

  [rectangleDrawer setColorPalette: settings.colorPalette];
  [rectangleDrawer setColorGradient: settings.colorGradient];
  [self setMaskTest: settings.maskTest];
}


// Overrides of protected methods

- (void) drawVisibleTreeAtRect:(FileItem *)visibleTree rect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: visibleTreeBackgroundColor];
}

- (void) drawUsedSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: usedSpaceColor];
}

- (void) drawFreeSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: freeSpaceColor];
}

- (void) drawFreedSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: freeSpaceColor];
}

- (void) drawFileItem:(FileItem *)fileItem atRect:(NSRect) rect depth:(int) depth {
  NSColor *labelColor = [NSColor colorWithDeviceWhite: 0.05 alpha: 0.92];

  if (fileItem.isDirectory) {
    [rectangleDrawer drawBasicFilledRect: rect intColor: directoryFillColor];
  }
  else {
    NSUInteger  hash = [_colorMapper hashForFileItem: fileItem atDepth: depth];
    NSUInteger  colorIndex = [_colorMapper colorIndexForHash: hash
                                                   numColors: rectangleDrawer.numGradientColors];

    [rectangleDrawer drawFlatFilledRect: rect colorIndex: colorIndex];
    labelColor = [self labelColorForBackgroundColor: [rectangleDrawer colorForIndex: colorIndex]];
  }
  [rectangleDrawer drawBorderedRect: rect
                           intColor: [rectangleDrawer intValueForColor:
                                      [NSColor colorWithDeviceWhite: 0.12 alpha: 1.0]]];
  [rectangleDrawer drawLabel: fileItem.label
                    sizeText: [FileItem stringForFileItemSize: fileItem.itemSize]
                    inRect: rect
                 asContainer: NO
                   textColor: labelColor];
}

- (void) drawDirectoryItem:(DirectoryItem *)directoryItem atRect:(NSRect) rect depth:(int) depth {
  NSString *label = directoryItem.label.lastPathComponent;
  if (label.length == 0) {
    label = directoryItem.pathComponent.lastPathComponent;
  }
  if (label.length == 0) {
    label = directoryItem.pathComponent;
  }

  if (depth > 0) {
    [rectangleDrawer drawLabel: label
                      sizeText: [FileItem stringForFileItemSize: directoryItem.itemSize]
                        inRect: rect
                   asContainer: YES];
  }
  [rectangleDrawer drawBorderedRect: rect
                           intColor: [rectangleDrawer intValueForColor:
                                      [NSColor colorWithDeviceWhite: 0.08 alpha: 1.0]]];
}

@end // @implementation TreeDrawer

@implementation TreeDrawer (PrivateMethods)

- (NSColor *) labelColorForBackgroundColor:(NSColor *)backgroundColor {
  NSColor *rgbColor = [backgroundColor colorUsingColorSpace: NSColorSpace.deviceRGBColorSpace];
  CGFloat luminance = 0.2126 * rgbColor.redComponent
                    + 0.7152 * rgbColor.greenComponent
                    + 0.0722 * rgbColor.blueComponent;

  return (luminance < 0.55)
    ? [NSColor colorWithDeviceWhite: 1.0 alpha: 0.94]
    : [NSColor colorWithDeviceWhite: 0.05 alpha: 0.92];
}

- (void) colorSchemeChanged:(NSNotification *)notification {
  // Force a redraw as the mapping change was due to an internal change impacting the scheme,
  // instead of a settings change that the view is aware of.
  [self updateColorMapper: YES];
}

- (void) updateColorMapper:(BOOL)forceRedraw {
  self.colorMapper = [self.colorScheme fileItemMappingForTree: scanTree];

  NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;
  [nc postNotificationName: ColorMappingChangedEvent
                    object: self
                  userInfo: @{@"forceRedraw": [NSNumber numberWithBool: forceRedraw]}];
}

- (void) updateColorMapperForSettings:(TreeDrawerSettings *)settings {
  self.colorMapper = [self.colorScheme fileItemMappingForTree: scanTree settings: settings];

  NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;
  [nc postNotificationName: ColorMappingChangedEvent
                    object: self
                  userInfo: @{@"forceRedraw": [NSNumber numberWithBool: NO]}];
}

@end // @implementation TreeDrawer (PrivateMethod)
