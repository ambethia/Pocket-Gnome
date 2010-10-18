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
 * $Id: PvPBehavior.h 435 2010-04-23 19:01:10Z ootoaoo $
 *
 */

#import <Cocoa/Cocoa.h>
#import "FileObject.h"

#define ZoneAlteracValley			2597
#define ZoneArathiBasin				3358
#define ZoneEyeOfTheStorm			3820
#define ZoneIsleOfConquest			4710
#define ZoneStrandOfTheAncients		4384
#define ZoneWarsongGulch			3277

@class Battleground;

@interface PvPBehavior : FileObject {
	
	// battlegrounds
	Battleground *_bgAlteracValley, *_bgArathiBasin, *_bgEyeOfTheStorm, *_bgIsleOfConquest, *_bgStrandOfTheAncients, *_bgWarsongGulch;
	
	
	
	// Note that these are all deprecaed (in the comabt profile now), but they've been left here so we dont' screw up the object people already have stored (not sure if it would be bad to remove these?)
	// options
	BOOL _random;
	BOOL _stopHonor;
	int _stopHonorTotal;
	BOOL _leaveIfInactive;
	BOOL _preparationDelay;
	BOOL _waitToLeave;
	float _waitTime;
}

@property (readwrite, retain) Battleground *AlteracValley;
@property (readwrite, retain) Battleground *ArathiBasin;
@property (readwrite, retain) Battleground *EyeOfTheStorm;
@property (readwrite, retain) Battleground *IsleOfConquest;
@property (readwrite, retain) Battleground *StrandOfTheAncients;
@property (readwrite, retain) Battleground *WarsongGulch;

@property (readwrite, assign) BOOL random;
@property (readwrite, assign) BOOL stopHonor;
@property (readwrite, assign) int stopHonorTotal;
@property (readwrite, assign) BOOL leaveIfInactive;
@property (readwrite, assign) BOOL preparationDelay;
@property (readwrite, assign) BOOL waitToLeave;
@property (readwrite, assign) float waitTime;

+ (id)pvpBehaviorWithName: (NSString*)name;

- (Battleground*)battlegroundForIndex:(int)index;
- (Battleground*)battlegroundForZone:(UInt32)zone;
- (BOOL)isValid;
- (BOOL)canDoRandom;

- (NSString*)formattedForJoinMacro;

@end
