//
//  Waypoint.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Position.h"

@class Action;
@class Rule;

@interface Waypoint : NSObject <UnitPosition, NSCoding, NSCopying>  {
    Position *_position;
    Action *_action;
	NSString *_title;	// this is a description
	
	// list of actions (in order)
	// list of conditions (procedure?)
	// name for the WP Actions (i.e. repair)
	NSMutableArray *_actions;
	Rule *_rule;
}

- (id)initWithPosition: (Position*)position;
+ (id)waypointWithPosition: (Position*)position;

@property (readwrite, copy) Position *position;
@property (readwrite, copy) Action *action;
@property (readwrite, copy) NSString *title;

@property (readonly, retain) NSArray *actions;
@property (readwrite, retain) Rule *rule;

// actions
- (void)addAction: (Action*)action;
- (void)setActions: (NSArray*)actions;

@end
