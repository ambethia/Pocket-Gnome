//
//  Position.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "Position.h"


@implementation Position

+ (void)initialize {
    [self exposeBinding: @"xPosition"];
    [self exposeBinding: @"yPosition"];
    [self exposeBinding: @"zPosition"];
}

- (id) init
{
    return [self initWithX: -1 Y: -1 Z: -1];
}

- (id)initWithX: (float)xLoc Y: (float)yLoc Z: (float)zLoc {
    self = [super init];
    if (self != nil) {
        self.xPosition = xLoc;
        self.yPosition = yLoc;
        self.zPosition = zLoc;
    }
    return self;
}

+ (id)positionWithX: (float)xLoc Y: (float)yLoc Z: (float)zLoc {
    Position *position = [[Position alloc] initWithX: xLoc Y: yLoc Z: zLoc];
    
    return [position autorelease];
}


@synthesize xPosition = _xPosition;
@synthesize yPosition = _yPosition;
@synthesize zPosition = _zPosition;

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if(self) {
        self.xPosition = [[decoder decodeObjectForKey: @"xPosition"] floatValue];
        self.yPosition = [[decoder decodeObjectForKey: @"yPosition"] floatValue];
        self.zPosition = [[decoder decodeObjectForKey: @"zPosition"] floatValue];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: [NSNumber numberWithFloat: self.xPosition] forKey: @"xPosition"];
    [coder encodeObject: [NSNumber numberWithFloat: self.yPosition] forKey: @"yPosition"];
    [coder encodeObject: [NSNumber numberWithFloat: self.zPosition] forKey: @"zPosition"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Position *copy = [[[self class] allocWithZone: zone] initWithX: self.xPosition Y: self.yPosition Z: self.zPosition];
    
    return copy;
}

- (void) dealloc
{
    [super dealloc];
}


- (NSString*)description {
    return [NSString stringWithFormat: @"<Position X: %.2f Y: %.2f Z: %.2f>", [self xPosition], [self yPosition], [self zPosition]];
}

#pragma mark -

- (Position*)positionAtDistance:(float)distance withDestination:(Position*)playerPosition {

	// this is where we want to face!
	float direction = [playerPosition angleTo:self];
	float x, y;

	// negative x
	if ( [self xPosition] < 0.0f ){
		x = -1.0f * (cosf(direction) * distance);
	}
	// positive x
	else{
		x = -1.0f * (cosf(direction) * distance);
	}
	
	// negative y
	if ( [self yPosition] < 0.0f ){
		y = -1.0f * (sinf(direction) * distance);
	}
	// positive y
	else{
		y = -1.0f * (sinf(direction) * distance);
	}
	
	Position *newPos = [[Position alloc] initWithX:([self xPosition] + x) Y:([self yPosition] + y) Z:[self zPosition]];
	return [[newPos retain] autorelease];
}


- (float)angleTo: (Position*)position {
    
    // create unit vector in direction of the mob
    float xDiff = [position xPosition] - [self xPosition];
    float yDiff = [position yPosition] - [self yPosition];
    float distance = [self distanceToPosition2D: position];
    NSPoint mobUnitVector = NSMakePoint(xDiff/distance, yDiff/distance);
    // log(LOG_GENERAL, @"Unit Vector to Mob: %@", NSStringFromPoint(mobUnitVector));
    
    // create unit vector of player facing angle
    //float angle = [playerDataController playerDirection];
    //NSPoint playerUnitVector = NSMakePoint(cosf(angle), sinf(angle));
    NSPoint northUnitVector = NSMakePoint(1, 0);
    
    // determine the angle between the Mob and North
    float angleBetween = mobUnitVector.x*northUnitVector.x + mobUnitVector.y*northUnitVector.y;
    float angleOffset = acosf(angleBetween);
    // log(LOG_GENERAL, @"Cosine of angle between: %f", angleBetween);
    // log(LOG_GENERAL, @"Angle (rad) between: %f", angleOffset);
    
    if(mobUnitVector.y > 0) // mob is in N-->W-->S half of the compass
        return angleOffset;
    else                    // mob is in N-->E-->S half of the compass
        return ((6.2831853f) - angleOffset);
}


- (float)verticalAngleTo: (Position*)position {
    
    // create unit vector in direction of the mob
    float xDiff = [position xPosition] - [self xPosition];
    float yDiff = [position yPosition] - [self yPosition];
    float zDiff = [position zPosition] - [self zPosition];
    float distance = [self distanceToPosition: position];
    
    float mobUVx = xDiff/distance;
    float mobUVy = yDiff/distance;
    float mobUVz = zDiff/distance;
    
    // create unit vector toward mob at current elevation
    float distance2D = [self distanceToPosition2D: position];
    
    float levelUVx = xDiff/distance2D;
    float levelUVy = yDiff/distance2D;
    float levelUVz = 0.0f;
    
    // cosine of the angle between them is: (A x B) / |A||B| (but since magnitudes are 1...)
    float cosine = mobUVx*levelUVx + mobUVy*levelUVy + mobUVz*levelUVz;
    if(cosine > 1.0f) cosine = 1.0f; // values over 1.0 are invalid for acosf().
    float angleBetween = acosf(cosine);

    // now, adjust the sign
    if(zDiff < 0.0f) {
        angleBetween = 0.0f - angleBetween;
    }

    //log(LOG_GENERAL, @"Got vertical angle between: %f; cosine: %f", angleBetween, cosine);
    return angleBetween;
}

- (float)distanceToPosition2D: (Position*)position {
    
    float distance;
    if([self xPosition] != INFINITY && [self yPosition] != INFINITY) {
        float xDiff = [position xPosition] - [self xPosition];
        float yDiff = [position yPosition] - [self yPosition];
        distance = sqrt(xDiff*xDiff + yDiff*yDiff);
    } else {
        distance = INFINITY;
    }
    return distance;
}

- (float)distanceToPosition: (Position*)position {
    
    float distance = INFINITY;
    if(position && ([self xPosition] != INFINITY && [self yPosition] != INFINITY && [self zPosition] != INFINITY)) {
        float xDiff = [position xPosition] - [self xPosition];
        float yDiff = [position yPosition] - [self yPosition];
        float zDiff = [position zPosition] - [self zPosition];
        distance = sqrt(xDiff*xDiff + yDiff*yDiff + zDiff*zDiff);
    }
    return distance;
}

- (float)verticalDistanceToPosition: (Position*)position {
    return fabsf([position zPosition] - [self zPosition]);
}

- (float)dotProduct: (Position*)position {
	return [self xPosition]*[position xPosition] + [self yPosition]*[position yPosition] + [self zPosition]*[position zPosition];
}

- (Position*)difference: (Position*)position {
	Position *diff = [[Position alloc] initWithX:[self xPosition] - [position xPosition]
											   Y:[self yPosition] - [position yPosition]
											   Z:[self zPosition] - [position zPosition]];
	return diff;
}

- (BOOL)isEqual:(Position*)other {
	
	if ( other == self ){
		return YES;
	}
	if ( self.xPosition == other.xPosition && self.yPosition == other.yPosition && self.zPosition == other.zPosition ){
		return YES;
	}
	
	return NO;
}

@end
