//
//  QuestTurnInActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/17/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "QuestTurnInActionController.h"
#import "ActionController.h"

@implementation QuestTurnInActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"QuestTurnInAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading QuestTurnInAction.nib.");
            
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
    
    Action *action = [Action actionWithType:ActionType_QuestTurnIn value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
