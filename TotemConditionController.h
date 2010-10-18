//
//  TotemConditionController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/8/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@interface TotemConditionController : ConditionController {

    IBOutlet NSTextField *valueText;
    IBOutlet NSPopUpButton *comparatorPopUp;
}

@end
