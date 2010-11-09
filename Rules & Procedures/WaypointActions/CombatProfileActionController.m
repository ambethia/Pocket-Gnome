//
//  CombatProfileActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "CombatProfileActionController.h"
#import "ActionController.h"

#import "CombatProfile.h"

@implementation CombatProfileActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_profiles = nil;
        if(![NSBundle loadNibNamed: @"CombatProfileAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading CombatProfileAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithProfiles: (NSArray*)profiles{
    self = [self init];
    if (self != nil) {
        self.profiles = profiles;
    }
    return self;
}

+ (id)combatProfileActionControllerWithProfiles: (NSArray*)profiles{
	return [[[CombatProfileActionController alloc] initWithProfiles: profiles] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [profilePopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[profilePopUp unbind: binding];
	}
}

@synthesize profiles = _profiles;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [profilePopUp itemArray] ){
		if ( [[(CombatProfile*)[item representedObject] UUID] isEqualToString:action.value] ){
			[profilePopUp selectItem:item];
			break;
		}
	}
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_CombatProfile value:nil];
	
	[action setEnabled: self.enabled];
	[action setValue: [[[profilePopUp selectedItem] representedObject] UUID]];
	
	log(LOG_GENERAL, @"saving combat profile with %@", [[[profilePopUp selectedItem] representedObject] UUID]);
    
    return action;
}


@end
