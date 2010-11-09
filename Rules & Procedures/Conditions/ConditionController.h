//
//  RuleController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Condition.h"

@interface ConditionController : NSObject {
    IBOutlet NSView *view;
    IBOutlet id _delegate;
    IBOutlet NSButton *disableButton;
    BOOL _enabled;
}

+ (id)conditionControllerWithCondition: (Condition*)condition;

- (NSView*)view;
- (IBAction)validateState: (id)sender;
- (IBAction)disableCondition: (id)sender;

@property (readwrite, assign) id delegate;
@property BOOL enabled;

- (Condition*)condition;
- (void)setStateFromCondition: (Condition*)condition;

@end
