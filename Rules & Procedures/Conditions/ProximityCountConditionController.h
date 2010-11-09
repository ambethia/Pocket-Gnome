//
//  ProximityCountConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/17/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;


@interface ProximityCountConditionController : ConditionController {
    IBOutlet BetterSegmentedControl *unitSegment;
    IBOutlet BetterSegmentedControl *comparatorSegment;

    IBOutlet NSTextField *countText;
    IBOutlet NSTextField *distanceText;
}

@end
