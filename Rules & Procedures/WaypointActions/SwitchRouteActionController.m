//
//  SwitchRouteActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/14/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "SwitchRouteActionController.h"
#import "ActionController.h"

#import "RouteSet.h"

@implementation SwitchRouteActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
		_routes = nil;
        if(![NSBundle loadNibNamed: @"SwitchRouteAction" owner: self]) {
            log(LOG_GENERAL, @"Error loading SwitchRouteAction.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}
	
- (id) initWithRoutes: (NSArray*)routes{
    self = [self init];
    if (self != nil) {
        self.routes = routes;
		
		if ( [routePopUp numberOfItems] > 0 ){
			[routePopUp selectItemAtIndex:0];
			//[routePopUp removeItemWithTitle:@"No Value"];
		}
    }
    return self;
}


+ (id)switchRouteActionControllerWithRoutes: (NSArray*)routes{
	return [[[SwitchRouteActionController alloc] initWithRoutes: routes] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [routePopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[routePopUp unbind: binding];
	}
	/*
	[routePopUp unbind:NSSelectedValueBinding];
	[routePopUp unbind:NSContentObjectBinding];
	[routePopUp unbind:NSContentValuesBinding];
	[routePopUp unbind:NSContentBinding];*/
}

@synthesize routes = _routes;

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [routePopUp itemArray] ){
		
		log(LOG_GENERAL, @"not equal? %@ %@", [(RouteSet*)[item representedObject] UUID], action.value);
		
		if ( [[(RouteSet*)[item representedObject] UUID] isEqualToString:action.value] ){
			log(LOG_GENERAL, @"ZOMG EQUAL!");
			[routePopUp selectItem:item];
			break;
		}
	}
		
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_SwitchRoute value:nil];
	
	[action setEnabled: self.enabled];
	[action setValue: [[[routePopUp selectedItem] representedObject] UUID]];
	
	log(LOG_GENERAL, @" saving %d %@ for %@", self.enabled, [[[routePopUp selectedItem] representedObject] UUID], self);
    
    return action;
}

@end
