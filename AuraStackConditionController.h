//
//  AuraStackConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/1/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface AuraStackConditionController : ConditionController {
    IBOutlet NSPopUpButton *unitPopUp;
    IBOutlet NSPopUpButton *qualityPopUp;
    IBOutlet NSPopUpButton *comparatorPopUp;
    
    IBOutlet NSTextField *stackText;
    IBOutlet NSTextField *auraText;
    
    IBOutlet BetterSegmentedControl *typeSegment;
}

@end

