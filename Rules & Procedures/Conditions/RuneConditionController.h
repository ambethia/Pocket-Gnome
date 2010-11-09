//
//  RuneConditionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/7/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface RuneConditionController : ConditionController {
	IBOutlet BetterSegmentedControl *comparatorSegment;
	IBOutlet NSPopUpButton *qualityPopUp;
	IBOutlet NSPopUpButton *quantityPopUp;
}

@end
