//
//  QuestGrabActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/17/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "QuestGrabActionController.h"
#import "ActionController.h"

@implementation QuestGrabActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"QuestGrabAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading QuestGrabAction.nib.");
            
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
    
    Action *action = [Action actionWithType:ActionType_QuestGrab value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
