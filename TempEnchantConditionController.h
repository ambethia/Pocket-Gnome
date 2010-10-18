//
//  TempEnchantConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/20/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"
@class BetterSegmentedControl;

@interface TempEnchantConditionController : ConditionController {
    IBOutlet BetterSegmentedControl *qualitySegment;
    IBOutlet NSPopUpButton          *comparatorPopUp;
}

@end
