//
//  LastSpellCastConditionController.h
//  Pocket Gnome
//
//  Created by Josh on 12/28/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface LastSpellCastConditionController : ConditionController {
    IBOutlet BetterSegmentedControl *typeSegment;
	IBOutlet NSPopUpButton *comparatorPopUp;
    IBOutlet NSTextField *valueText;
}

@end
