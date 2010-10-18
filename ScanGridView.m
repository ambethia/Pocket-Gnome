//
//  ScanGridView.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/31/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "ScanGridView.h"


@implementation ScanGridView

@synthesize xIncrement = xInc;
@synthesize yIncrement = yInc;
@synthesize scanPoint;
@synthesize origin;


- (void)drawRect:(NSRect)aRect {
	[[NSColor clearColor] set];
	[NSBezierPath fillRect: [self frame]];
    
    
    NSBezierPath *border = [NSBezierPath bezierPath];
    NSBezierPath *done = [NSBezierPath bezierPath];
    NSBezierPath *notDone = [NSBezierPath bezierPath];
    
    // make box around us
    [border moveToPoint: NSZeroPoint];
    [border lineToPoint: NSMakePoint(0, aRect.size.height)];
    [border lineToPoint: NSMakePoint(aRect.size.width, aRect.size.height)];
    [border lineToPoint: NSMakePoint(aRect.size.width, 0)];
    [border lineToPoint: NSZeroPoint];
    
    int i;
    if(self.xIncrement > 0) {
        for(i=0; i<=aRect.size.width; i+=self.xIncrement) {
            
            if(i < self.scanPoint.x) {
                [done moveToPoint: NSMakePoint(i, 0)];
                [done lineToPoint: NSMakePoint(i, aRect.size.height)];
            } else {
                [notDone moveToPoint: NSMakePoint(i, 0)];
                [notDone lineToPoint: NSMakePoint(i, aRect.size.height)];
            }
        }
    }
    if(self.yIncrement > 0) {
        for(i=aRect.size.height; i>=0; i-=self.yIncrement) {
            if(i > self.scanPoint.y) {
                [done moveToPoint: NSMakePoint(0, i)];
                [done lineToPoint: NSMakePoint(aRect.size.width, i)];
            } else {
                [notDone moveToPoint: NSMakePoint(0, i)];
                [notDone lineToPoint: NSMakePoint(aRect.size.width, i)];
            }
        }
    }
    
	NSRect focusBox = NSZeroRect;
	focusBox.origin = NSPointFromCGPoint(self.scanPoint);
    NSBezierPath *mouse = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(focusBox, -5, -5)];
    
    [[NSColor greenColor] set];
    [done setLineWidth: 1.0];
    [done stroke];
    
    [[NSColor redColor] set];
    [notDone setLineWidth: 1.0];
    [notDone stroke];

    
    [[NSColor orangeColor] set];
    [border setLineWidth: 4.0];
    [border stroke];
    [mouse fill];
    
}

@end
