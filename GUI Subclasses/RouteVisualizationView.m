//
//  RouteVisualizationView.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 2/8/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "RouteVisualizationView.h"

#import "Route.h"

@implementation RouteVisualizationView

@synthesize route;
@synthesize playerPosition;
@synthesize shouldClosePath;

- (void)drawRect:(NSRect)aRect {
    // determine our extremes for drawing
    float leftmost = positiveInfinity, rightmost = negativeInfinity, upper = negativeInfinity, lower = positiveInfinity;
    for(Waypoint *waypoint in [self.route waypoints]) {
    
        if([[waypoint position] xPosition] < leftmost)
            leftmost = [[waypoint position] xPosition];
        if([[waypoint position] xPosition] > rightmost)
            rightmost = [[waypoint position] xPosition];

        if([[waypoint position] yPosition] < lower)
            lower = [[waypoint position] yPosition];
        if([[waypoint position] yPosition] > upper)
            upper = [[waypoint position] yPosition];
    }
    
    // now we have our extremes
    float xSpan = rightmost - leftmost;
    float ySpan = upper - lower;
    NSBezierPath *path = [NSBezierPath bezierPath];

    // create the path
    NSPoint firstPoint = NSZeroPoint;
    for(Waypoint *waypoint in [self.route waypoints]) {
        float xDiff = ([[waypoint position] xPosition] - leftmost)/xSpan;
        float yDiff = ([[waypoint position] yPosition] - lower)/ySpan;
        
        NSPoint point = NSMakePoint(xDiff*([self bounds].size.width-20) + 10, yDiff*([self bounds].size.height-20) + 10);
        
        if([path elementCount] == 0) {
            firstPoint = point;
            [path moveToPoint: point];
        }
        
        [path lineToPoint: point];
        [path moveToPoint: point];
    }
    if(!NSEqualPoints(firstPoint, NSZeroPoint) && shouldClosePath)
        [path lineToPoint: firstPoint];
    [[NSColor blueColor] set];
    [path setLineWidth: 3.0];
    [path stroke];
    
    NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paraStyle setAlignment: NSCenterTextAlignment];
    
    // draw the points
    int i = 0;
    for(Waypoint *waypoint in [self.route waypoints]) {
        float xDiff = ([[waypoint position] xPosition] - leftmost)/xSpan;
        float yDiff = ([[waypoint position] yPosition] - lower)/ySpan;
        float xPos = xDiff*([self bounds].size.width-20) - 7 + 10;
        float yPos = yDiff*([self bounds].size.height-20) - 7 + 10;

        NSRect pointRect = NSMakeRect(xPos, yPos, 14, 14);
        if(waypoint == [self.route waypointAtIndex: 0])
            [[NSColor greenColor] set];
        else
            [[NSColor redColor] set];
        [[NSBezierPath bezierPathWithOvalInRect: pointRect] fill];
        
        NSAttributedString *numStr = [[[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%d", ++i] 
                                                                      attributes: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                                                   [NSFont labelFontOfSize: ((i < 100) ? 8 : 6)],           NSFontAttributeName,
                                                                                   ((i==0) ? [NSColor blackColor] : [NSColor whiteColor]),  NSForegroundColorAttributeName, 
                                                                                   paraStyle,                                               NSParagraphStyleAttributeName, nil]] autorelease];
        
        NSSize strSize = [numStr size];
        float x = pointRect.origin.x + ((pointRect.size.width - strSize.width) / 2.0f);
        float y = pointRect.origin.y + ((pointRect.size.height - strSize.height) / 2.0f);
        
        /*
         //[numStr drawAtPoint: NSMakePoint(xPos, yPos)];
         if(strSize.width > pointRect.size.width) {
            diff = strSize.width - pointRect.size.width;
            pointRect.size.width += diff;
            pointRect.origin.x -= (diff/2.0f);
            log(LOG_GENERAL, @"Fixing rect size for %f %@", strSize.width, NSStringFromRect(pointRect));
        }*/
        [numStr drawInRect: NSMakeRect(x, y, strSize.width, strSize.height)];
    }
    
    if(self.playerPosition) {
        float xDiff = ([self.playerPosition xPosition] - leftmost)/xSpan;
        float yDiff = ([self.playerPosition yPosition] - lower)/ySpan;
        float xPos = xDiff*([self bounds].size.width-20) - 6 + 10;
        float yPos = yDiff*([self bounds].size.height-20) - 6 + 10;
        
        NSRect pointRect = NSMakeRect(xPos, yPos, 12, 12);
        [[NSColor orangeColor] set];
        [[NSBezierPath bezierPathWithOvalInRect: pointRect] fill];
        
        /*NSAttributedString *str = [[[NSAttributedString alloc] initWithString: @"*" 
                                                                   attributes: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                                                [NSFont boldSystemFontOfSize: 12],  NSFontAttributeName,
                                                                                [NSColor whiteColor],               NSForegroundColorAttributeName, 
                                                                                paraStyle,                          NSParagraphStyleAttributeName, nil]] autorelease];
        [str drawInRect: pointRect];*/
    }
    
}

@end
