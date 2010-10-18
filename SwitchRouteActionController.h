//
//  SwitchRouteActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/14/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionController.h"

@interface SwitchRouteActionController : ActionController {
	
	IBOutlet NSPopUpButton *routePopUp;
	
	NSArray *_routes;
}

+ (id)switchRouteActionControllerWithRoutes: (NSArray*)routes;

@property (readwrite, copy) NSArray *routes;

@end
