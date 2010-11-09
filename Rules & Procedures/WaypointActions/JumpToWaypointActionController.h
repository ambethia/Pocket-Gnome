//
//  JumpToWaypointActionController.h
//  Pocket Gnome
//
//  Created by Josh on 3/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionController.h"

@interface JumpToWaypointActionController : ActionController {

	int _maxWaypoints;
	
	IBOutlet NSTextField *waypointNumTextView;
}

+ (id)jumpToWaypointActionControllerWithTotalWaypoints: (int)waypoints;

@end
