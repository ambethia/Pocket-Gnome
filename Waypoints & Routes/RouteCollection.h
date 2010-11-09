//
//  RouteCollection.h
//  Pocket Gnome
//
//  Created by Josh on 2/11/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileObject.h"

@class RouteSet;

@interface RouteCollection : FileObject {
	NSMutableArray *_routes;
	
	NSString *_startUUID;
	
	BOOL _startRouteOnDeath;
}

+ (id)routeCollectionWithName: (NSString*)name;

@property (readonly, retain) NSMutableArray *routes;
@property BOOL startRouteOnDeath;

- (void)moveRouteSet:(RouteSet*)route toLocation:(int)index;
- (void)addRouteSet:(RouteSet*)route;
- (BOOL)removeRouteSet:(RouteSet*)route;
- (BOOL)containsRouteSet:(RouteSet*)route;

- (RouteSet*)startingRoute;
- (void)setStartRoute:(RouteSet*)route;
- (BOOL)isStartingRoute:(RouteSet*)route;

@end
