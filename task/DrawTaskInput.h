// GrandSniffer modification: changed from GrandPerspective on 2026-09-10. Copyright (C) 2026 Michael Y. Qiu. See LICENSE and Credits.rtf.

#import <Cocoa/Cocoa.h>

@class FileItem;
@class TreeLayoutBuilder;

@interface DrawTaskInput : NSObject {
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds
                 backingScaleFactor:(CGFloat)backingScaleFactor NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) FileItem *visibleTree;
@property (nonatomic, readonly, strong) FileItem *treeInView;
@property (nonatomic, readonly, strong) TreeLayoutBuilder *layoutBuilder;
@property (nonatomic, readonly) NSRect bounds;
@property (nonatomic, readonly) CGFloat backingScaleFactor;

@end
