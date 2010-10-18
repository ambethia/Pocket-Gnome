//
//  ConditionCell.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "ConditionCell.h"


@implementation ConditionCell

- (void) addSubview:(NSView *) view {
    // Weak reference
    subview = view;
}

- (void) dealloc {
    subview = nil;
    [super dealloc];
}

- (NSView *) view {
    return subview;
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *) controlView {

    [super drawWithFrame: cellFrame inView: controlView];
	
    [[self view] setFrame: cellFrame];
	
    if ([[self view] superview] != controlView)
    {
		[controlView addSubview: [self view]];
    }
}

@end
