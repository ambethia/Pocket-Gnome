//
//  NoAccessApplication.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 6/21/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "NoAccessApplication.h"


@implementation NoAccessApplication

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.allowAccessibility = NO;
    }
    return self;
}


@synthesize allowAccessibility;

- (BOOL)accessibilityIsIgnored {
    return !self.allowAccessibility;
}

- (id)accessibilityHitTest:(NSPoint)point {
    if(self.allowAccessibility)
        return [super accessibilityHitTest: point];
    return nil;
}

- (id)accessibilityFocusedUIElement {
    if(self.allowAccessibility)
        return [super accessibilityFocusedUIElement];
    return nil;
}

@end
