//
//  Rule.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Rule.h"
#import "Action.h"

@implementation Rule

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.isMatchAll = YES;
        self.conditions = [NSArray array];
        self.name = nil;
        self.action = [Action action];
		self.target = -1;
        //self.actionID = 0;
        //self.resultType = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        [self setName: [decoder decodeObjectForKey: @"Name"]];
        [self setIsMatchAll: [[decoder decodeObjectForKey: @"MatchAll"] boolValue]];
        [self setConditions: [decoder decodeObjectForKey: @"Conditions"]];
		[self setTarget: [[decoder decodeObjectForKey: @"Target"] intValue]];
        
        // we have an old-style rule we must import
        if([decoder decodeObjectForKey: @"ResultType"] && [decoder decodeObjectForKey: @"ActionID"]) {
            self.action = [Action actionWithType: [[decoder decodeObjectForKey: @"ResultType"] unsignedIntValue]
                                           value: [decoder decodeObjectForKey: @"ActionID"]];
            // log(LOG_GENERAL, @"Translating action %@ to %@", [decoder decodeObjectForKey: @"ActionID"], self.action);
        } else {
            self.action = [decoder decodeObjectForKey: @"Action"] ? [decoder decodeObjectForKey: @"Action"] : [Action action];
        }
        
        //[self setResultType: [[decoder decodeObjectForKey: @"ResultType"] intValue]];
        //[self setActionID: [[decoder decodeObjectForKey: @"ActionID"] unsignedIntValue]];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: [self name] forKey: @"Name"];
    [coder encodeObject: [NSNumber numberWithBool: [self isMatchAll]] forKey: @"MatchAll"];
    [coder encodeObject: [self conditions] forKey: @"Conditions"];
    [coder encodeObject: self.action forKey: @"Action"];
	[coder encodeObject: [NSNumber numberWithInt:self.target] forKey: @"Target"];
    
    //[coder encodeObject: [NSNumber numberWithInt: [self resultType]] forKey: @"ResultType"];
    //[coder encodeObject: [NSNumber numberWithUnsignedInt: [self actionID]] forKey: @"ActionID"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Rule *copy = [[[self class] allocWithZone: zone] init];

    copy.name = self.name;
    copy.conditions = self.conditions;
    copy.isMatchAll = self.isMatchAll;
    copy.action = self.action;
	copy.target = self.target;
    //copy.resultType = self.resultType;
    //copy.actionID = self.actionID;
            
    return copy;
}

- (void) dealloc {
    self.conditions = nil;
    self.name = nil;
    self.action = nil;

    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    NSString *resultType = @"No Action";
    if(self.action.type == ActionType_Spell) resultType = @"Cast Spell";
    if(self.action.type == ActionType_Item) resultType = @"Use Item";
    if(self.action.type == ActionType_Macro) resultType = @"Use Macro";
    return [NSString stringWithFormat: @"<Rule \"%@\" (%@ %d conditions); %@ (%@)>", [self name], [self isMatchAll] ? @"Match all" : @"Match any of", [[self conditions] count], resultType, self.action.value];
}

@synthesize name = _name;
@synthesize isMatchAll = _matchAll;
@synthesize conditions = _conditionsList;
@synthesize action = _action;
@synthesize target = _target;
//@synthesize resultType = _resultType;
//@synthesize actionID = _actionID;

- (void)setConditions: (NSArray*)conditions {
    [_conditionsList autorelease];
    if(conditions) {
        _conditionsList = [[NSMutableArray alloc] initWithArray: conditions copyItems: YES];
    } else {
        _conditionsList = nil;
    }
}

- (ActionType)resultType {
    return [[self action] type];
}

- (UInt32)actionID {
    return [[self action] actionID];
}

@end
