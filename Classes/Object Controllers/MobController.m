//
//  MobController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/17/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//
#import <ScreenSaver/ScreenSaver.h>

#import "MobController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "MemoryViewController.h"
#import "CombatController.h"
#import "MovementController.h"
#import "AuraController.h"
#import "BotController.h"
#import "SpellController.h"
#import "ObjectsController.h"

#import "MemoryAccess.h"
#import "CombatProfile.h"

#import "Mob.h"
#import "Waypoint.h"
#import "Position.h"
#import "Offsets.h"

#import "ImageAndTextCell.h"

@interface MobController (Internal)
- (BOOL)trackingMob: (Mob*)mob;
@end

@implementation MobController

+ (void)InitializeDataBrowserCallbacks {
}

static MobController* sharedController = nil;

+ (MobController *)sharedController {
	if (sharedController == nil)
		sharedController = [[[self class] alloc] init];
	return sharedController;
}

- (id) init {
    self = [super init];
	if(sharedController) {
		[self release];
		self = sharedController;
	} else if (self != nil) {
        sharedController = self;

        [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObject: @"0.25" forKey: @"MobControllerUpdateFrequency"]];
        cachedPlayerLevel = 0;
    }
    return self;
}

- (void)dealloc{
	[_objectList release];
	[_objectDataList release];

	[super dealloc];
}

#pragma mark Accessors

- (NSImage*)toolbarIcon {
    NSImage *original = [NSImage imageNamed: @"INV_Misc_Head_Dragon_Bronze"];
    NSImage *newImage = [original copy];
    
    NSDictionary *attributes = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Helvetica-Bold" size: 18], NSFontAttributeName,
                                 [NSColor whiteColor], NSForegroundColorAttributeName, nil] autorelease];
    
    NSString *count = [NSString stringWithFormat: @"%d", [_objectList count]];
    NSSize numSize = [count sizeWithAttributes:attributes];
    NSSize iconSize = [original size];
    
    if ([_objectList count]) {
        
        [newImage lockFocus];
        float max = ((numSize.width > numSize.height) ? numSize.width : numSize.height) + 8.0f;
        
        NSRect circleRect = NSMakeRect(iconSize.width - max, 0, max, max); // iconSize.width - max, iconSize.height - max
        NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:circleRect];
        [[NSColor colorWithCalibratedRed:0.8f green:0.0f blue:0.0f alpha:1.0f] set];
        [bp fill];
        [count drawAtPoint: NSMakePoint(NSMidX(circleRect) - numSize.width / 2.0f, NSMidY(circleRect) - numSize.height / 2.0f + 2.0f) 
                withAttributes: attributes];
        
        [newImage unlockFocus];
    }

    return [newImage autorelease];
}

#pragma mark -
// deselect all mobs
- (void)clearTargets{
	// deselect all
	for(Mob *mob in _objectList) {
		[mob deselect];
	}
}

/*
// old-style manual totem detection
- (BOOL)mobIsOurTotem: (Mob*)mob {
    UInt64 createdByGUID  = [mob createdBy];
    UInt32 createdBySpell = [mob createdBySpell];
    
    if( ([mob unitBytes2] == 0x2801) && (createdBySpell != 0) && (createdByGUID != 0) && ([mob petNumber] == 0) && ([mob petNameTimestamp] == 0)) {
        Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: createdBySpell]];
        if( [spellController isPlayerSpell: spell] && ([playerData GUID] == createdByGUID)) {
            return YES;
        }
    }
    return NO;
}*/

- (Mob*)playerTarget {
    GUID playerTarget = [playerData targetID];
    
    for(Mob *mob in _objectList) {
        if( playerTarget == [mob GUID]) {
            return mob;
        }
    }
    return nil;
}

- (Mob*)mobWithEntryID: (int)entryID {
    for(Mob *mob in _objectList) {
        if( entryID == [mob entryID]) {
            return [[mob retain] autorelease];
        }
    }
    return nil;
}

- (NSArray*)mobsWithEntryID: (int)entryID {

	NSMutableArray *mobs = [NSMutableArray array];
    for(Mob *mob in _objectList) {
		
		if( entryID == [mob entryID]) {
			[mobs addObject: mob];
		}
	}
	
    return mobs;
}

- (Mob*)mobWithGUID: (GUID)guid {
    for(Mob *mob in _objectList) {
        if( guid == [mob GUID]) {
            return [[mob retain] autorelease];
        }
    }
    return nil;
}

- (unsigned)mobCount {
    return [_objectList count];
}

- (unsigned int)objectCount {
	return [_objectList count];	
}

- (NSArray*)allObjects{
	return [[_objectList retain] autorelease];
}

- (NSArray*)allMobs {
    return [[_objectList retain] autorelease];
}

- (void)addAddresses: (NSArray*)addresses {
	[super addAddresses: addresses];

    [self updateTracking: nil];
}

#pragma mark -

- (NSArray*)mobsWithinDistance: (float)mobDistance MobIDs: (NSArray*)mobIDs position:(Position*)position aliveOnly:(BOOL)aliveOnly{
	
	NSMutableArray *withinRangeMobs = [NSMutableArray array];
	BOOL tapCheckPassed = YES;
    for(Mob *mob in _objectList) {
		tapCheckPassed = YES;
		// Just return nearby mobs
		if ( mobIDs == nil ){
			float distance = [position distanceToPosition: [mob position]];
			if((distance != INFINITY) && (distance <= mobDistance)) {
//				log(LOG_DEV, @"Mob %@ is %0.2f away", mob, distance);
				
				// Living check?
				if ( !aliveOnly || (aliveOnly && ![mob isDead]) ){
					[withinRangeMobs addObject: mob];
				}
			}
		}
		else{
			for ( NSNumber *entryID in mobIDs ) {
				if ( [mob entryID] == [entryID intValue] ){
					float distance = [position distanceToPosition: [mob position]];
					if((distance != INFINITY) && (distance <= mobDistance)) {
						if ( [mob isTappedByOther] && !botController.theCombatProfile.partyEnabled && !botController.pvpIsInBG ) tapCheckPassed = NO;

						// Living check?
						if ( !aliveOnly || (aliveOnly && ![mob isDead]) ) {
							if (tapCheckPassed) {
								[withinRangeMobs addObject: mob];
							} else {
								log(LOG_DEV, @"Mob %@ is tapped by another player, not adding it to my mob list!", mob, distance);
							}
						}
					}
				}
			}
		}
	}
	
	return withinRangeMobs;
}


- (NSArray*)mobsWithinDistance: (float)mobDistance
                    levelRange: (NSRange)range
                  includeElite: (BOOL)includeElite
               includeFriendly: (BOOL)friendly
                includeNeutral: (BOOL)neutral
                includeHostile: (BOOL)hostile {
    
    NSMutableArray *withinRangeMobs = [NSMutableArray array];
    
	BOOL tapCheckPassed;
    BOOL ignoreLevelOne = ([playerData level] > 10) ? YES : NO;
    Position *playerPosition = [(PlayerDataController*)playerData position];
	
	//log(LOG_GENERAL, @"[Mob] Total mobs: %d", [_objectList count]);
    
    for(Mob *mob in _objectList) {
        
        if ( !includeElite && [mob isElite] ){
			log(LOG_DEV, @"Ignoring elite %@", mob);
            continue;   // ignore elite if specified
		}
		
		// ignore units that don't meet the combat profile
		if ( [botController.theCombatProfile unitShouldBeIgnored: mob] ){
			continue;
		}
		
		// ignore pets?
		if ( ![botController.theCombatProfile attackPets] && [mob isPet] ){
			continue;
		}
        
		tapCheckPassed = YES;
		if ( [mob isTappedByOther] && !botController.theCombatProfile.partyEnabled && !botController.pvpIsInBG ) tapCheckPassed = NO;
		
        float distance = [playerPosition distanceToPosition: [mob position]];
                
        if((distance != INFINITY) && (distance <= mobDistance)) {
            int lowLevel = range.location;
            if(lowLevel < 1) lowLevel = 1;
            if(lowLevel == 1 && ignoreLevelOne) lowLevel = 2;
            int highLevel = lowLevel + range.length;
            int mobLevel = [mob level];
            
            int faction = [mob factionTemplate];
            BOOL isFriendly = [playerData isFriendlyWithFaction: faction];
            BOOL isHostile = [playerData isHostileWithFaction: faction];
			BOOL isNeutral = (!isHostile && ![playerData isFriendlyWithFaction: faction]);
			
			//log(LOG_GENERAL, @"%d %d (%d || %d || %d) %d %d %d %d %@", [mob isValid], ![mob isDead], (friendly && isFriendly), (neutral && isNeutral), (hostile && isHostile), ((mobLevel >= lowLevel) && (mobLevel <= highLevel)), [mob isSelectable], 
			//	  [mob isAttackable],   ![mob isTappedByOther], mob);
			
            // only include:
            if(   [mob isValid]                                             // 1) valid mobs
               && ![mob isDead]                                             // 2) mobs that aren't dead
               && ((friendly && isFriendly)                                 // 3) friendly as specified
                   || (neutral && isNeutral)								//    neutral as specified
                   || (hostile && isHostile) )                              //    hostile as specified
               && ((mobLevel >= lowLevel) && (mobLevel <= highLevel))       // 4) mobs within the level range
               //&& ![mob isPet]											// 5) mobs that are not player pets
               && [mob isSelectable]                                        // 6) mobs that are selectable
               && [mob isAttackable]                                        // 7) mobs that are attackable
               && tapCheckPassed )											// 8) mobs that are not tapped by someone else
                [withinRangeMobs addObject: mob];
        }
    }
	
	//log(LOG_GENERAL, @"[MobController] Found %d mobs", [withinRangeMobs count]);
    
    return withinRangeMobs;
}

- (Mob*)closestMobForInteraction:(UInt32)entryID {
    
    Position *playerPosition = [(PlayerDataController*)playerData position];
    
    for(Mob *mob in _objectList) {
        float distance = [playerPosition distanceToPosition: [mob position]];
		
        if((distance != INFINITY) && (distance <= 9)) {
            //int faction = [mob factionTemplate];
            // only include: valid mobs, mobs that aren't dead, friendly, selectable mobs
            if( [mob isValid] && [mob entryID] == entryID && ![mob isDead] && ![mob isPet] )
                return mob;
        }
    }
	
    log(LOG_GENERAL, @"[Mob] No mob for interaction");
    return nil;
}

#pragma mark ObjectsController helpers

- (NSArray*)uniqueMobsAlphabetized{
	
	NSMutableArray *addedMobNames = [NSMutableArray array];
	
	for ( Mob *mob in _objectList ){
		if ( ![addedMobNames containsObject:[mob name]] ){
			[addedMobNames addObject:[mob name]];
		}
	}
	
	[addedMobNames sortUsingSelector:@selector(compare:)];
	
	return [[addedMobNames retain] autorelease];
}

- (Mob*)closestMobWithName:(NSString*)mobName{
	
	NSMutableArray *mobsWithName = [NSMutableArray array];
	
	// find mobs with the name!
	for ( Mob *mob in _objectList ){
		if ( [mobName isEqualToString:[mob name]] ){
			[mobsWithName addObject:mob];
		}
	}
	
	if ( [mobsWithName count] == 1 ){
		return [mobsWithName objectAtIndex:0];
	}
	
	Position *playerPosition = [playerData position];
	Mob *closestMob = nil;
	float closestDistance = INFINITY;
	for ( Mob *mob in mobsWithName ){
		
		float distance = [playerPosition distanceToPosition:[mob position]];
		if ( distance < closestDistance ){
			closestDistance = distance;
			closestMob = mob;
		}
	}
	
	return closestMob;	
}

#pragma mark -

- (void)doCombatScan {
	BOOL doNearbyScan = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnNearbyMob"] boolValue];
	int nearbyEntryID = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnNearbyMobID"] intValue];

    // check to see if we're in combat

	if ( doNearbyScan ){
		for(Mob *mob in _objectList) {
			if ( [mob entryID] == nearbyEntryID && ![mob isDead] ){
				[[NSSound soundNamed: @"alarm"] play];
				log(LOG_GENERAL, @"[Combat] Found %d nearby! Playing alarm!", nearbyEntryID);
			}
		}
	}
		
}

- (BOOL)trackingMob: (Mob*)trackingMob {
    for(Mob *mob in _objectList) {
        if( [mob isEqualToObject: trackingMob] )
            return YES;
    }
    return NO;
}

- (IBAction)updateTracking: (id)sender {
    if(![playerData playerIsValid:self]) return;
    
    if(sender && ![sender isKindOfClass: [self class]]) {
        // the stupid popup doesn't update the state of the menu items OR BINDINGS until after it fires off its selector.
        // so if this call is coming from the UI, just delay for a tiny bit and try again.
        [self performSelector: _cmd withObject: self afterDelay: 0.1];
        return;
    }
    
    BOOL trackFriendly = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobTrackFriendly"];
    BOOL trackNeutral = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobTrackNeutral"];
    BOOL trackHostile = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobTrackHostile"];
    
    if(!sender && !trackFriendly && !trackNeutral && !trackHostile) {
        // there's nothing to update
        return;
    }
    
    for(Mob *mob in _objectList) {
        BOOL isHostile = [playerData isHostileWithFaction: [mob factionTemplate]];
        BOOL isFriendly = [playerData isFriendlyWithFaction: [mob factionTemplate]];
        BOOL isNeutral = (!isHostile && !isFriendly);
        BOOL shouldTrack = NO;
        
        if( trackHostile && isHostile) {
            shouldTrack = YES;
        }
        if( trackNeutral && isNeutral) {
            shouldTrack = YES;
        }
        if( trackFriendly && isFriendly) {
            shouldTrack = YES;
        }
        
        if(shouldTrack) [mob trackUnit];
        else            [mob untrackUnit];
    }
}

#pragma mark - Implementing functions from teh super class!

- (id)objectWithAddress:(NSNumber*) address inMemory:(MemoryAccess*)memory{
	return [Mob mobWithAddress:address inMemory:memory];
}

- (NSString*)updateFrequencyKey{
	return @"MobControllerUpdateFrequency";
}

- (unsigned int)objectCountWithFilters{
	BOOL hideNonSeletable = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobHideNonSelectable"];
	BOOL hidePets = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobHidePets"];
	BOOL hideCritters = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobHideCritters"];
	
	if ( [_objectDataList count] || ( hideNonSeletable || hidePets || hideCritters ) )
		return [_objectDataList count];
	
	return [_objectList count];
}

// update our object data list!
- (void)refreshData {
	
	// remove old objects
	[_objectDataList removeAllObjects];
	
	// is player valid?
	if ( ![playerData playerIsValid:self] ) return;
	
	// search for nearby mobs (for alarm!)
	[self doCombatScan];
	
	// is tab viewable?
	if ( ![objectsController isTabVisible:Tab_Mobs] )
		return;
	
    cachedPlayerLevel = [playerData level];
    
	unsigned level, health;
	Position *playerPosition = [(PlayerDataController*)playerData position];
	NSString *filterString = [objectsController nameFilter];
	for ( Mob *mob in _objectList ) {
		
		if ( ![mob isValid] )
			continue;
		
		if ( filterString ) {
			if( [[mob name] rangeOfString: filterString options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location == NSNotFound) {
				continue;
			}
		}
		
		BOOL hideNonSeletable = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobHideNonSelectable"];
		BOOL hidePets = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobHidePets"];
		BOOL hideCritters = [[NSUserDefaults standardUserDefaults] boolForKey: @"MobHideCritters"];
		
		// hide invisible mobs from the list
		if ( hideNonSeletable && ![mob isSelectable] )
			continue;
		
		int faction = [mob factionTemplate];
		level = [mob level];
		BOOL critter = ([controller reactMaskForFaction: faction] == 0) && (level == 1);
		
		// skip critters if necessary
		if( hideCritters && critter)
			continue;
		
		NSString *name = nil;
		
		// check to see if it's a pet
		if ( [mob isPet] ) {
			if ( hidePets ) continue;
			if ( [mob isTotem] ){
				name = [mob name];
				name = [@"[Totem] " stringByAppendingString: name];
			}
			else{
				name = [mob name];
				name = [@"[Pet] " stringByAppendingString: name];
			}
		}
		
		health = [mob currentHealth];
		
		
		if ( !name )
			name = [mob name];

		BOOL isDead = [mob isDead];
		BOOL isCombat = [mob isInCombat];
				BOOL isHostile = [playerData isHostileWithFaction: faction];
		BOOL isNeutral = (!isHostile && ![playerData isFriendlyWithFaction: faction]);
		BOOL allianceFriendly = ([controller reactMaskForFaction: faction] & 0x2);
		BOOL hordeFriendly = ([controller reactMaskForFaction: faction] & 0x4);
		BOOL bothFriendly = hordeFriendly && allianceFriendly;
		allianceFriendly = allianceFriendly && !bothFriendly;
		hordeFriendly = hordeFriendly && !bothFriendly;
		
		float distance = [playerPosition distanceToPosition: [mob position]];
		
		NSImage *nameIcon = nil;
		if( !nameIcon && (level == PLAYER_LEVEL_CAP+3) && [mob isElite])
			nameIcon = [NSImage imageNamed: @"Skull"];
		
		if( !nameIcon && [mob isAuctioneer])    nameIcon = [NSImage imageNamed: @"BankerGossipIcon"];
		if( !nameIcon && [mob isStableMaster])  nameIcon = [NSImage imageNamed: @"Stable"];
		if( !nameIcon && [mob isBanker])        nameIcon = [NSImage imageNamed: @"BankerGossipIcon"];
		if( !nameIcon && [mob isInnkeeper])     nameIcon = [NSImage imageNamed: @"Innkeeper"];
		if( !nameIcon && [mob isFlightMaster])  nameIcon = [NSImage imageNamed: @"TaxiGossipIcon"];
		if( !nameIcon && [mob canRepair])       nameIcon = [NSImage imageNamed: @"Repair"];
		if( !nameIcon && [mob isVendor])        nameIcon = [NSImage imageNamed: @"VendorGossipIcon"];
		if( !nameIcon && [mob isTrainer])       nameIcon = [NSImage imageNamed: @"TrainerGossipIcon"];
		if( !nameIcon && [mob isQuestGiver])    nameIcon = [NSImage imageNamed: @"ActiveQuestIcon"];
		if( !nameIcon && [mob canGossip])       nameIcon = [NSImage imageNamed: @"GossipGossipIcon"];
		if( !nameIcon && allianceFriendly)      nameIcon = [NSImage imageNamed: @"AllianceCrest"];
		if( !nameIcon && hordeFriendly)         nameIcon = [NSImage imageNamed: @"HordeCrest"];
		if( !nameIcon && critter)               nameIcon = [NSImage imageNamed: @"Chicken"];
		if( !nameIcon)                          nameIcon = [NSImage imageNamed: @"NeutralCrest"];
		
		
		[_objectDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
								  mob,                                                      @"Mob",
								  name,                                                     @"Name",
								  [NSNumber numberWithInt: [mob entryID]],                  @"ID",
								  [NSNumber numberWithInt: health],                         @"Health",
								  [NSNumber numberWithUnsignedInt: level],                  @"Level",
								  [NSString stringWithFormat: @"0x%X", [mob baseAddress]],  @"Address",
								  [NSNumber numberWithFloat: distance],                     @"Distance", 
								  [mob isPet] ? @"Yes" : @"No",                             @"Pet",
								  // isHostile ? @"Yes" : @"No",                           @"Hostile",
								  // isCombat ? @"Yes" : @"No",                            @"Combat",
								  (isDead ? @"3" : (isCombat ? @"1" : (isNeutral ? @"4" : (isHostile ? @"2" : @"5")))),  @"Status",
								  nameIcon,                                                 @"NameIcon", 
								  nil]];
        
	}
	
	// sort
	[_objectDataList sortUsingDescriptors: [[objectsController mobTable] sortDescriptors]];
	
	// reload table
	[objectsController loadTabData];
}

- (WoWObject*)objectForRowIndex:(int)rowIndex{
	if ( rowIndex >= [_objectDataList count] ) return nil;
	return [[_objectDataList objectAtIndex: rowIndex] objectForKey: @"Mob"];
}

#pragma mark -
#pragma mark TableView Delegate & Datasource (called from objectsController, NOT from the UI)

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

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex{
    
	if ( aRowIndex == -1 || aRowIndex >= [_objectDataList count] ) return;

	if ( [[aTableColumn identifier] isEqualToString: @"Name"] ) {
		[(ImageAndTextCell*)aCell setImage: [[_objectDataList objectAtIndex: aRowIndex] objectForKey: @"NameIcon"]];
	}
	
	if ( ![aCell respondsToSelector: @selector(setTextColor:)] )
		return;
	
	if ( cachedPlayerLevel == 0 || ![[NSUserDefaults standardUserDefaults] boolForKey: @"MobColorByLevel"] ) {
		[aCell setTextColor: [NSColor blackColor]];
		return;
	}
	
	Mob *mob = [[_objectDataList objectAtIndex: aRowIndex] objectForKey: @"Mob"];
	int mobLevel = [mob level];
	
	if ( mobLevel >= cachedPlayerLevel+5 ){
		[aCell setTextColor: [NSColor redColor]];
		return;
	}
	
	if ( mobLevel > cachedPlayerLevel+3 ){
		[aCell setTextColor: [NSColor orangeColor]];
		return;
	}
	
	if ( mobLevel > cachedPlayerLevel-2 ){
		[aCell setTextColor: [NSColor colorWithCalibratedRed: 1.0 green: 200.0/255.0 blue: 30.0/255.0 alpha: 1.0]];
		return;
	}
	
	if ( mobLevel > cachedPlayerLevel-8 ){
		[aCell setTextColor: [NSColor colorWithCalibratedRed: 30.0/255.0 green: 115.0/255.0 blue: 30.0/255.0 alpha: 1.0] ]; // [NSColor greenColor]
		return;
	}
	
	[aCell setTextColor: [NSColor darkGrayColor]];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn{
    
	if ( [[aTableColumn identifier] isEqualToString: @"Pet"] ){
		return NO;
	}
	if ( [[aTableColumn identifier] isEqualToString: @"Hostile"] ){
		return NO;
	}
	if ( [[aTableColumn identifier] isEqualToString: @"Combat"] ){
		return NO;
	}
	
    return YES;
}

- (void)tableDoubleClick: (id)sender{
	[memoryViewController showObjectMemory: [[_objectDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Mob"]];
	[controller showMemoryView];
}

@end
