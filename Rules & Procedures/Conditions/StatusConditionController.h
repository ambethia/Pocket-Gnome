//
//  StatusRuleController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface StatusConditionController : ConditionController {

    IBOutlet NSPopUpButton          *unitPopUp;
    //IBOutlet BetterSegmentedControl *unitSegment;
    IBOutlet BetterSegmentedControl *comparatorSegment;
    IBOutlet BetterSegmentedControl *stateSegment;
    
    int previousState;
}

@end
