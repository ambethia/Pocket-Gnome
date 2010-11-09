//
//  Route.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Route.h"

@interface Route ()
@property (readwrite, retain) NSArray *waypoints;
@end

@implementation Route

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.waypoints = [NSArray array];
    }
    return self;
}

+ (id)route {
    Route *route = [[Route alloc] init];
    
    return [route autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.waypoints = [decoder decodeObjectForKey: @"Waypoints"] ? [decoder decodeObjectForKey: @"Waypoints"] : [NSArray array];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.waypoints forKey: @"Waypoints"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Route *copy = [[[self class] allocWithZone: zone] init];
    copy.waypoints = self.waypoints;
    
    // log(LOG_GENERAL, @"Old route: %@", self.waypoints);
    // log(LOG_GENERAL, @"New route: %@", copy.waypoints);
    
    return copy;
}

- (void) dealloc
{
    self.waypoints = nil;
    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<0x%X Route: %d waypoints>", self, [self waypointCount]];
}

@synthesize waypoints = _waypoints;

- (void)setWaypoints: (NSArray*)waypoints {
    [_waypoints autorelease];
    if(waypoints) {
        _waypoints = [[NSMutableArray alloc] initWithArray: waypoints copyItems: YES];
    } else {
        _waypoints = nil;
    }
}

- (unsigned)waypointCount {
    return _waypoints ? [_waypoints count] : 0;
}

- (Waypoint*)waypointAtIndex: (unsigned)index {
    if(index >= 0 && index < [_waypoints count])
        return [[[_waypoints objectAtIndex: index] retain] autorelease];
    return nil;
}

- (Waypoint*)waypointClosestToPosition: (Position*)position {
    Waypoint *closestWP = nil;
    float minDist = INFINITY, tempDist = 0;
    for ( Waypoint *waypoint in [self waypoints] ) {
        tempDist = [position distanceToPosition: [waypoint position]];
		//log(LOG_GENERAL, @" %0.2f < %0.2f  %@", tempDist, minDist, waypoint);
        if ( (tempDist < minDist) && (tempDist >= 0.0f) ) {
            minDist = tempDist;
            closestWP = waypoint;
        }
    }

	log(LOG_MOVEMENT, @"Closest WP found at a distance of %0.2f  Vertical Distance: %0.2f Total waypoints searched: %d", minDist, [position verticalDistanceToPosition:[closestWP position]], [[self waypoints] count]);
	
    return [[closestWP retain] autorelease];
}

- (void)addWaypoint: (Waypoint*)waypoint {
    if(waypoint != nil) {
        log(LOG_DEV, @"addWaypoint: adding waypoint");
        [_waypoints addObject: waypoint];
   } else {
        log(LOG_GENERAL, @"addWaypoint: failed; waypoint is nil");
   }
}

- (void)insertWaypoint: (Waypoint*)waypoint atIndex: (unsigned)index {
    if(waypoint != nil && index >= 0 && index <= [_waypoints count])
        [_waypoints insertObject: waypoint atIndex: index];
    else
        log(LOG_GENERAL, @"insertWaypoint:atIndex: failed; either waypoint is nil or index is out of bounds");
}

- (void)removeWaypoint: (Waypoint*)waypoint {
    if(waypoint == nil) return;
    [_waypoints removeObject: waypoint];
}

- (void)removeWaypointAtIndex: (unsigned)index {
    if(index >= 0 && index < [_waypoints count])
        [_waypoints removeObjectAtIndex: index];
}

- (void)removeAllWaypoints {
    [_waypoints removeAllObjects];
}

@end
