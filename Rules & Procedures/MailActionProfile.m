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
 * $Id: MailActionProfile.m 315 2010-04-17 04:12:45Z Tanaris4 $
 *
 */

#import "MailActionProfile.h"

@implementation MailActionProfile

- (id) init
{
    self = [super init];
    if (self != nil) {
		_qualityPoor = NO;
		_qualityCommon = YES;
		_qualityUncommon = YES;
		_qualityRare = YES;
		_qualityEpic = YES;
		_qualityLegendary = YES;
		_includeItems = NO;
		_excludeItems = YES;
		_itemsToInclude = @"*";
		_itemsToExclude = @"Hearthstone, Mining Pick, Strong Fishing Pole";
		_sendTo = @"";
		
		_observers = [[NSArray arrayWithObjects:
					   @"qualityPoor",
					   @"qualityCommon",
					   @"qualityUncommon",
					   @"qualityRare",
					   @"qualityEpic",
					   @"qualityLegendary",
					   @"includeItems",
					   @"excludeItems",
					   @"itemsToInclude",
					   @"itemsToExclude",
					   @"sendTo",
					   nil] retain];
    }
    return self;
}

+ (id)mailActionProfileWithName: (NSString*)name {
    return [[[MailActionProfile alloc] initWithName: name] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder{
	self = [self init];
	if ( self ) {
		
		self.qualityPoor                = [[decoder decodeObjectForKey: @"QualityPoor"] boolValue];
		self.qualityCommon              = [[decoder decodeObjectForKey: @"QualityCommon"] boolValue];
		self.qualityUncommon    = [[decoder decodeObjectForKey: @"QualityUncommon"] boolValue];
		self.qualityRare                = [[decoder decodeObjectForKey: @"QualityRare"] boolValue];
		self.qualityEpic                = [[decoder decodeObjectForKey: @"QualityEpic"] boolValue];
		self.qualityLegendary   = [[decoder decodeObjectForKey: @"QualityLegendary"] boolValue];
		
		self.includeItems = [[decoder decodeObjectForKey:@"IncludeItems"] boolValue];
		self.excludeItems = [[decoder decodeObjectForKey:@"ExcludeItems"] boolValue];
		
		self.itemsToInclude = [decoder decodeObjectForKey:@"ItemsToInclude"];
		self.itemsToExclude = [decoder decodeObjectForKey:@"ItemsToExclude"];
		
		self.sendTo = [decoder decodeObjectForKey:@"SendTo"];
		
		[super initWithCoder:decoder];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	
	[super encodeWithCoder:coder];
	
	[coder encodeObject: [NSNumber numberWithBool:self.qualityPoor] forKey:@"QualityPoor"];
	[coder encodeObject: [NSNumber numberWithBool:self.qualityCommon] forKey:@"QualityCommon"];
	[coder encodeObject: [NSNumber numberWithBool:self.qualityUncommon] forKey:@"QualityUncommon"];
	[coder encodeObject: [NSNumber numberWithBool:self.qualityRare] forKey:@"QualityRare"];
	[coder encodeObject: [NSNumber numberWithBool:self.qualityEpic] forKey:@"QualityEpic"];
	[coder encodeObject: [NSNumber numberWithBool:self.qualityLegendary] forKey:@"QualityLegendary"];
	
	[coder encodeObject: [NSNumber numberWithBool:self.includeItems] forKey:@"IncludeItems"];
	[coder encodeObject: [NSNumber numberWithBool:self.excludeItems] forKey:@"ExcludeItems"];
	
	[coder encodeObject: self.itemsToInclude forKey:@"ItemsToInclude"];
	[coder encodeObject: self.itemsToExclude forKey:@"ItemsToExclude"];
	[coder encodeObject: self.sendTo forKey:@"SendTo"];
}

- (id)copyWithZone:(NSZone *)zone{
    MailActionProfile *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
	
	copy.qualityPoor = self.qualityPoor;
	copy.qualityCommon = self.qualityCommon;
	copy.qualityUncommon = self.qualityCommon;
	copy.qualityRare = self.qualityRare;
	copy.qualityEpic = self.qualityEpic;
	copy.qualityLegendary = self.qualityLegendary;
	
	copy.includeItems = self.includeItems;
	copy.excludeItems = self.excludeItems;
	
	copy.itemsToInclude = self.itemsToInclude;
	copy.itemsToExclude = self.itemsToExclude;
	copy.sendTo = self.sendTo;
	
    return copy;
}

@synthesize qualityPoor = _qualityPoor;
@synthesize qualityCommon = _qualityCommon;
@synthesize qualityUncommon = _qualityUncommon;
@synthesize qualityRare = _qualityRare;
@synthesize qualityEpic = _qualityEpic;
@synthesize qualityLegendary = _qualityLegendary;
@synthesize includeItems = _includeItems;
@synthesize excludeItems = _excludeItems;
@synthesize itemsToInclude = _itemsToInclude;
@synthesize itemsToExclude = _itemsToExclude;
@synthesize sendTo = _sendTo;

- (NSArray*)inclusions{
	
	if ( !self.includeItems ){
		return nil;
	}
	
	NSMutableArray *final = [NSMutableArray array];
	NSArray *list = [self.itemsToInclude componentsSeparatedByString:@","];
	
	for ( NSString *str in list ){
		[final addObject:[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
	
	return final;
}

- (NSArray*)exclusions{
	if ( !self.excludeItems ){
		return nil;
	}         
	
	NSMutableArray *final = [NSMutableArray array];
	NSArray *list = [self.itemsToExclude componentsSeparatedByString:@","];
	
	for ( NSString *str in list ){
		[final addObject:[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
	
	return final;
}
@end