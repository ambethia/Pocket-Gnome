//
//  PlayersController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 5/25/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "PlayersController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "MemoryViewController.h"
#import "MovementController.h"
#import "ObjectsController.h"

#import "ImageAndTextCell.h"

#import "Player.h"
#import "Unit.h"
#import "Offsets.h"

@interface PlayersController (Internal)
- (BOOL)trackingPlayer: (Player*)trackingPlayer;
- (NSString*)unitClassToString: (UnitClass)unitClass;
@end

@implementation PlayersController

static PlayersController *sharedPlayers = nil;

+ (PlayersController *)sharedPlayers {
	if (sharedPlayers == nil)
		sharedPlayers = [[[self class] alloc] init];
	return sharedPlayers;
}

- (id) init
{
    self = [super init];
	if(sharedPlayers) {
		[self release];
		self = sharedPlayers;
    } else {
        sharedPlayers = self;
        [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObject: @"0.5" forKey: @"PlayersControllerUpdateFrequency"]];
		_playerNameList = [[NSMutableDictionary dictionary] retain];
    }
	
    return self;
}

#pragma mark -
#pragma mark Data Set Management

- (NSArray*)allPlayers {
    return [[_objectList retain] autorelease];
}

- (Player*)playerTarget {
    GUID playerTarget = [playerData targetID];
    
    for(Player *player in _objectList) {
        if( playerTarget == [player GUID]) {
            return [[player retain] autorelease];
        }
    }
    return nil;
}

- (Player*)playerWithGUID: (GUID)guid {
    for(Player *player in _objectList) {
        if( guid == [player GUID]) {
            return [[player retain] autorelease];
        }
    }
    return nil;
}

- (void)addAddresses: (NSArray*)addresses {
	[super addAddresses:addresses];
	
    [self updateTracking:nil];
}

#pragma mark Player Name Storage

- (NSString*)playerNameWithGUID:(UInt64)guid{
	NSNumber *fullGUID = [NSNumber numberWithUnsignedLongLong:guid];
	NSString *name = [_playerNameList objectForKey: fullGUID];
	
	if ( name ){
		return [[name copy] autorelease];
	}
	
	return @"";
}

// returns yes on adding
- (BOOL)addPlayerName: (NSString*)name withGUID:(UInt64)guid{
	
	if ( name == nil ){
		//log(LOG_GENERAL, @"[Players] Name not added for 0x%qX, not found", guid);
		return NO;
	}
	
	NSNumber *fullGUID = [NSNumber numberWithUnsignedLongLong:guid];
	
	if ( ![_playerNameList objectForKey: fullGUID] ){
		
		[_playerNameList  setObject: name forKey: fullGUID];
		
		return YES;
	}
	
	return NO;
}

- (int)totalNames{
	return [_playerNameList count];
}

- (unsigned int)objectCount {
	return [_objectList count];     
}

- (unsigned)playerCount {
    return [_objectList count];
}


- (BOOL)trackingPlayer: (Player*)trackingPlayer {
    for(Player *player in _objectList) {
        if( [player isEqualToObject: trackingPlayer] ) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -

- (NSArray*)friendlyPlayers{
	
	NSMutableArray *friendlyUnits = [NSMutableArray array];
	
	for(Unit *unit in _objectList) {
		int faction = [unit factionTemplate];
		BOOL isFriendly = [playerData isFriendlyWithFaction: faction];
		
		if ( isFriendly){
			[friendlyUnits addObject: unit];
		}       
	}
	
	return friendlyUnits;
}

- (NSArray*)playersWithinDistance: (float)unitDistance
                       levelRange: (NSRange)range
                  includeFriendly: (BOOL)friendly
                   includeNeutral: (BOOL)neutral
                   includeHostile: (BOOL)hostile {
    
    
    NSMutableArray *unitsWithinRange = [NSMutableArray array];
    
    BOOL ignoreLevelOne = [playerData level] > 10 ? YES : NO;
	
    for(Unit *unit in _objectList) {
        
        float distance = [[(PlayerDataController*)playerData position] distanceToPosition: [unit position]];
        
        if(distance != INFINITY && distance <= unitDistance) {
            int lowLevel = range.location;
            if(lowLevel < 1) lowLevel = 1;
            if(lowLevel == 1 && ignoreLevelOne) lowLevel = 2;
            int highLevel = lowLevel + range.length;
            int unitLevel = [unit level];
            
            int faction = [unit factionTemplate];
            BOOL isFriendly = [playerData isFriendlyWithFaction: faction];
            BOOL isHostile = [playerData isHostileWithFaction: faction];
			BOOL isNeutral = (!isHostile && ![playerData isFriendlyWithFaction: faction]);
			
			//log(LOG_GENERAL, @"%d %d (%d || %d || %d) %d %d %d %d %@", [unit isValid], ![unit isDead], (friendly && isFriendly), (neutral && isNeutral), (hostile && isHostile), ((unitLevel >= lowLevel) && (unitLevel <= highLevel)), [unit isSelectable], 
			//        [unit isAttackable],  [unit isPVP], unit);
			
            // only include:
            if(   [unit isValid]                                                // 1) valid units
               && ![unit isDead]                                                // 2) units that aren't dead
               && ((friendly && isFriendly)                                     // 3) friendly as specified
                   || (neutral && isNeutral)                                                                    //    neutral as specified
                   || (hostile && isHostile))                                   //    hostile as specified
               && (unitLevel >= lowLevel) && unitLevel <= highLevel             // 4) units within the level range
               && [unit isSelectable]                                           // 5) units that are selectable
               && [unit isAttackable]/*                                           // 6) units that are attackable
									  && [unit isPVP]*/ ){                                                // 7) units that are PVP
										  //log(LOG_GENERAL, @"[PlayersController] Adding player %@", unit);
										  
										  [unitsWithinRange addObject: unit];
										  
									  }
        }
    }
	
	//log(LOG_GENERAL, @"[PlayersController] Found %d players", [unitsWithinRange count]);
    
    return unitsWithinRange;
}

- (BOOL)playerWithinRangeOfUnit: (float)distance Unit:(Unit*)unit includeFriendly:(BOOL)friendly includeHostile:(BOOL)hostile {
	
	log(LOG_DEV, @"checking distance %0.2f  %@ %d %d", distance, unit, friendly, hostile);
	Position *position = [unit position];
	
	// loop through all players
	for(Unit *player in [self allPlayers]) {
		
		BOOL isHostile = [playerData isHostileWithFaction: [player factionTemplate]];
		// range check
		float range = [position distanceToPosition: [player position]];
		
		if (
			range <= distance &&                                            // 1 - in range
			(!friendly || (friendly && !isHostile)) &&      // 2 - friendly
			(!hostile || (hostile && isHostile))            // 3 - hostile
			){
			log(LOG_GENERAL, @"[Loot] Player %@ found %0.2f yards away! I scared! Friendly?(%d)  Hostile?(%d)", player, range, friendly, hostile);
			return YES;
		}
	}
	
	return NO;
}

- (void)updateTracking: (id)sender{
	
    if ( ![playerData playerIsValid:self] ) return;
	
	BOOL trackHostile = [[NSUserDefaults standardUserDefaults] boolForKey: @"PlayersTrackHostile"];
	BOOL trackFriendly = [[NSUserDefaults standardUserDefaults] boolForKey: @"PlayersTrackFriendly"];
	
    // not sent from UI, so don't bother!
	if ( sender == nil && !trackHostile && !trackFriendly )
		return;
	
    for ( Unit *unit in _objectList ){
		
        BOOL shouldTrack = NO;
        
        if ( trackHostile && [playerData isHostileWithFaction: [unit factionTemplate]]) {
            shouldTrack = YES;
        }
        if ( trackFriendly && [playerData isFriendlyWithFaction: [unit factionTemplate]]) {
            shouldTrack = YES;
        }
        
        if ( shouldTrack )      [unit trackUnit];
        else                            [unit untrackUnit];
    }
}

#pragma mark -

- (id)objectWithAddress:(NSNumber*) address inMemory:(MemoryAccess*)memory{
	return [Player playerWithAddress:address inMemory:memory];
}

- (NSString*)updateFrequencyKey{
	return @"PlayersControllerUpdateFrequency";
}

- (void)refreshData {
	
	// remove old objects
	[_objectDataList removeAllObjects];
	
    if ( ![playerData playerIsValid:self] ) return;
	
	// is tab viewable?
	if ( ![objectsController isTabVisible:Tab_Players] )
		return;
	
	cachedPlayerLevel = [playerData level];
	
	for ( Player *player in _objectList ) {
		
		if( ![player isValid] )
			continue;
		
		float distance = [[playerData position] distanceToPosition: [player position]];
		
		BOOL isHostile = [playerData isHostileWithFaction: [player factionTemplate]];
		BOOL isNeutral = (!isHostile && ![playerData isFriendlyWithFaction: [player factionTemplate]]);
		
		unsigned level = [player level];
		if ( level > 100 ) level = 0;
		
		[_objectDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
									 player,                                                                @"Player",
									 [NSString stringWithFormat: @"0x%X", [player lowGUID]],                @"ID",
									 [self playerNameWithGUID:[player GUID]],                                                               @"Name",
									 ([player isGM] ? @"GM" : [Unit stringForClass: [player unitClass]]),   @"Class",
									 [Unit stringForRace: [player race]],                                   @"Race",
									 [Unit stringForGender: [player gender]],                               @"Gender",
									 [NSString stringWithFormat: @"%d%%", [player percentHealth]],          @"Health",
									 [NSNumber numberWithUnsignedInt: level],                               @"Level",
									 [NSNumber numberWithFloat: distance],                                  @"Distance", 
									 (isNeutral ? @"4" : (isHostile ? @"2" : @"5")),                        @"Status",
									 [player iconForRace: [player race] gender: [player gender]],           @"RaceIcon",
									 [NSImage imageNamed: [Unit stringForGender: [player gender]]],         @"GenderIcon",
									 [player iconForClass: [player unitClass]],                             @"ClassIcon",
									 nil]];
	}
	
	// sort
	[_objectDataList sortUsingDescriptors: [[objectsController playersTable] sortDescriptors]];
	
	// reload table
	[objectsController loadTabData];
}

- (WoWObject*)objectForRowIndex:(int)rowIndex{
	if ( rowIndex >= [_objectDataList count] ) return nil;
	return [[_objectDataList objectAtIndex: rowIndex] objectForKey: @"Player"];
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if ( rowIndex == -1 || rowIndex >= [_objectDataList count] ) return nil;
    
    if ( [[aTableColumn identifier] isEqualToString: @"Distance"] )
        return [NSString stringWithFormat: @"%.2f", [[[_objectDataList objectAtIndex: rowIndex] objectForKey: @"Distance"] floatValue]];
    
    if ( [[aTableColumn identifier] isEqualToString: @"Status"] ) {
        NSString *status = [[_objectDataList objectAtIndex: rowIndex] objectForKey: @"Status"];
        if([status isEqualToString: @"1"])  status = @"Combat";
        if([status isEqualToString: @"2"])  status = @"Hostile";
        if([status isEqualToString: @"3"])  status = @"Dead";
        if([status isEqualToString: @"4"])  status = @"Neutral";
        if([status isEqualToString: @"5"])  status = @"Friendly";
        return [NSImage imageNamed: status];
    }
    
    return [[_objectDataList objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex
{
    if ( aRowIndex == -1 || aRowIndex >= [_objectDataList count] ) return;
    
    if ( [[aTableColumn identifier] isEqualToString: @"Race"] ){
        [(ImageAndTextCell*)aCell setImage: [[_objectDataList objectAtIndex: aRowIndex] objectForKey: @"RaceIcon"]];
    }
    if ( [[aTableColumn identifier] isEqualToString: @"Class"] ){
        [(ImageAndTextCell*)aCell setImage: [[_objectDataList objectAtIndex: aRowIndex] objectForKey: @"ClassIcon"]];
    }
    if ( [[aTableColumn identifier] isEqualToString: @"Gender"] ){
        [(ImageAndTextCell*)aCell setImage: [[_objectDataList objectAtIndex: aRowIndex] objectForKey: @"GenderIcon"]];
    }
    
    // do text color
    if ( ![aCell respondsToSelector: @selector(setTextColor:)] )
        return;
    
    if ( cachedPlayerLevel == 0 || ![[NSUserDefaults standardUserDefaults] boolForKey: @"PlayerColorByLevel"] ){
        [aCell setTextColor: [NSColor blackColor]];
        return;
    }
    
    Player *player = [[_objectDataList objectAtIndex: aRowIndex] objectForKey: @"Player"];
    int level = [player level];
    
    if ( level >= cachedPlayerLevel+5 ){
        [aCell setTextColor: [NSColor redColor]];
        return;
    }
    
    if ( level > cachedPlayerLevel+3 ){
        [aCell setTextColor: [NSColor orangeColor]];
        return;
    }
    
    if ( level > cachedPlayerLevel-2 ){
        [aCell setTextColor: [NSColor colorWithCalibratedRed: 1.0 green: 200.0/255.0 blue: 30.0/255.0 alpha: 1.0]];
        return;
    }
    
    if ( level > cachedPlayerLevel-8 ){
        [aCell setTextColor: [NSColor colorWithCalibratedRed: 30.0/255.0 green: 115.0/255.0 blue: 30.0/255.0 alpha: 1.0] ]; // [NSColor greenColor]
        return;
    }
    
    [aCell setTextColor: [NSColor darkGrayColor]];
    return;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
    
	if ( [[aTableColumn identifier] isEqualToString: @"RaceIcon"] )
        return NO;
    if ( [[aTableColumn identifier] isEqualToString: @"ClassIcon"] )
        return NO;
	
    return YES;
}

- (void)tableDoubleClick: (id)sender{
	[memoryViewController showObjectMemory: [[_objectDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Player"]];
	[controller showMemoryView];
}

@end
