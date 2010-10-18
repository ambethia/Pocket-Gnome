//
//  DelayActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "DelayActionController.h"
#import "ActionController.h"

@implementation DelayActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"DelayAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading DelayAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
	
}

- (void)setStateFromAction: (Action*)action{
	
	[delayTextField setStringValue:[NSString stringWithFormat:@"%@", action.value]];
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
	NSNumber *delay = [NSNumber numberWithInt:[delayTextField intValue]];
    Action *action = [Action actionWithType:ActionType_Delay value:delay];

	[action setEnabled: self.enabled];
    
    return action;
}

@end
