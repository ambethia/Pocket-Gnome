//
//  Action.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 9/6/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "Action.h"
#import "RouteSet.h"
#import "Route.h"
#import "Spell.h"
#import "SpellController.h"

@implementation Action

- (id) init {
    return [self initWithType: ActionType_None value: nil];
}

- (id)initWithType: (ActionType)type value: (id)value {
    self = [super init];
    if (self != nil) {
        self.type = type;
        self.value = value;
		self.enabled = YES;
        //self.delay = delay;
        //self.actionID = actionID;
    }
    return self;
}

+ (id)actionWithType: (ActionType)type value: (id)value {
    return [[[[self class] alloc] initWithType: type value: value] autorelease];
}

+ (id)action {
    return [[self class] actionWithType: ActionType_None value: nil];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if(self) {
        self.type = [[decoder decodeObjectForKey: @"Type"] unsignedIntValue];
        self.value = ([decoder decodeObjectForKey: @"Value"] ? [decoder decodeObjectForKey: @"Value"] : nil);
		self.enabled = [decoder decodeObjectForKey: @"Enabled"] ? [[decoder decodeObjectForKey: @"Enabled"] boolValue] : YES;
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject: [NSNumber numberWithUnsignedInt: self.type]    forKey: @"Type"];
	
    if(self.type > ActionType_None){
        [coder encodeObject: self.value                                 forKey: @"Value"];
		[coder encodeObject: [NSNumber numberWithBool: self.enabled] forKey: @"Enabled"];
	}
}

- (id)copyWithZone:(NSZone *)zone {
    Action *copy = [[[self class] allocWithZone: zone] initWithType: self.type value: self.value];
    return copy;
}

- (void) dealloc {
    self.value = nil;
    [super dealloc];
}


@synthesize type = _type;
@synthesize value = _value;
@synthesize enabled = _enabled;

- (void)setType: (ActionType)type {
    if(type < ActionType_None || (type >= ActionType_Max)) {
        type = ActionType_None;
    }
    
    _type = type;
}

- (float)delay {
    if(self.type == ActionType_Delay) {
        return [self.value floatValue];
    }
    return 0.0f;
}

- (UInt32)actionID {
	
    if(self.type == ActionType_Spell || self.type == ActionType_Item || self.type == ActionType_Macro) {
        return [self.value unsignedIntValue];
    }
    return 0;
}

- (RouteSet*)route{
	
	if ( self.type == ActionType_SwitchRoute ){
		return (RouteSet*)self.value;
	}
	
	return nil;
}

@end
