//
//  Condition.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Condition.h"


@implementation Condition

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.variety    = 0;
        self.unit       = 0;
        self.quality    = 0;
        self.comparator = 0;
        self.state      = 0;
        self.type       = 0;
        self.value      = nil;
    }
    return self;
}

- (id)initWithVariety: (int)variety unit: (int)unit quality: (int)quality comparator: (int)comparator state: (int)state type: (int)type value: (id)value {
    [self init];
    if(self) {
        self.variety    = variety;
        self.unit       = unit;
        self.quality    = quality;
        self.comparator = comparator;
        self.state      = state;
        self.type       = type;
        self.value      = value;
    }
    return self;
}

+ (id)conditionWithVariety: (int)variety unit: (int)unit quality: (int)quality comparator: (int)comparator state: (int)state type: (int)type value: (id)value {
    return [[[Condition alloc] initWithVariety: variety 
                                          unit: unit 
                                       quality: quality 
                                    comparator: comparator 
                                         state: state 
                                          type: type 
                                         value: value] autorelease];                      
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.variety    = [[decoder decodeObjectForKey: @"Variety"] intValue];
        self.unit       = [[decoder decodeObjectForKey: @"Unit"] intValue];
        self.quality    = [[decoder decodeObjectForKey: @"Quality"] intValue];
        self.comparator = [[decoder decodeObjectForKey: @"Comparator"] intValue];
        self.state      = [[decoder decodeObjectForKey: @"State"] intValue];
        self.type       = [[decoder decodeObjectForKey: @"Type"] intValue];
        self.value      = [decoder decodeObjectForKey: @"Value"];
        
        self.enabled = [decoder decodeObjectForKey: @"Enabled"] ? [[decoder decodeObjectForKey: @"Enabled"] boolValue] : YES;
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: [NSNumber numberWithInt: [self variety]] forKey: @"Variety"];
    [coder encodeObject: [NSNumber numberWithInt: [self unit]] forKey: @"Unit"];
    [coder encodeObject: [NSNumber numberWithInt: [self quality]] forKey: @"Quality"];
    [coder encodeObject: [NSNumber numberWithInt: [self comparator]] forKey: @"Comparator"];
    [coder encodeObject: [NSNumber numberWithInt: [self state]] forKey: @"State"];
    [coder encodeObject: [NSNumber numberWithInt: [self type]] forKey: @"Type"];
    [coder encodeObject: [self value] forKey: @"Value"];
    [coder encodeObject: [NSNumber numberWithBool: self.enabled] forKey: @"Enabled"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Condition *copy = [[[self class] allocWithZone: zone] initWithVariety: [self variety] 
                                                                     unit: [self unit]
                                                                  quality: [self quality]
                                                               comparator: [self comparator]
                                                                    state: [self state]
                                                                     type: [self type] 
                                                                    value: [self value]];
    [copy setEnabled: [self enabled]];
        
    return copy;
}

- (void) dealloc
{
    [_value release];
    [super dealloc];
}

@synthesize variety = _variety;
@synthesize unit = _unit;
@synthesize quality = _quality;
@synthesize comparator = _comparator;
@synthesize state = _state;
@synthesize type = _type;

@synthesize value = _value;
@synthesize enabled = _enabled;

- (NSString*)description {
    return [NSString stringWithFormat: @"<Condition Variety: %d, Unit: %d, Qual: %d, Comp: %d, State: %d, Type: %d, Val: %@", _variety, _unit, _quality, _comparator, _state, _type, _value];
}


@end
