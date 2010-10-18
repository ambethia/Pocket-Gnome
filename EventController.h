//
//  EventController.h
//  Pocket Gnome
//
//  Created by Josh on 11/23/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define EventZoneChanged					@"EventZoneChanged"
#define EventBattlegroundStatusChange		@"EventBattlegroundStatusChange"

@class Controller;
@class BotController;
@class PlayerDataController;
@class OffsetController;

@class MemoryAccess;

@interface EventController : NSObject {
	IBOutlet Controller				*controller;
	IBOutlet BotController			*botController;
	IBOutlet PlayerDataController	*playerController;
	IBOutlet OffsetController		*offsetController;
	
	NSTimer *_uberQuickTimer;
	NSTimer *_oneSecondTimer;
	NSTimer *_fiveSecondTimer;
	NSTimer *_twentySecondTimer;
	
	int _lastPlayerZone;
	int _lastBGStatus;
	int _lastBattlefieldWinnerStatus;
	
	MemoryAccess *_memory;
}

@end
