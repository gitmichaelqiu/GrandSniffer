// GrandSniffer modification: changed from GrandPerspective on 2026-09-10. Copyright (C) 2026 Michael Y. Qiu. See LICENSE and Credits.rtf.

#import "OverlayDrawer.h"

#import "FileItem.h"
#import "FilteredTreeGuide.h"
#import "GradientRectangleDrawer.h"
#import "TreeLayoutBuilder.h"

@implementation OverlayDrawer

- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
                     colorPalette:(NSColorList *)colorPalette {
  if (self = [super initWithScanTree: scanTreeVal colorPalette: colorPalette]) {
    overlayColor = [rectangleDrawer intValueForColor: NSColor.lightGrayColor];
  }
  return self;
}

- (NSImage *)drawOverlayImageOfVisibleTree:(FileItem *)visibleTree
                            startingAtTree:(FileItem *)treeRoot
                        usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                                    inRect:(NSRect) bounds
                               overlayTest:(FileItemTest *)overlayTest; {
  [treeGuide setFileItemTest: overlayTest];

  return [super drawImageOfVisibleTree: visibleTree
                        startingAtTree: treeRoot
                    usingLayoutBuilder: layoutBuilder
                                inRect: bounds];
}

- (void) drawFileItem:(FileItem *)fileItem atRect:(NSRect) rect depth:(int) depth {
  // Plain file that passed the test. Keep its label and color visible while highlighting it.
  [rectangleDrawer drawBorderedRect: rect intColor: overlayColor];
}

@end
