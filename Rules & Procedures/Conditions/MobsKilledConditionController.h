//
//  MobsKilledConditionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/23/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface MobsKilledConditionController : ConditionController {
    IBOutlet BetterSegmentedControl *comparatorSegment;
	
	IBOutlet NSTextField *killCountText;
	IBOutlet NSTextField *mobText;
	
	IBOutlet BetterSegmentedControl *typeSegment;
	
	/*
	 IBOutlet NSPopUpButton *unitPopUp;
	 IBOutlet NSPopUpButton *qualityPopUp;
	 IBOutlet NSPopUpButton *comparatorPopUp;
	 
	 IBOutlet NSTextField *stackText;
	 IBOutlet NSTextField *auraText;
	 
	 IBOutlet BetterSegmentedControl *typeSegment;
	 */
}

@end
