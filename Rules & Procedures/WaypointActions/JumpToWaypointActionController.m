//
//  JumpToWaypointActionController.m
//  Pocket Gnome
//
//  Created by Josh on 3/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "JumpToWaypointActionController.h"
#import "ActionController.h"

@implementation JumpToWaypointActionController

- (id)init
{
    self = [super init];
    if (self != nil){
		_maxWaypoints = 0;

        if(![NSBundle loadNibNamed: @"JumpToWaypointAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading JumpToWaypointAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithWaypoints: (int)waypoints{
    self = [self init];
    if (self != nil) {
		_maxWaypoints = waypoints;
    }
    return self;
}

+ (id)jumpToWaypointActionControllerWithTotalWaypoints: (int)waypoints{
	return [[[JumpToWaypointActionController alloc] initWithWaypoints: waypoints] autorelease];
}

- (IBAction)validateState: (id)sender {
	
	if ( [waypointNumTextView intValue] > _maxWaypoints || [waypointNumTextView intValue] < 1 ){
		[waypointNumTextView setStringValue:@"1"];
	}
}

- (void)setStateFromAction: (Action*)action{
	
	[waypointNumTextView setIntValue:[[action value] intValue]];
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_JumpToWaypoint value:nil];
	
	[action setEnabled: self.enabled];
	[action setValue: [waypointNumTextView stringValue]];
    
    return action;
}

@end
