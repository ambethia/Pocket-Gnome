/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id: Battleground.h 325 2010-04-01 22:59:14Z ootoaoo $
 *
 */

#import <Cocoa/Cocoa.h>

@class RouteCollection;

@interface Battleground : NSObject {
	
	NSString *_name;
	int _zone;			// what zone is this BG associated with
	int _queueID;		// what ID should we send in our queue macro!
	BOOL _enabled;
	
	// we'll never actually save this to the disk (it will be part of PvPBehavior, so we have to track this)
	BOOL _changed;
	
	RouteCollection *_routeCollection;	
}

@property (readonly) int zone;
@property (readonly) int queueID;
@property (readonly, retain) NSString *name;
@property (readwrite, assign) BOOL enabled;
@property (readwrite, retain) RouteCollection *routeCollection;
@property (readwrite, assign) BOOL changed;

+ (id)battlegroundWithName: (NSString*)name andZone: (int)zone andQueueID: (int)queueID;

- (BOOL)isValid;

@end
