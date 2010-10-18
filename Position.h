//
//  Position.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Position : NSObject <NSCoding, NSCopying> {
    float _xPosition;
    float _yPosition;
    float _zPosition;
}

- (id)initWithX: (float)xLoc Y: (float)yLoc Z: (float)zLoc;
+ (id)positionWithX: (float)xLoc Y: (float)yLoc Z: (float)zLoc;

@property (readwrite, assign) float xPosition;
@property (readwrite, assign) float yPosition;
@property (readwrite, assign) float zPosition;

- (Position*)positionAtDistance:(float)distance withDestination:(Position*)playerPosition;
- (float)angleTo: (Position*)position;
- (float)verticalAngleTo: (Position*)position;
- (float)distanceToPosition: (Position*)position;
- (float)distanceToPosition2D: (Position*)position;
- (float)verticalDistanceToPosition: (Position*)position;

// Add some matrix methods crap
- (float)dotProduct: (Position*)position;
- (Position*)difference: (Position*)position;

- (BOOL)isEqual:(id)other;
@end

@protocol UnitPosition
- (Position*)position;
@end

