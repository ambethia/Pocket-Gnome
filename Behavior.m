//
//  Behavior.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Behavior.h"
#import "FileObject.h"

@interface Behavior ()
@property (readwrite, retain) NSDictionary *procedures;
@end

@interface Behavior (Internal)
- (void)setProcedure: (Procedure*)proc forKey: (NSString*)key;
@end

@implementation Behavior

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.procedures = [NSDictionary dictionary];
        self.meleeCombat = NO;
        self.usePet = NO;
		self.useStartAttack = NO;
		
		_observers = [[NSArray arrayWithObjects:
					   @"usePet",
					   @"meleeCombat",
					   @"useStartAttack",
					   nil] retain];
    }
    return self;
}

- (id)initWithName: (NSString*)name {
    self = [self init];
    
	if ( self ){
		self.name = name;
		self.procedures = [NSDictionary dictionaryWithObjectsAndKeys: 
						   [Procedure procedureWithName: name], PreCombatProcedure,
						   [Procedure procedureWithName: name], CombatProcedure,
						   [Procedure procedureWithName: name], PostCombatProcedure,
						   [Procedure procedureWithName: name], RegenProcedure,
						   [Procedure procedureWithName: name], PatrollingProcedure, nil];
	}
    
    return self;
}


+ (id)behaviorWithName: (NSString*)name {
    return [[[Behavior alloc] initWithName: name] autorelease];
}


- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if ( self ) {
        self.procedures = [decoder decodeObjectForKey: @"Procedures"] ? [decoder decodeObjectForKey: @"Procedures"] : [NSDictionary dictionary];
        
        // make sure we have a procedure object for every type
        if( ![self procedureForKey: PreCombatProcedure])
            [self setProcedure: [Procedure procedureWithName: [self name]] forKey: PreCombatProcedure];
        if( ![self procedureForKey: CombatProcedure])
            [self setProcedure: [Procedure procedureWithName: [self name]] forKey: CombatProcedure];
        if( ![self procedureForKey: PostCombatProcedure])
            [self setProcedure: [Procedure procedureWithName: [self name]] forKey: PostCombatProcedure];
        if( ![self procedureForKey: RegenProcedure])
            [self setProcedure: [Procedure procedureWithName: [self name]] forKey: RegenProcedure];
        if( ![self procedureForKey: PatrollingProcedure])
            [self setProcedure: [Procedure procedureWithName: [self name]] forKey: PatrollingProcedure];
        
        if([decoder decodeObjectForKey: @"MeleeCombat"]) {
            self.meleeCombat = [[decoder decodeObjectForKey: @"MeleeCombat"] boolValue];
        }
        
        if([decoder decodeObjectForKey: @"UsePet"]) {
            self.usePet = [[decoder decodeObjectForKey: @"UsePet"] boolValue];
        }

        if([decoder decodeObjectForKey: @"UseStartAttack"]) {
            self.useStartAttack = [[decoder decodeObjectForKey: @"UseStartAttack"] boolValue];
        }
		
		[super initWithCoder:decoder];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
    [coder encodeObject: self.procedures forKey: @"Procedures"];
    [coder encodeObject: [NSNumber numberWithBool: self.meleeCombat] forKey: @"MeleeCombat"];
    [coder encodeObject: [NSNumber numberWithBool: self.usePet] forKey: @"UsePet"];
    [coder encodeObject: [NSNumber numberWithBool: self.usePet] forKey: @"UseStartAttack"];
}

- (id)copyWithZone:(NSZone *)zone
{
    Behavior *copy = [[[self class] allocWithZone: zone] initWithName: self.name];

    copy.procedures = self.procedures;
    copy.usePet = self.usePet;
    copy.meleeCombat = self.meleeCombat;
    copy.useStartAttack = self.useStartAttack;
	copy.changed = YES;
        
    return copy;
}

- (void) dealloc{
	[_observers release];
	_observers = nil;
	[_procedures release];
	_procedures = nil;
//    self.procedures = nil;

    [super dealloc];
}

#pragma mark -


- (NSString*)description {
    return [NSString stringWithFormat: @"<Behavior %@>", [self name]];
}

@synthesize procedures = _procedures;
@synthesize meleeCombat = _meleeCombat;
@synthesize usePet = _usePet;
@synthesize useStartAttack = _useStartAttack;
- (Procedure*)procedureForKey: (NSString*)key {
    return [_procedures objectForKey: key];
}

- (NSArray*)allProcedures{
	NSMutableArray *allProcedures = [NSMutableArray array];
	
	if ( [_procedures objectForKey: PreCombatProcedure] )
		[allProcedures addObject:[_procedures objectForKey: PreCombatProcedure]];
	if ( [_procedures objectForKey: CombatProcedure] )
		[allProcedures addObject:[_procedures objectForKey: CombatProcedure]];
	if ( [_procedures objectForKey: PostCombatProcedure] )
		[allProcedures addObject:[_procedures objectForKey: PostCombatProcedure]];
	if ( [_procedures objectForKey: RegenProcedure] )
		[allProcedures addObject:[_procedures objectForKey: RegenProcedure]];
	if ( [_procedures objectForKey: PatrollingProcedure] )
		[allProcedures addObject:[_procedures objectForKey: PatrollingProcedure]];
	
	return [[allProcedures retain] autorelease];
}

- (void)setProcedure: (Procedure*)proc forKey: (NSString*)key {
    if(proc && key) {
        [_procedures setObject: proc forKey: key];
    }
}

- (void)setProcedures: (NSDictionary*)procedureDict {
    [_procedures autorelease];
    if(procedureDict) {
        _procedures = [[NSMutableDictionary alloc] initWithDictionary: procedureDict copyItems: YES];
    } else {
        _procedures = nil;
    }
}

@end
