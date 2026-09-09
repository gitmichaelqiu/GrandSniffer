#import "StatelessFileItemMapping.h"

@implementation StatelessFileItemMapping

- (BOOL)dependsOnTreeDrawerSettings {
  return NO;
}

// Default implementation
- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree {
  return self;
}

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree
                                   settings:(TreeDrawerBaseSettings *)settings {
  return [self fileItemMappingForTree: tree];
}

@end
