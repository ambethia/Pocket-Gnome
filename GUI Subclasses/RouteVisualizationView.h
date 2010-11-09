//
//  RouteVisualizationView.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 2/8/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Route;
@class Position;

@interface RouteVisualizationView : NSView {
    Route *route;
    Position *playerPosition;
    BOOL shouldClosePath;
}

@property BOOL shouldClosePath;
@property (readwrite, retain) Route *route;
@property (readwrite, retain) Position *playerPosition;

@end
