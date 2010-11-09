//
//  SpellCooldownConditionController.h
//  Pocket Gnome
//
//  Created by Josh on 12/7/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface SpellCooldownConditionController : ConditionController {
    IBOutlet BetterSegmentedControl *typeSegment;
	IBOutlet BetterSegmentedControl *comparatorSegment;
    IBOutlet NSTextField *valueText;
}

@end
