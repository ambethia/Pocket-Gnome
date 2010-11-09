//
//  CorpseController.h
//  Pocket Gnome
//
//  Created by Josh on 5/25/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class Position;

@interface CorpseController : NSObject {
    IBOutlet Controller *controller;
	
	NSMutableArray *_corpseList;
}

- (void)addAddresses: (NSArray*)addresses;

- (Position *) findPositionbyGUID: (GUID)GUID;

- (int)totalCorpses;

@end
