//
//  VendorActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/22/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "VendorActionController.h"
#import "ActionController.h"

@implementation VendorActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"VendorAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading VendorAction.nib.");
            
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
    
    Action *action = [Action actionWithType:ActionType_Vendor value:nil];
	
	[action setEnabled: self.enabled];
    
    return action;
}

@end
