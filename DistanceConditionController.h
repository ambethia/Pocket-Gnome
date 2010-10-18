//
//  DistanceConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/18/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface DistanceConditionController : ConditionController {
    //IBOutlet BetterSegmentedControl *unitSegment;
    //IBOutlet BetterSegmentedControl *qualitySegment;
    //IBOutlet BetterSegmentedControl *comparatorSegment;
    IBOutlet NSPopUpButton *comparatorPopUp;
    
    IBOutlet NSTextField *valueText;
}

@end
