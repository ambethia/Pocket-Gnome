//
//  AuraRuleController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface AuraConditionController : ConditionController {
    IBOutlet NSPopUpButton *unitPopUp;
    IBOutlet NSPopUpButton *qualityPopUp;
    IBOutlet NSPopUpButton *comparatorPopUp;
    IBOutlet NSPopUpButton *dispelTypePopUp;
    
    IBOutlet NSTextField *valueText;
    
    IBOutlet BetterSegmentedControl *typeSegment;
}

- (IBAction)validateState: (id)sender;

@end
