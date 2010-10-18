//
//  ReverseRouteActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/22/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "ReverseRouteActionController.h"
#import "ActionController.h"

@implementation ReverseRouteActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"ReverseRouteAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading ReverseRouteAction.nib.");
            
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
    
    Action *action = [Action actionWithType:ActionType_ReverseRoute value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
