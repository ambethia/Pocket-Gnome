//
//  Route.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Waypoint.h"

@interface Route : NSObject <NSCoding, NSCopying> {
    NSMutableArray *_waypoints;
}

+ (id)route;

@property (readonly, retain) NSArray *waypoints;

- (unsigned)waypointCount;
- (Waypoint*)waypointAtIndex: (unsigned)index;
- (Waypoint*)waypointClosestToPosition: (Position*)position;

- (void)addWaypoint: (Waypoint*)waypoint;
- (void)insertWaypoint: (Waypoint*)waypoint atIndex: (unsigned)index;
- (void)removeWaypoint: (Waypoint*)waypoint;
- (void)removeWaypointAtIndex: (unsigned)index;
- (void)removeAllWaypoints;

@end
