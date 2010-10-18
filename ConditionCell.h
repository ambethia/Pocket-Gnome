//
//  RuleCell.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ConditionCell : NSTextFieldCell {

    NSView *subview;
}

// The view is not retained by the cell!
- (void) addSubview:(NSView *) view;

@end
