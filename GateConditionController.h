//
//  GateConditionController.h
//  Pocket Gnome
//
//  Created by Josh on 2/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

   
@interface GateConditionController : ConditionController {
	
	IBOutlet NSPopUpButton *qualityPopUp;

	IBOutlet BetterSegmentedControl *comparatorSegment;
}

@end
