//
//  Procedure.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Procedure.h"
#import "FileObject.h"

@interface Procedure ()
@property (readwrite, retain) NSArray *rules;
@end

@implementation Procedure

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.name = nil;
        self.rules = [NSArray array];
    }
    return self;
}

- (id)initWithName: (NSString*)name {
    self = [self init];
    if (self != nil) {
        self.name = name;
    }
    return self;
}

+ (id)procedureWithName: (NSString*)name {
    return [[[[self class] alloc] initWithName: name] autorelease];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.rules = [decoder decodeObjectForKey: @"Rules"] ? [decoder decodeObjectForKey: @"Rules"] : [NSArray array];
        self.name = [decoder decodeObjectForKey: @"Name"];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.name forKey: @"Name"];
    [coder encodeObject: self.rules forKey: @"Rules"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Procedure *copy = [[[self class] allocWithZone: zone] initWithName: self.name];

    copy.rules = self.rules;
            
    return copy;
}

- (void) dealloc {
    self.name = nil;
    self.rules = nil;
    [super dealloc];
}

#pragma mark -

- (NSString*)description {
    return [NSString stringWithFormat: @"<Procedure %@: %d rules>", [self name], [self ruleCount]];
}

@synthesize name = _name;
@synthesize rules = _rules;

- (void)setRules: (NSArray*)rules {
    [_rules autorelease];
    if(rules) {
        _rules = [[NSMutableArray alloc] initWithArray: rules copyItems: YES];
    } else {
        _rules = nil;
    }
}

- (unsigned)ruleCount {
    return [self.rules count];
}

- (Rule*)ruleAtIndex: (unsigned)index {
    if(index >= 0 && index < [self ruleCount])
        return [[[_rules objectAtIndex: index] retain] autorelease];
    return nil;
}

- (void)addRule: (Rule*)rule {
    if(rule != nil){
        [_rules addObject: rule];
	}
    else{
        log(LOG_GENERAL, @"addRule: failed; rule is nil");
	}
}

- (void)insertRule: (Rule*)rule atIndex: (unsigned)index {
    if(rule != nil && index >= 0 && index <= [_rules count]){
        [_rules insertObject: rule atIndex: index];
	}
    else{
        log(LOG_GENERAL, @"insertRule:atIndex: failed; rule %@ index %d is out of bounds", rule, index);
	}
}

- (void)replaceRuleAtIndex: (int)index withRule: (Rule*)rule {

    if((rule != nil) && (index >= 0) && (index < [self ruleCount])) {
        [_rules replaceObjectAtIndex: index withObject: rule];
    }
	else{
        log(LOG_GENERAL, @"replaceRule:atIndex: failed; either rule is nil or index is out of bounds");
	}
}

- (void)removeRule: (Rule*)rule {
    if(rule == nil) return;
    [_rules removeObject: rule];
}

- (void)removeRuleAtIndex: (unsigned)index {
    if(index >= 0 && index < [self ruleCount]){
        [_rules removeObjectAtIndex: index];
	}
}

@end
