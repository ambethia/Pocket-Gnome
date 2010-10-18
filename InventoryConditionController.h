//
//  InventoryConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/18/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface InventoryConditionController : ConditionController {

    IBOutlet NSPopUpButton *comparatorPopUp;
    //IBOutlet BetterSegmentedControl *comparatorSegment;
    IBOutlet BetterSegmentedControl *typeSegment;

    IBOutlet NSTextField *quantityText;
    IBOutlet NSTextField *itemText;
}

@end
