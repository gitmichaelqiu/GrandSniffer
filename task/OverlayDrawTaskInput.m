// GrandSniffer modification: changed from GrandPerspective on 2026-09-10. Copyright (C) 2026 Michael Y. Qiu. See LICENSE and Credits.rtf.

#import "OverlayDrawTaskInput.h"

#import "FileItemTest.h"

@implementation OverlayDrawTaskInput

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds
                 backingScaleFactor:(CGFloat)backingScaleFactor
                         overlayTest:(FileItemTest *)overlayTest {

  if (self = [super initWithVisibleTree: visibleTree
                             treeInView: treeInView
                          layoutBuilder: layoutBuilder
                                 bounds: bounds
                    backingScaleFactor: backingScaleFactor]) {
    _overlayTest = [overlayTest retain];
  }

  return self;
}

- (void) dealloc {
  [_overlayTest release];

  [super dealloc];
}

@end
