//
//  EventController.m
//  Pocket Gnome
//
//  Created by Josh on 11/23/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "EventController.h"
#import "Controller.h"
#import "BotController.h"
#import "PlayerDataController.h"
#import "OffsetController.h"

#import "Player.h"
#import "MemoryAccess.h"

@interface EventController (Internal)

@end

@implementation EventController

- (id) init{
    self = [super init];
    if (self != nil) {
		
		_uberQuickTimer = nil;
		_oneSecondTimer = nil;
		_fiveSecondTimer = nil;
		_twentySecondTimer = nil;
		
		_lastPlayerZone = -1;
		_lastBGStatus = -1;
		_lastBattlefieldWinnerStatus = -1;
		_memory = nil;
	
		// Notifications
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(playerIsValid:) 
													 name: PlayerIsValidNotification 
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryValid:) 
                                                     name: MemoryAccessValidNotification 
                                                   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(memoryInvalid:) 
                                                     name: MemoryAccessInvalidNotification 
                                                   object: nil];
		
    }
    return self;
}

- (void) dealloc{
	[_memory release]; _memory = nil;
    [super dealloc];
}

#pragma mark Notifications

- (void)playerIsValid: (NSNotification*)not {
	_uberQuickTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1f target: self selector: @selector(uberQuickTimer:) userInfo: nil repeats: YES];
	//_oneSecondTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(oneSecondTimer:) userInfo: nil repeats: YES];
	//_fiveSecondTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0f target: self selector: @selector(fiveSecondTimer:) userInfo: nil repeats: YES];
	//_twentySecondTimer = [NSTimer scheduledTimerWithTimeInterval: 10.0f target: self selector: @selector(twentySecondTimer:) userInfo: nil repeats: YES];
}

- (void)playerIsInvalid: (NSNotification*)not {
	[_uberQuickTimer invalidate]; _uberQuickTimer = nil;
	[_fiveSecondTimer invalidate]; _fiveSecondTimer = nil;
	[_oneSecondTimer invalidate]; _oneSecondTimer = nil;
	[_twentySecondTimer invalidate]; _twentySecondTimer = nil;
}

- (void)memoryValid: (NSNotification*)not {
	_memory = [[controller wowMemoryAccess] retain];
}

- (void)memoryInvalid: (NSNotification*)not {
	[_memory release]; _memory = nil;
}

#pragma mark Timers

- (void)twentySecondTimer: (NSTimer*)timer {
	
}

- (void)oneSecondTimer: (NSTimer*)timer {

}

- (void)fiveSecondTimer: (NSTimer*)timer {

}

- (void)uberQuickTimer: (NSTimer*)timer {
	
	// check for a zone change!
	int currentZone = [playerController zone];
	if ( _lastPlayerZone != currentZone ){
		// only send notification if the zone had been set already!
		if ( _lastPlayerZone != -1 ){
			[[NSNotificationCenter defaultCenter] postNotificationName: EventZoneChanged object: [NSNumber numberWithInt:_lastPlayerZone]];
		}
	}
	
	int bgStatus = [playerController battlegroundStatus];
	if ( _lastBGStatus != bgStatus ){
		// only send notification if the zone had been set already!
		if ( _lastBGStatus != -1 ){
			[[NSNotificationCenter defaultCenter] postNotificationName: EventBattlegroundStatusChange object: [NSNumber numberWithInt:bgStatus]];
		}
		log(LOG_DEV, @"[Events] BGStatus change from %d to %d", _lastBGStatus, bgStatus);
	}
	
	_lastBGStatus = bgStatus;
	_lastPlayerZone = currentZone;
}

@end
