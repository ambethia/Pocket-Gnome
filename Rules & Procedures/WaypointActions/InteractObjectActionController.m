//
//  InteractObjectActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "InteractObjectActionController.h"
#import "ActionController.h"

#import "Node.h"

@implementation InteractObjectActionController

- (id)init
{
    self = [super init];
    if (self != nil) {
		_objects = nil;
        if(![NSBundle loadNibNamed: @"InteractObjectAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading InteractObjectAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithZeObjects: (NSArray*)objects{
    self = [self init];
    if (self != nil) {
        self.objects = objects;
		
		if ( [objects count] == 0 ){
			[self removeBindings];
			
			NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"No Objects"] autorelease];
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"No nearby nodes were found" action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setTag:0];
			[menu addItem: item];
			
			[objectsPopUp setMenu:menu];	
		}
    }
    return self;
}

+ (id)interactObjectActionControllerWithObjects: (NSArray*)objects{
	return [[[InteractObjectActionController alloc] initWithZeObjects: objects] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [objectsPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[objectsPopUp unbind: binding];
	}
}

@synthesize objects = _objects;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [objectsPopUp itemArray] ){
		if ( [(Node*)[item representedObject] GUID] == [(NSNumber*)[action value] unsignedLongLongValue] ){
			[objectsPopUp selectItem:item];
			break;
		}
	}

	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_InteractObject value:nil];
	
	id object = [[objectsPopUp selectedItem] representedObject];
	id value = [NSNumber numberWithInt:[(Node*)object entryID]];
	
	[action setEnabled: self.enabled];
	[action setValue: value];
    
    return action;
}

@end
