#import "DrawTaskInput.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"


@implementation DrawTaskInput

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds
                 backingScaleFactor:(CGFloat)backingScaleFactor {
  if (self = [super init]) {
    _visibleTree = [visibleTree retain];
    _treeInView = [treeInView retain];
    _layoutBuilder = [layoutBuilder retain];
    _bounds = bounds;
    _backingScaleFactor = MAX(1.0, backingScaleFactor);
  }
  return self;
}

- (void) dealloc {
  [_visibleTree release];
  [_treeInView release];
  [_layoutBuilder release];
  
  [super dealloc];
}

@end
