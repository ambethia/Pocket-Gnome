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
 * $Id: PvPBehavior.m 435 2010-04-23 19:01:10Z ootoaoo $
 *
 */

#import "PvPBehavior.h"

#import "Battleground.h"
#import "FileObject.h"

#define TotalBattlegrounds			6

@implementation PvPBehavior

- (id) init{
	
    self = [super init];
    if ( self != nil ){
		
		// initiate our BGs
		_bgAlteracValley			= [[Battleground battlegroundWithName:@"Alterac Valley" andZone:ZoneAlteracValley andQueueID:1] retain];
		_bgArathiBasin				= [[Battleground battlegroundWithName:@"Arathi Basin" andZone:ZoneArathiBasin andQueueID:3] retain];
		_bgEyeOfTheStorm			= [[Battleground battlegroundWithName:@"Eye of the Storm" andZone:ZoneEyeOfTheStorm andQueueID:7] retain];
		_bgIsleOfConquest			= [[Battleground battlegroundWithName:@"Isle of Conquest" andZone:ZoneIsleOfConquest andQueueID:30] retain];
		_bgStrandOfTheAncients		= [[Battleground battlegroundWithName:@"Strand of the Ancients" andZone:ZoneStrandOfTheAncients andQueueID:9] retain];
		_bgWarsongGulch				= [[Battleground battlegroundWithName:@"Warsong Gulch" andZone:ZoneWarsongGulch andQueueID:2] retain];
		
		_random = NO;
		_stopHonor = 0;
		_stopHonorTotal = 75000;
		_preparationDelay = YES;
		_leaveIfInactive = YES;
		_waitToLeave = YES;
		_waitTime = 10.0f;
		
		_name = [[NSString stringWithFormat:@"Unknown"] retain];
		
		_observers = [[NSArray arrayWithObjects: 
					   @"AlteracValley",
					   @"ArathiBasin",
					   @"EyeOfTheStorm",
					   @"IsleOfConquest",
					   @"StrandOfTheAncients",
					   @"WarsongGulch",
					   @"random",
					   @"stopHonor",
					   @"stopHonorTotal",
					   @"leaveIfInactive",
					   @"preparationDelay",
					   @"waitToLeave",
					   @"waitTime", nil] retain];
		
    }
    return self;
}

- (void) dealloc{
	[_bgAlteracValley release];
	[_bgArathiBasin release];
	[_bgEyeOfTheStorm release];
	[_bgIsleOfConquest release];
	[_bgStrandOfTheAncients release];
	[_bgWarsongGulch release];
	[_name release];
	
    [super dealloc];
}

- (id)initWithName:(NSString*)name{
	self = [self init];
    if (self != nil) {
		self.name = name;
	}
	return self;
}

+ (id)pvpBehaviorWithName: (NSString*)name {
    return [[[PvPBehavior alloc] initWithName: name] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder{
	self = [self init];
	if ( self ) {
		
		self.AlteracValley			= [decoder decodeObjectForKey: @"AlteracValley"];
		self.ArathiBasin			= [decoder decodeObjectForKey: @"ArathiBasin"];
		self.EyeOfTheStorm			= [decoder decodeObjectForKey: @"EyeOfTheStorm"];
		self.IsleOfConquest			= [decoder decodeObjectForKey: @"IsleOfConquest"];
		self.StrandOfTheAncients	= [decoder decodeObjectForKey: @"StrandOfTheAncients"];
		self.WarsongGulch			= [decoder decodeObjectForKey: @"WarsongGulch"];
		
		self.random = [[decoder decodeObjectForKey: @"Random"] boolValue];
		self.stopHonor = [[decoder decodeObjectForKey: @"StopHonor"] intValue];
		self.stopHonorTotal = [[decoder decodeObjectForKey: @"StopHonorTotal"] intValue];
		self.preparationDelay = [[decoder decodeObjectForKey: @"PreparationDelay"] boolValue];
		self.waitToLeave = [[decoder decodeObjectForKey: @"WaitToLeave"] boolValue];
		self.waitTime = [[decoder decodeObjectForKey: @"WaitTime"] floatValue];
		
		self.name = [decoder decodeObjectForKey:@"Name"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	
	[coder encodeObject: self.AlteracValley forKey:@"AlteracValley"];
	[coder encodeObject: self.ArathiBasin forKey:@"ArathiBasin"];
	[coder encodeObject: self.EyeOfTheStorm forKey:@"EyeOfTheStorm"];
	[coder encodeObject: self.IsleOfConquest forKey:@"IsleOfConquest"];
	[coder encodeObject: self.StrandOfTheAncients forKey:@"StrandOfTheAncients"];
	[coder encodeObject: self.WarsongGulch forKey:@"WarsongGulch"];
	
	[coder encodeObject: [NSNumber numberWithBool:self.random] forKey:@"Random"];
	[coder encodeObject: [NSNumber numberWithInt: self.stopHonor] forKey:@"StopHonor"];
	[coder encodeObject: [NSNumber numberWithInt: self.stopHonorTotal] forKey:@"StopHonorTotal"];
	[coder encodeObject: [NSNumber numberWithBool:self.preparationDelay] forKey:@"PreparationDelay"];
	[coder encodeObject: [NSNumber numberWithBool:self.waitToLeave] forKey:@"WaitToLeave"];
	[coder encodeObject: [NSNumber numberWithFloat: self.waitTime] forKey:@"WaitTime"];
	
	[coder encodeObject: self.name forKey:@"Name"];
}

- (id)copyWithZone:(NSZone *)zone{
    PvPBehavior *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
	
	copy.AlteracValley = self.AlteracValley;
	copy.ArathiBasin = self.ArathiBasin;
	copy.EyeOfTheStorm = self.EyeOfTheStorm;
	copy.IsleOfConquest = self.IsleOfConquest;
	copy.StrandOfTheAncients = self.StrandOfTheAncients;
	copy.WarsongGulch = self.WarsongGulch;
	
	copy.random = self.random;
	copy.stopHonor = self.stopHonor;
	copy.stopHonorTotal = self.stopHonorTotal;
	copy.preparationDelay = self.preparationDelay;
	copy.waitToLeave = self.waitToLeave;
	copy.waitTime = self.waitTime;
	
    return copy;
}

@synthesize AlteracValley = _bgAlteracValley;
@synthesize ArathiBasin = _bgArathiBasin;
@synthesize EyeOfTheStorm = _bgEyeOfTheStorm;
@synthesize IsleOfConquest = _bgIsleOfConquest;
@synthesize StrandOfTheAncients = _bgStrandOfTheAncients;
@synthesize WarsongGulch = _bgWarsongGulch;

@synthesize random = _random;
@synthesize stopHonor = _stopHonor;
@synthesize stopHonorTotal = _stopHonorTotal;
@synthesize leaveIfInactive = _leaveIfInactive;
@synthesize preparationDelay = _preparationDelay;
@synthesize waitToLeave = _waitToLeave;
@synthesize waitTime = _waitTime;

// little helper
- (BOOL)isValid{
	
	int totalEnabled = 0;
	
	if ( self.AlteracValley.enabled && self.AlteracValley.routeCollection != nil )
		totalEnabled++;
	if ( self.ArathiBasin.enabled && self.ArathiBasin.routeCollection != nil )
		totalEnabled++;
	if ( self.EyeOfTheStorm.enabled && self.EyeOfTheStorm.routeCollection != nil )
		totalEnabled++;
	if ( self.IsleOfConquest.enabled && self.IsleOfConquest.routeCollection != nil )
		totalEnabled++;
	if ( self.StrandOfTheAncients.enabled && self.StrandOfTheAncients.routeCollection != nil )
		totalEnabled++;
	if ( self.WarsongGulch.enabled && self.WarsongGulch.routeCollection != nil )
		totalEnabled++;
	
	// don't have the total for random!
	/*if ( self.random && totalEnabled != TotalBattlegrounds ){
	 return NO;
	 }*/
	// none enabled
	if ( totalEnabled == 0 ){
		return NO;
	}
	
	return YES;	
}

// we need a route collection for each BG
- (BOOL)canDoRandom{
	int totalEnabled = 0;
	
	if ( self.AlteracValley.enabled && self.AlteracValley.routeCollection != nil )
		totalEnabled++;
	if ( self.ArathiBasin.enabled && self.ArathiBasin.routeCollection != nil )
		totalEnabled++;
	if ( self.EyeOfTheStorm.enabled && self.EyeOfTheStorm.routeCollection != nil )
		totalEnabled++;
	if ( self.IsleOfConquest.enabled && self.IsleOfConquest.routeCollection != nil )
		totalEnabled++;
	if ( self.StrandOfTheAncients.enabled && self.StrandOfTheAncients.routeCollection != nil )
		totalEnabled++;
	if ( self.WarsongGulch.enabled && self.WarsongGulch.routeCollection != nil )
		totalEnabled++;	
	
	if ( totalEnabled == TotalBattlegrounds ){
		return YES;
	}
	
	return NO;
}

#pragma mark Accessors

// over-write our default changed!
- (BOOL)changed{
	
	if ( _changed )
		return YES;
	
	// any of the BGs change?
	if ( self.AlteracValley.changed )
		return YES;
	if ( self.ArathiBasin.changed )
		return YES;
	if ( self.EyeOfTheStorm.changed )
		return YES;
	if ( self.IsleOfConquest.changed )
		return YES;
	if ( self.StrandOfTheAncients.changed )
		return YES;
	if ( self.WarsongGulch.changed )
		return YES;
	
	return NO;
}

- (void)setChanged:(BOOL)changed{
	_changed = changed;
	
	// tell the BGs they're not changed!
	if ( changed == NO ){
		[self.AlteracValley setChanged:NO];
		[self.ArathiBasin setChanged:NO];
		[self.EyeOfTheStorm setChanged:NO];
		[self.IsleOfConquest setChanged:NO];
		[self.StrandOfTheAncients setChanged:NO];
		[self.WarsongGulch setChanged:NO];
	}
}

#pragma mark -

- (NSArray*)validBattlegrounds{
	
	NSMutableArray *validBGs = [NSMutableArray array];
	
	if ( [self.AlteracValley isValid] )
		[validBGs addObject:self.AlteracValley];
	if ( [self.ArathiBasin isValid] )
		[validBGs addObject:self.ArathiBasin];
	if ( [self.EyeOfTheStorm isValid] )
		[validBGs addObject:self.EyeOfTheStorm];
	if ( [self.IsleOfConquest isValid] )
		[validBGs addObject:self.IsleOfConquest];
	if ( [self.StrandOfTheAncients isValid] )
		[validBGs addObject:self.StrandOfTheAncients];
	if ( [self.WarsongGulch isValid] )
		[validBGs addObject:self.WarsongGulch];
	
	return [[validBGs retain] autorelease];
}

- (Battleground*)battlegroundForIndex:(int)index{
	
	NSArray *validBGs = [self validBattlegrounds];
	
	if ( [validBGs count] == 0 || index < 0 || index >= [validBGs count]) {
		return nil;
	}
	
	return [validBGs objectAtIndex:index];
}

- (Battleground*)battlegroundForZone:(UInt32)zone{
	
	if ( zone == [self.AlteracValley zone] && [self.AlteracValley enabled] ){
		return self.AlteracValley;
	}
	else if ( zone == [self.ArathiBasin zone] && [self.ArathiBasin enabled] ){
		return self.ArathiBasin;	
	}
	else if ( zone == [self.EyeOfTheStorm zone] && [self.EyeOfTheStorm enabled] ){
		return self.EyeOfTheStorm;
	}
	else if ( zone ==  [self.IsleOfConquest zone] && [self.IsleOfConquest enabled] ){
		return self.IsleOfConquest;
	}
	else if ( zone == [self.StrandOfTheAncients zone] && [self.StrandOfTheAncients enabled] ){
		return self.StrandOfTheAncients;
	}
	else if ( zone == [self.WarsongGulch zone] && [self.WarsongGulch enabled] ){
		return self.WarsongGulch;
	}
	
	return nil;
}

- (NSString*)formattedForJoinMacro{
	NSMutableString *bgs = [NSMutableString string];
	
	if ( self.AlteracValley.enabled && self.AlteracValley.routeCollection != nil )
		[bgs appendString:[NSString stringWithFormat:@"%d,", [self.AlteracValley queueID]]];
	if ( self.ArathiBasin.enabled && self.ArathiBasin.routeCollection != nil )
		[bgs appendString:[NSString stringWithFormat:@"%d,", [self.ArathiBasin queueID]]];
	if ( self.EyeOfTheStorm.enabled && self.EyeOfTheStorm.routeCollection != nil )
		[bgs appendString:[NSString stringWithFormat:@"%d,", [self.EyeOfTheStorm queueID]]];
	if ( self.IsleOfConquest.enabled && self.IsleOfConquest.routeCollection != nil )
		[bgs appendString:[NSString stringWithFormat:@"%d,", [self.IsleOfConquest queueID]]];
	if ( self.StrandOfTheAncients.enabled && self.StrandOfTheAncients.routeCollection != nil )
		[bgs appendString:[NSString stringWithFormat:@"%d,", [self.StrandOfTheAncients queueID]]];
	if ( self.WarsongGulch.enabled && self.WarsongGulch.routeCollection != nil )
		[bgs appendString:[NSString stringWithFormat:@"%d,", [self.WarsongGulch queueID]]];
	
	NSRange range = NSMakeRange(0, [bgs length] - 1);
	NSString *str = [bgs substringWithRange:range];
	
	return [[str retain] autorelease];
}

@end
