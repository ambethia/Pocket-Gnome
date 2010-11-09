//
//  ComboPointConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/7/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface ComboPointConditionController : ConditionController {

    IBOutlet NSPopUpButton *comparatorPopUp;
    IBOutlet NSTextField *valueText;
}

@end
