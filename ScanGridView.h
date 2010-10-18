//
//  ScanGridView.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/31/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ScanGridView : NSView {
    float xInc, yInc;
    CGPoint scanPoint;
    CGPoint origin;
}

@property float xIncrement;
@property float yIncrement;
@property CGPoint scanPoint;
@property CGPoint origin;

@end
