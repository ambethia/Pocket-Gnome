//
//  Macro.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 6/24/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "Macro.h"


@implementation Macro

+ (id)macroWithName: (NSString*)name number: (NSNumber*)number body: (NSString*)body isCharacter: (BOOL)isChar {
    Macro *newMacro = [[Macro alloc] init];
    if(newMacro) {
        newMacro.name = name;
        newMacro.body = body;
        newMacro.number = number;
        newMacro.isCharacter = isChar;
    }
    return [newMacro autorelease];
}

- (void) dealloc
{
    self.name = nil;
    self.body = nil;
    self.number = nil;
    [super dealloc];
}


@synthesize name;
@synthesize body;
@synthesize number;
@synthesize isCharacter;

- (NSString*)nameWithType{
	
	if ( self.isCharacter ){
		return [NSString stringWithFormat:@"Character - %@", self.name];
	}
	else{
		return [NSString stringWithFormat:@"Account - %@", self.name];
	}
}

@end
