//
//  RepairActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/14/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "RepairActionController.h"
#import "ActionController.h"

@implementation RepairActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"RepairAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading RepairAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
	
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Repair value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
