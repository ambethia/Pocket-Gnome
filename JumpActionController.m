//
//  JumpActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "JumpActionController.h"
#import "ActionController.h"

@implementation JumpActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"JumpAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading JumpAction.nib.");
            
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
    
    Action *action = [Action actionWithType:ActionType_Jump value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
