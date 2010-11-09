//
//  Behavior.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Procedure.h"
#import "FileObject.h"

#define PreCombatProcedure  @"PreCombatProcedure"
#define CombatProcedure     @"CombatProcedure"
#define PostCombatProcedure @"PostCombatProcedure"
#define RegenProcedure      @"RegenProcedure"
#define PatrollingProcedure @"PatrollingProcedure"

@interface Behavior : FileObject {
    BOOL _meleeCombat, _usePet, _useStartAttack;
    NSMutableDictionary *_procedures;
}

+ (id)behaviorWithName: (NSString*)name;

@property (readonly, retain) NSDictionary *procedures;
@property BOOL meleeCombat;
@property BOOL usePet;
@property BOOL useStartAttack;

- (Procedure*)procedureForKey: (NSString*)key;

- (NSArray*)allProcedures;

@end
