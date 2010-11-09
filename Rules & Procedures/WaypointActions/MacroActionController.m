//
//  MacroActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//
#import "ActionController.h"
#import "MacroActionController.h"

#import "Action.h"
#import "Macro.h"

@implementation MacroActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_macros = nil;
        if(![NSBundle loadNibNamed: @"MacroAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading MacroAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithMacros: (NSArray*)macros{
    self = [self init];
    if (self != nil) {
        self.macros = macros;
    }
    return self;
}

+ (id)macroActionControllerWithMacros: (NSArray*)macros{
	NSMutableArray *arrayToSort = [NSMutableArray arrayWithArray:macros];
    [arrayToSort sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"nameWithType" ascending: YES] autorelease]]];
	return [[[MacroActionController alloc] initWithMacros: arrayToSort] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [macroPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[macroPopUp unbind: binding];
	}
}

@synthesize macros = _macros;

- (void)setStateFromAction: (Action*)action{

	NSNumber *macroID = [[action value] objectForKey:@"MacroID"];
	NSNumber *instant = [[action value] objectForKey:@"Instant"];
	
	for ( NSMenuItem *item in [macroPopUp itemArray] ){
		if ( [[(Macro*)[item representedObject] number] intValue] == [macroID intValue] ){
			[macroPopUp selectItem:item];
			break;
		}
	}
	
	[instantButton setState:[instant boolValue]];
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Macro value:nil];
	
	[action setEnabled: self.enabled];
	
	NSNumber *macroID = [[[macroPopUp selectedItem] representedObject] number];
	NSNumber *instant = [NSNumber numberWithBool:[instantButton state]];
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
							macroID,		@"MacroID",
							instant,		@"Instant", nil];
	[action setValue: values];
    
    return action;
}


@end
