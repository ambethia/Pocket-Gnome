//
//  RouteSet.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/21/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Route.h"
#import "FileObject.h"

#define PrimaryRoute        @"PrimaryRoute"
#define CorpseRunRoute      @"CorpseRunRoute"

@class RouteCollection;

// this class implements FileObject, but isn't actually saved (part of RouteCollection)
@interface RouteSet : FileObject {
    NSMutableDictionary *_routes;
	
	RouteCollection *_parent;
}

+ (id)routeSetWithName: (NSString*)name;

@property (readonly, retain) NSDictionary *routes;
@property (readwrite, retain) RouteCollection *parent;

- (Route*)routeForKey: (NSString*)key;
- (void)setRoute: (Route*)route forKey: (NSString*)key;

@end
