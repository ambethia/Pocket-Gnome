//
//  GrabWindow.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/8/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (GrabWindow)
//+ (NSImage*)imageWithWindow:(int)wid;
//+ (NSImage*)imageWithRect: (NSRect)rect inWindow:(int)wid;
+ (NSImage*)imageWithCGContextCaptureWindow: (int)wid;
+ (NSImage*)imageWithBitmapRep: (NSBitmapImageRep*)rep;

- (NSImage*)thumbnailWithMaxDimension: (float)dim;

@end

@interface NSBitmapImageRep (GrabWindow)
+ (NSBitmapImageRep*)correctBitmap: (NSBitmapImageRep*)rep;
+ (NSBitmapImageRep*)bitmapRepFromNSImage:(NSImage*)image;
+ (NSBitmapImageRep*)bitmapRepWithWindow:(int)wid;
@end