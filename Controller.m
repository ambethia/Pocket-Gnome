//
//  Controller.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/15/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//
//

#import "Controller.h"
#import "NoAccessApplication.h"
#import "BotController.h"
#import "MobController.h"
#import "NodeController.h"
#import "SpellController.h"
#import "InventoryController.h"
#import "WaypointController.h"
#import "ProcedureController.h"
#import "PlayerDataController.h"
#import "MemoryViewController.h"
#import "PlayersController.h"
#import "CorpseController.h"
#import "OffsetController.h"
#import "StatisticsController.h"
#import "ObjectsController.h"
#import "PvPController.h"
#import "ProfileController.h"

#import "CGSPrivate.h"

#import "MemoryAccess.h"
#import "Offsets.h"
#import "NSNumberToHexString.h"
#import "NSString+URLEncode.h"
#import "NSString+Extras.h"
#import "Mob.h"
#import "Item.h"
#import "Node.h"
#import "Player.h"
#import "PTHeader.h"
#import "Position.h"

#import <Sparkle/Sparkle.h>

#import <Foundation/foundation.h>
#import <SecurityFoundation/SFAuthorization.h>
#import <Security/AuthorizationTags.h>

typedef enum {
    wowNotOpenState =       0,
    memoryInvalidState =    1,
    memoryValidState =      2,
    playerValidState =      3,
} memoryState;

#define MainWindowMinWidth  740
#define MainWindowMinHeight 200

@interface Controller ()
@property int currentState;
@property (readwrite, retain) NSString* matchExistingApp;
@end

@interface Controller (Internal)
- (void)finalizeUserDefaults;

- (void)scanObjectGraph;
- (BOOL)locatePlayerStructure;
- (void)loadView: (NSView*)newView withTitle: (NSString*)title;
- (void)populateWowInstances;
- (void)foundObjectListAddress: (NSNumber*)address;

// new structure scanning
- (BOOL)isValidAddress: (UInt32)address;
- (UInt32)getNextObjectAddress:(MemoryAccess*)memory;
- (void)sortObjects: (MemoryAccess*)memory;
@end

@implementation Controller

+ (void)initialize {
	
	// fix for saving the mount dropdown
	id mountObject = [[NSUserDefaults standardUserDefaults] objectForKey: @"MountType"];
	if ( [mountObject isKindOfClass:[NSString class]] ){
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"MountType"];
		 [[NSUserDefaults standardUserDefaults] synchronize];
	}
	
    // initialize our value transformer
    NSNumberToHexString *hexTransformer = [[[NSNumberToHexString alloc] init] autorelease];
    [NSValueTransformer setValueTransformer: hexTransformer forName: @"NSNumberToHexString"];
    
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 7.0],     @"BlacklistTriggerNotInCombat",
                                   [NSNumber numberWithFloat: 45.0],    @"BlacklistDurationNotInCombat",
                                   [NSNumber numberWithFloat: 20.0],    @"BlacklistDurationNotInLos",
                                   [NSNumber numberWithFloat: 10.0],    @"BlacklistVerticalOffset",
								   [NSNumber numberWithInt: 3],			@"BlacklistTriggerNodeFailedToReach",
                                   [NSNumber numberWithInt: 4],			@"BlacklistTriggerNodeFailedToLoot",
                                   [NSNumber numberWithInt: 2],			@"BlacklistTriggerNodeMadeMeFall",
                                   [NSNumber numberWithBool: YES],      @"MovementUseSmoothTurning",
                                   [NSNumber numberWithFloat: 2.0],     @"MovementMinJumpTime",
                                   [NSNumber numberWithFloat: 6.0],     @"MovementMaxJumpTime",
                                   [NSNumber numberWithBool: YES],      @"GlobalSendGrowlNotifications",
                                   [NSNumber numberWithBool: YES],      @"SUCheckAtStartup",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingEnable",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingDev",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingEvaluate",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingBindings",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingMacro",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingMovement",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingWaypoint",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingCondition",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingRule",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingBlacklist",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingStatistics",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingFunction",
								   [NSNumber numberWithBool: NO],       @"ExtendedLoggingMemory",
								   [NSNumber numberWithInt: 1],			@"MountType",
                                   nil];
	[[NSUserDefaults standardUserDefaults] setObject: @"http://pg.savorydeviate.com/appcast.xml" forKey: @"SUFeedURL"];
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"SUFeedURL"];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
	
	// allow GUI scripting
	[NSApp setAllowAccessibility: YES];
}

static Controller* sharedController = nil;

+ (Controller *)sharedController {
	if (sharedController == nil)
		sharedController = [[[self class] alloc] init];
	return sharedController;
}

- (id) init {
    self = [super init];
	if(sharedController) {
		[self release];
		self = sharedController;
	} else if(self != nil) {
		
        sharedController = self;
        _items = [[NSMutableArray array] retain];
        _mobs = [[NSMutableArray array] retain];
        _players = [[NSMutableArray array] retain];
        _corpses = [[NSMutableArray array] retain];
        _gameObjects = [[NSMutableArray array] retain];
        _dynamicObjects = [[NSMutableArray array] retain];

        _wowMemoryAccess = nil;
        _appFinishedLaunching = NO;
		_invalidPlayerNotificationSent = NO;
		
		_lastAttachedPID = 0;
		_selectedPID = 0;
		_globalGUID = 0;
		
		// new search
		_objectAddresses = [[NSMutableArray array] retain];		// stores the start address for all objects
		_objectGUIDs = [[NSMutableArray array] retain];
		_currentAddress = 0;
		_totalObjects = 0;
		_currentObjectManager = 0;
        
        // load in our faction dictionary
        factionTemplate = [[NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"FactionTemplate" ofType: @"plist"]] retain];
		
		// start our name list update timer!
		_updateNameListTimer = [NSTimer scheduledTimerWithTimeInterval: 30.0f target: self selector: @selector(updateNameList:) userInfo: nil repeats: YES];
		_nameListAddresses = [[NSMutableDictionary dictionary] retain];
	}
    
    return self;
}

- (void)dealloc {
	[_items release];
	[_mobs release];
	[_players release];
	[_corpses release];
	[_gameObjects release];
	[_dynamicObjects release];
	[_nameListAddresses release];
	[_objectAddresses release];
	[_objectGUIDs release];
	[factionTemplate release];
	[currentStatusText release];
	[_wowMemoryAccess release];

	[super dealloc];
}

- (void)checkWoWVersion {
    
    NSString *appVers = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"];
    
    if([self isWoWVersionValid]) {
        [aboutValidImage setImage: [NSImage imageNamed: @"good"]];
	[versionInfoText setStringValue: [NSString stringWithFormat: @"%@ v%@ is up to date with WoW %@.", [self appName], appVers, [self wowVersionShort]]];
    } else {
        [aboutValidImage setImage: [NSImage imageNamed: @"bad"]];
	[versionInfoText setStringValue: [NSString stringWithFormat: @"%@ v%@ may require WoW %@. Check the site below for more details.", [self appName], appVers, VALID_WOW_VERSION]];
    }
}

- (void)awakeFromNib {
    // [mainWindow setBackgroundColor: [NSColor windowFrameColor]];
    
    [self showAbout: nil];
    [self checkWoWVersion];
    
    [GrowlApplicationBridge setGrowlDelegate: self];
    [GrowlApplicationBridge setWillRegisterWhenGrowlIsReady: YES];
    /*if( [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
        log(LOG_CONTROLLER, @"Growl running.");
        [GrowlApplicationBridge notifyWithTitle: @"RUNNING"
                                    description: [NSString stringWithFormat: @"You have reached level %d.", 1]
                               notificationName: @"PlayerLevelUp"
                                       iconData: [[NSImage imageNamed: @"Ability_Warrior_Revenge"] TIFFRepresentation]
                                       priority: 0
                                       isSticky: NO
                                   clickContext: nil];             
    } else {
        log(LOG_CONTROLLER, @"Growl not running.");
    }*/
	
}

- (void)finalizeUserDefaults {
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"SUFeedURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // no more license checking; clean up old registration
    self.isRegistered = YES;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings removeObjectForKey: @"LicenseData"];
    [settings removeObjectForKey: @"LicenseName"];
    [settings removeObjectForKey: @"LicenseEmail"];
    [settings removeObjectForKey: @"LicenseHash"];
    [settings removeObjectForKey: @"LicenseID"];
	[settings removeObjectForKey: @"SecurityDisableGUIScripting"];
	[settings removeObjectForKey: @"SecurityDisableLogging"];
	[settings removeObjectForKey: @"SecurityPreferencesUnreadable"];
	[settings removeObjectForKey: @"SecurityUseBlankWindowTitles"];
	[settings removeObjectForKey: @"SecurityShowRenameSettings"];
    [settings synchronize];
    
    // make us the front process
	if ( ![self isWoWFront] ){
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		SetFrontProcess( &psn );
		[mainWindow makeKeyAndOrderFront: nil];
	}
    _appFinishedLaunching = YES;
	
	// check for update?
	//[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
    
    // validate game version
    //if(![self isWoWVersionValid]) {
    //    NSRunCriticalAlertPanel(@"No valid version of WoW detected!", @"You have version %@ of WoW installed, and this program requires version %@.  There is no gaurantee that this program will work with your version of World of Warcraft.  Please check for an updated version.", @"Okay", nil, nil, [self wowVersionShort], VALID_WOW_VERSION);
    //}
    
    [self performSelector: @selector(scanObjectGraph) withObject: nil afterDelay: 0.5];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self finalizeUserDefaults];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    if(![mainWindow isVisible]) {
        [mainWindow makeKeyAndOrderFront: nil];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    if(!flag) {
        [mainWindow makeKeyAndOrderFront: nil];
    }
    return NO;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    
    if ( [[filename pathExtension] isEqualToString: @"route"] || [[filename pathExtension] isEqualToString: @"routeset"] || [[filename pathExtension] isEqualToString: @"routecollection"] ) {
        [routeController importRouteAtPath: filename];
        [self toolbarItemSelected: routesToolbarItem];
        [mainToolbar setSelectedItemIdentifier: [routesToolbarItem itemIdentifier]];
        return YES;
    }
	else if ( [[filename pathExtension] isEqualToString: @"behavior"] || [[filename pathExtension] isEqualToString: @"behaviorset"] ) {
        [behaviorController importBehaviorAtPath: filename];
        [self toolbarItemSelected: behavsToolbarItem];
        [mainToolbar setSelectedItemIdentifier: [behavsToolbarItem itemIdentifier]];
        return YES;
    }
	else if ( [[filename pathExtension] isEqualToString: @"pvpbehavior"] ) {
        [pvpController importBehaviorAtPath: filename];
        [self toolbarItemSelected: pvpToolbarItem];
        [mainToolbar setSelectedItemIdentifier: [pvpToolbarItem itemIdentifier]];
        return YES;
    }
	// mail action profile or combat profile
	else if ( [[filename pathExtension] isEqualToString: @"mailprofile"] || [[filename pathExtension] isEqualToString: @"combatprofile"] || [[filename pathExtension] isEqualToString: @"combatProfile"] ) {
	        [self toolbarItemSelected: profilesToolbarItem];
	        [mainToolbar setSelectedItemIdentifier: [profilesToolbarItem itemIdentifier]];
			[profileController importProfileAtPath: filename];
	        return YES;
    }
    
    return NO;
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response { return; }

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data { return; }

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // log(LOG_CONTROLLER, @"Registration connection error.");
    [connection autorelease];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // log(LOG_CONTROLLER, @"Registration connection done.");
    [connection autorelease];
}

#pragma mark Name List Scanning

typedef struct NameListStruct{
	UInt32 four;
	UInt32 nextPtr;
	UInt32 prevPtr;
} NameListStruct;

// next + prev could be swapped, not sure, but pointers nonetheless
typedef struct NameObjectStruct{
	UInt32 guidLow;
	UInt32 addr;
	UInt32 unk;
	UInt32 nextPtr;			// 0xC			need to subtract 0xC to get to the start
	UInt32 prevPtr;			// 0x10			no change req'd
	UInt64 guid;
	char   name[16];		// max length is 12 chars
} NameObjectStruct;

- (void)updateNameList: (NSTimer*)timer{
	[self traverseNameList];
}

- (NameObjectStruct)readPlayerName: (UInt32)address withMemory:(MemoryAccess*)memory{
	NameObjectStruct objBad;
	objBad.guidLow = 1;
	
	NSNumber *key = [NSNumber numberWithUnsignedLong:address];
	NSNumber *value = [_nameListAddresses objectForKey:key];
	
	// we already have this guy stored?
	if ( value != nil ){
		[_nameListAddresses setObject:[NSNumber numberWithInt:[value intValue]+1] forKey:key];

		//_nameListSavedRead++;
		
		return objBad;
	}
	// add to list
	else{
		[_nameListAddresses setObject:[NSNumber numberWithInt:1] forKey:key];
	}
	
	// invalid address
	if ( address & 1 )
		return objBad;
	
	// load the entire chunk
	NameObjectStruct obj;
	[memory loadDataForObject: self atAddress: address Buffer: (Byte *)&obj BufLength: sizeof(obj)];
	
	// back in list, ignore!
	if ( obj.guidLow == 0x4 )
		return objBad;
	
	// if we get here we should have a valid name!
	NSString *newTmpName = [NSString stringWithUTF8String: obj.name];  // will stop after it's first encounter with '\0'
	
	// add the player?
	[playersController addPlayerName:newTmpName withGUID:obj.guid];
	
	return obj;
}

- (void)traverseNameList{
	UInt32 curObjAddress = 0x0, offset = [offsetController offset:@"PLAYER_NAME_LIST"];
	
	// reset our stats guy
	//_nameListSavedRead = 0;
	
	// + 0x58 is another pointer to within the list, not sure what it means?  first or last?
	MemoryAccess *memory = [self wowMemoryAccess];
	[memory resetLoadCount];
	if ( memory && [memory loadDataForObject: self atAddress: offset + 0x24 Buffer: (Byte*)&curObjAddress BufLength: sizeof(curObjAddress)] && curObjAddress ){
		
		// check to make sure the first value is 0x4!
		NameListStruct nameListStruct;
		NameObjectStruct nameStruct1, nameStruct2;
		
		[memory loadDataForObject: self atAddress: curObjAddress Buffer: (Byte*)&nameListStruct BufLength: sizeof(nameListStruct)];
		while ( nameListStruct.four == 0x4 ){
						
			// FIRST one in the list
			nameStruct1 = [self readPlayerName:nameListStruct.nextPtr - 0x4 withMemory:memory];
			
			// there are 2 pointers in EACH player struct, so lets check both
			if ( nameStruct1.guidLow != 1 ){

				[self readPlayerName:nameStruct1.nextPtr - 0xC withMemory:memory];
				[self readPlayerName:nameStruct1.prevPtr withMemory:memory];
			}
				
			// second in the list
			nameStruct2 = [self readPlayerName:nameListStruct.prevPtr withMemory:memory];
			
			// 2 more pointers due to the second struct check!
			if ( nameStruct2.guidLow != 1 ){
				[self readPlayerName:nameStruct2.nextPtr - 0xC withMemory:memory];
				[self readPlayerName:nameStruct2.prevPtr withMemory:memory];
			}

			curObjAddress += 0xC;
			[memory loadDataForObject: self atAddress: curObjAddress Buffer: (Byte*)&nameListStruct BufLength: sizeof(nameListStruct)];
		}
		
		//log(LOG_CONTROLLER, @"[Controller] Player names updated after %d memory reads", [memory loadCount]);
	}
}

#pragma mark -
#pragma mark WoW Structure Scanning

// Special thanks to EmilyStrange @ http://www.mmowned.com/forums/wow-memory-editing/261575-c-memory-enumerator-walking-objects.html
- (void)scanObjectList:(MemoryAccess*)memory{
	
	// clear crap from our last scan
	[_objectAddresses removeAllObjects];
	_currentAddress = 0;
	
	// find all object addresses
	UInt32 objectAddress = 0;
	while ( (objectAddress = [self getNextObjectAddress:memory]) && [self isValidAddress:objectAddress] ){
		_currentAddress = objectAddress;
		
		// save the object addresses
		[_objectAddresses addObject:[NSNumber numberWithUnsignedInt:objectAddress]];
	}
	
	// we have the addresses now, lets add them to our respective controllers
	[self sortObjects:memory];
	_totalObjects = [_objectAddresses count];
}

- (BOOL)isValidAddress: (UInt32)address{
	if ( address == 0x0 )
		return NO;
	
	if ( (address & 1) != 0 )
		return NO;
	
	if ( address == _currentAddress )
		return NO;
	
	return YES;
}

// player GUID (lower) is stored at [[OBJECT_LIST_LL_PTR] + 0xBC]
- (UInt32)getNextObjectAddress:(MemoryAccess*)memory{
	if ( _currentAddress == 0 ){
		UInt32 objectManager = 0;
		UInt32 firstObjectOffset = [offsetController offset:@"FIRST_OBJECT_OFFSET"];
		if([memory loadDataForObject: self atAddress: [offsetController offset:@"OBJECT_LIST_LL_PTR"] Buffer: (Byte*)&objectManager BufLength: sizeof(objectManager)] && objectManager) {
			_validObjectListManager = YES;
			UInt32 firstObjectPtr = 0;
			if([memory loadDataForObject: self atAddress: objectManager + firstObjectOffset Buffer: (Byte*)&firstObjectPtr BufLength: sizeof(firstObjectPtr)] && firstObjectPtr) {
				return firstObjectPtr;
			}
		}
	}

	UInt32 nextObjectAddress = 0;
	if([memory loadDataForObject: self atAddress: _currentAddress + 0x34 Buffer: (Byte*)&nextObjectAddress BufLength: sizeof(nextObjectAddress)] && nextObjectAddress) {
		return nextObjectAddress;
	}
	
	return 0;
}

- (void)sortObjects: (MemoryAccess*)memory{
	
	// remove all known
	[_objectGUIDs removeAllObjects];
	
	UInt32 objectAddress = 0;
	for ( NSNumber *objAddress in _objectAddresses ){
		objectAddress = [objAddress unsignedIntValue];

		int objectType = TYPEID_UNKNOWN;
		if ( [memory loadDataForObject: self atAddress: (objectAddress + OBJECT_TYPE_ID) Buffer: (Byte*)&objectType BufLength: sizeof(objectType)] ) {

			// store object GUIDs
			UInt32 guid = 0x0;
			[memory loadDataForObject: self atAddress: (objectAddress + OBJECT_GUID_LOW32) Buffer: (Byte*)&guid BufLength: sizeof(guid)];
			[_objectGUIDs addObject:[NSNumber numberWithInt:guid]];

			// item
			if ( objectType == TYPEID_ITEM || objectType == TYPEID_CONTAINER ) {
				[_items addObject: objAddress];
				continue;
			}
			
			// mob
			if ( objectType == TYPEID_UNIT ) {
				[_mobs addObject: objAddress];
				continue;
			}
			
			// player
			if ( objectType == TYPEID_PLAYER ) {
				
				if ( guid == GUID_LOW32(_globalGUID) ){
					if ( objectAddress != [playerData baselineAddress] ){
						
						log(LOG_CONTROLLER, @"[Controller] Player base address 0x%X changed to 0x%X, verifying change...", [playerData baselineAddress], objectAddress);
						
						// reset mobs, nodes, and inventory for the new player address
						[mobController resetAllObjects];
						[nodeController resetAllObjects];
						[itemController resetAllObjects];
						[playersController resetAllObjects];
						
						// tell our player controller its new address
						[playerData setStructureAddress: objAddress];
						Player *player = [playerData player];
						log(LOG_CONTROLLER, @"[Player] Level %d %@ %@", [player level], [Unit stringForRace: [player race]], [Unit stringForClass: [player unitClass]]);
						
						[self setCurrentState: playerValidState];
					}			
				}
				
				//log(LOG_CONTROLLER, @"Player GUID: 0x%X Yours: 0x%X 0x%qX", guid, GUID_LOW32(_globalGUID), _globalGUID);

				[_players addObject: objAddress];
				continue;
			}
			
			if(objectType == TYPEID_GAMEOBJECT) {
				[_gameObjects addObject: objAddress];
				continue;
			}
			
			if(objectType == TYPEID_DYNAMICOBJECT) {
				[_dynamicObjects addObject: objAddress];
				continue;
			}
			
			if(objectType == TYPEID_CORPSE) {
				[_corpses addObject: objAddress];
				continue;
			}
		}
	}
}

// [[OBJECT_MANAGER] + 0xC] ==[[OBJECT_MANAGER] + 0xAC] = First object in object list
// [[OBJECT_MANAGER] + 0x1C] = Object list (not in order)
- (UInt32)objectManager:(MemoryAccess*)memory{
	UInt32 objectManager = 0;
	if([memory loadDataForObject: self atAddress: [offsetController offset:@"OBJECT_LIST_LL_PTR"] Buffer: (Byte*)&objectManager BufLength: sizeof(objectManager)] && objectManager) {
		return objectManager;
	}
	
	return 0;	
}

// this gets our objects
- (void)scanObjectGraph {
	
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
	// populate wow process list
	[self populateWowInstances];
	
	// grab memory
    MemoryAccess *memory = [self wowMemoryAccess];
	
	// grab our global GUID
	[memory loadDataForObject: self atAddress: [offsetController offset:@"PLAYER_GUID_NAME"] Buffer: (Byte*)&_globalGUID BufLength: sizeof(_globalGUID)];
	//log(LOG_CONTROLLER, @"[Controller] Player GUID: 0x%qX 0x%qX Low32:0x%X High32:0x%X HiPart:0x%X", _globalGUID, CFSwapInt64HostToLittle(_globalGUID), GUID_LOW32(_globalGUID), GUID_HIGH32(_globalGUID), GUID_HIPART(_globalGUID));
	
	// object manager
	if ( memory ){
		
		UInt32 objectManager = [self objectManager:memory];
		// we have a valid object list
		if ( objectManager > 0x0 ){
			// our object manager has changed (wonder if this happens often?)
			if ( _currentObjectManager > 0x0 && _currentObjectManager != objectManager ){
				_validObjectListManager = NO;
				log(LOG_CONTROLLER, @"[Controller] Object manager changed from 0x%X to 0x%X", _currentObjectManager, objectManager);
			}
			
			_currentObjectManager = objectManager;
			_invalidPlayerNotificationSent = NO;
		}
		// no valid list, player not logged in or loading screen
		else if ( objectManager == 0x0 || _globalGUID == 0x0 ){
			if ( !_invalidPlayerNotificationSent ){
				_invalidPlayerNotificationSent = YES;
				[[NSNotificationCenter defaultCenter] postNotificationName: PlayerIsInvalidNotification object: nil];
			}
			
			// memory is valid, but no player :(
			[self setCurrentState: memoryValidState];
		}
		
		// now lets tell our appropriate controllers!
        [_items removeAllObjects];
        [_mobs removeAllObjects];
        [_players removeAllObjects];
        [_gameObjects removeAllObjects];
        [_dynamicObjects removeAllObjects];
        //[_corpses removeAllObjects];
        
        //NSDate *date = [NSDate date];
		[memory resetLoadCount];
		[self scanObjectList:memory];
		//log(LOG_CONTROLLER, @"[Controller] Found %d objects in game with %d memory operations", _totalObjects, [memory loadCount]);
		//log(LOG_CONTROLLER, @"New name scan took %.2f seconds and %d memory operations.", [date timeIntervalSinceNow]*-1.0, [memory loadCount]);
		
        //log(LOG_CONTROLLER, @"Memory scan took %.4f sec for %d total objects.", [date timeIntervalSinceNow]*-1.0f, [_mobs count] + [_items count] + [_gameObjects count] + [_players count]);
        //date = [NSDate date];
        
        [mobController addAddresses: _mobs];
        [itemController addAddresses: _items];
        [nodeController addAddresses: _gameObjects];
        [playersController addAddresses: _players];
		//[corpseController addAddresses: _corpses];
		
        //log(LOG_CONTROLLER, @"Controller adding took %.4f sec", [date timeIntervalSinceNow]*-1.0f);
        //date = [NSDate date];
		
        // clean-up; we don't need this crap sitting around
        [_items removeAllObjects];
        [_mobs removeAllObjects];
        [_players removeAllObjects];
        [_gameObjects removeAllObjects];
        [_dynamicObjects removeAllObjects];
        //[_corpses removeAllObjects];
		
		// is our player invalid?
		if ( ![playerData playerIsValid:self] ){
			[self setCurrentState: memoryValidState];
		}
		else{
			[self setCurrentState: playerValidState];
		}
        
        //log(LOG_CONTROLLER, @"Total scan took %.4f sec", [start timeIntervalSinceNow]*-1.0f);
        //log(LOG_CONTROLLER, @"-----------------");
    }
    
    // run this every second
    [self performSelector: @selector(scanObjectGraph) withObject: nil afterDelay: 1.0];
}

#pragma mark -
#pragma mark IBActions

- (IBAction)showAbout: (id)sender {
    [self checkWoWVersion];
    [self loadView: aboutView withTitle: [self appName]];
    [mainToolbar setSelectedItemIdentifier: nil];

    NSSize theSize = [aboutView frame].size; theSize.height += 20;
    [mainWindow setContentMinSize: theSize];
    [mainWindow setContentMaxSize: theSize];
    [mainWindow setShowsResizeIndicator: NO];
}

- (IBAction)showSettings: (id)sender {
    [self loadView: settingsView withTitle: @"Settings"];
    [mainToolbar setSelectedItemIdentifier: [prefsToolbarItem itemIdentifier]];
    
    NSSize theSize = [settingsView frame].size; theSize.height += 20;
    [mainWindow setContentMinSize: theSize];
    [mainWindow setContentMaxSize: theSize];
    [mainWindow setShowsResizeIndicator: NO];
    
    // setup security stuff
    self.matchExistingApp = nil;
    [matchExistingCheckbox setState: NSOffState];
    [newNameField setStringValue: [self appName]];
    [newSignatureField setStringValue: [self appSignature]];
    [newIdentifierField setStringValue: [self appIdentifier]];
}

- (IBAction)launchWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.savorydeviate.com/pocketgnome/forum/viewforum.php?f=39"]];
}

- (void)loadView: (NSView*)newView withTitle: (NSString*)title {
    if(!newView || (newView == [mainBackgroundBox contentView]) ) return;
	
    // set the view to blank
    NSView *tempView = [[NSView alloc] initWithFrame: [[mainWindow contentView] frame]];
    [mainBackgroundBox setContentView: tempView];
    [tempView release];
    
    NSRect newFrame = [mainWindow frame];
    newFrame.size.height =	[newView frame].size.height + ([mainWindow frame].size.height - [[mainWindow contentView] frame].size.height) + 20; // Compensates for toolbar
    newFrame.size.width =	[newView frame].size.width < MainWindowMinWidth ? MainWindowMinWidth : [newView frame].size.width;
    newFrame.origin.y +=	([[mainWindow contentView] frame].size.height - [newView frame].size.height - 20); // Origin moves by difference in two views
    newFrame.origin.x +=	([[mainWindow contentView] frame].size.width - newFrame.size.width)/2; // Origin moves by difference in two views, halved to keep center alignment
    
    /* // resolution independent resizing
     float vdiff = ([newView frame].size.height - [[mainWindow contentView] frame].size.height) * [mainWindow userSpaceScaleFactor];
     newFrame.origin.y -= vdiff;
     newFrame.size.height += vdiff;
     float hdiff = ([newView frame].size.width - [[mainWindow contentView] frame].size.width) * [mainWindow userSpaceScaleFactor];
     newFrame.size.width += hdiff;*/
    
    [mainWindow setFrame: newFrame display: YES animate: YES];
    [mainBackgroundBox setContentView: newView];
        
    [[NSNotificationCenter defaultCenter] postNotificationName: DidLoadViewInMainWindowNotification object: newView];
}

- (IBAction)toolbarItemSelected: (id)sender {
    NSView *newView = nil;
    NSString *addToTitle = nil;
    NSSize minSize = NSZeroSize, maxSize = NSZeroSize;
    if( [sender tag] == 1) {
        newView = [botController view];
        addToTitle = [botController sectionTitle];
        minSize = [botController minSectionSize];
        maxSize = [botController maxSectionSize];
    }
    if( [sender tag] == 2) {
        newView = [playerData view];
        addToTitle = [playerData sectionTitle];
        minSize = [playerData minSectionSize];
        maxSize = [playerData maxSectionSize];
    }
    if( [sender tag] == 3) {
        newView = [spellController view];
        addToTitle = [spellController sectionTitle];
        minSize = [spellController minSectionSize];
        maxSize = [spellController maxSectionSize];
    }
    if( [sender tag] == 6) {
        newView = [routeController view];
        addToTitle = [routeController sectionTitle];
        minSize = [routeController minSectionSize];
        maxSize = [routeController maxSectionSize];
    }
    if( [sender tag] == 7) {
        newView = [behaviorController view];
        addToTitle = [behaviorController sectionTitle];
        minSize = [behaviorController minSectionSize];
        maxSize = [behaviorController maxSectionSize];
    }
    //if( [sender tag] == 9) {
    //    newView = settingsView;
    //    addToTitle = @"Settings";
    //}
    if( [sender tag] == 10) {
        newView = [memoryViewController view];
        addToTitle = [memoryViewController sectionTitle];
        minSize = [memoryViewController minSectionSize];
        maxSize = [memoryViewController maxSectionSize];
    }
    if( [sender tag] == 12) {
        newView = [chatLogController view];
        addToTitle = [chatLogController sectionTitle];
        minSize = [chatLogController minSectionSize];
        maxSize = [chatLogController maxSectionSize];
    }
    if( [sender tag] == 14) {
        newView = [statisticsController view];
        addToTitle = [statisticsController sectionTitle];
        minSize = [statisticsController minSectionSize];
        maxSize = [statisticsController maxSectionSize];
    }
	if( [sender tag] == 15) {
        newView = [objectsController view];
        addToTitle = [objectsController sectionTitle];
        minSize = [objectsController minSectionSize];
        maxSize = [objectsController maxSectionSize];
    }
	if ( [sender tag] == 16 ){
		newView = [pvpController view];
        addToTitle = [pvpController sectionTitle];
        minSize = [pvpController minSectionSize];
        maxSize = [pvpController maxSectionSize];
	}
	if ( [sender tag] == 17 ) {
		newView = [profileController view];
		addToTitle = [profileController sectionTitle];
        minSize = [profileController minSectionSize];
        maxSize = [profileController maxSectionSize];
	}
	
    if(newView) {
        [self loadView: newView withTitle: addToTitle];
    }
    
    // correct the minSize
    if(NSEqualSizes(minSize, NSZeroSize)) {
        minSize = NSMakeSize(MainWindowMinWidth, MainWindowMinHeight);
    } else {
        minSize.height += 20;
    }
    
    // correct the maxSize
    if(NSEqualSizes(maxSize, NSZeroSize)) {
        maxSize = NSMakeSize(20000, 20000);
    } else {
        maxSize.height += 20;
    }
    
    // set constraints
    if(minSize.width < MainWindowMinWidth) minSize.width = MainWindowMinWidth;
    if(maxSize.width < MainWindowMinWidth) maxSize.width = MainWindowMinWidth;
    if(minSize.height < MainWindowMinHeight) minSize.height = MainWindowMinHeight;
    if(maxSize.height < MainWindowMinHeight) maxSize.height = MainWindowMinHeight;
    
    if((minSize.width == maxSize.width) && (minSize.height == maxSize.height)) {
        [mainWindow setShowsResizeIndicator: NO];
    } else {
        [mainWindow setShowsResizeIndicator: YES];
    }
    
    [mainWindow setContentMinSize: minSize];
    [mainWindow setContentMaxSize: maxSize];
}

#pragma mark -
#pragma mark State & Status

- (void)revertStatus {
    [self setCurrentStatus: _savedStatus];
}

- (NSString*)currentStatus {
    return [currentStatusText stringValue];
}

- (void)setCurrentStatus: (NSString*)statusMsg {
	
	log(LOG_CONTROLLER, @"[Controller] Setting status to: %@", statusMsg);
	
    NSString *currentText = [[currentStatusText stringValue] retain];
    [currentStatusText setStringValue: statusMsg];

    [_savedStatus release];
    _savedStatus = currentText;
}

- (BOOL)isObjectManagerValid{
	return _validObjectListManager;
}

- (NSArray*)allObjectAddresses{
	return [[_objectAddresses copy] autorelease];
}

- (NSArray*)allObjectGUIDs{
	return [[_objectGUIDs copy] autorelease];
}

@synthesize currentState = _currentState;
@synthesize isRegistered = _isRegistered;   // too many bindings rely on this property, keep it
@synthesize matchExistingApp = _matchExistingApp;
@synthesize globalGUID = _globalGUID;

- (void)setCurrentState: (int)state {
    if(_currentState == state) return;
    
    [self willChangeValueForKey: @"stateImage"];
    [self willChangeValueForKey: @"stateString"];
    _currentState = state;
    [self didChangeValueForKey: @"stateImage"];
    [self didChangeValueForKey: @"stateString"];
}

- (NSImage*)stateImage {
    if(self.currentState == memoryValidState)
        return [NSImage imageNamed: @"mixed"];
    if(self.currentState == playerValidState)
        return [NSImage imageNamed: @"on"];
    return [NSImage imageNamed: @"off"];
}

- (NSString*)stateString {
    if(self.currentState == wowNotOpenState)
        return @"WoW is not open";
    if(self.currentState == memoryInvalidState)
        return @"Memory access denied";
    if(self.currentState == memoryValidState)
        return @"Player not found";
    if(self.currentState == playerValidState)
        return @"Player is Valid";
    return @"Unknown State";
}

- (NSString*)appName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
}

- (NSString*)appSignature {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleSignature"];
}

- (NSString*)appIdentifier {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleIdentifier"];
}

- (BOOL)sendGrowlNotifications {
    return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"GlobalSendGrowlNotifications"] boolValue];
}

#pragma mark -
#pragma mark WoW Accessors


- (MemoryAccess*)wowMemoryAccess {
    // dont do anything until the app finishes launching
    if(!_appFinishedLaunching) {
        //log(LOG_CONTROLLER, @"App still launching; nil");
        return nil;
    }

    // if we have a good memory access, return it
    if(_wowMemoryAccess && [_wowMemoryAccess isValid]) {
        return [[_wowMemoryAccess retain] autorelease];
    }
    
    // we have a memory access, but it is no longer valid
    if(_wowMemoryAccess && ![_wowMemoryAccess isValid]) {
        [self willChangeValueForKey: @"wowMemoryAccess"];

        // send notification of invalidity
        log(LOG_CONTROLLER, @"Memory access is invalid.");
        [self setCurrentState: memoryInvalidState];

        [_wowMemoryAccess release];
        _wowMemoryAccess = nil;
        
        [self didChangeValueForKey: @"wowMemoryAccess"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: MemoryAccessInvalidNotification object: nil];
        
        return nil;
    }
    
    if(_wowMemoryAccess == nil) {
        if([self isWoWOpen]) {
            // log(LOG_CONTROLLER, @"Initializing memory access.");
            // otherwise, create one if possible
            pid_t wowPID = 0;
            ProcessSerialNumber wowPSN = [self getWoWProcessSerialNumber];
            OSStatus err = GetProcessPID(&wowPSN, &wowPID);
            
            //log(LOG_CONTROLLER, @"Got PID: %d", wowPID);
            
            // make sure the old one is disposed of, just incase
            [_wowMemoryAccess release];
            _wowMemoryAccess = nil;
            
            if(err == noErr && wowPID > 0) {
                // now we have a valid memory access
                [self willChangeValueForKey: @"wowMemoryAccess"];
                _wowMemoryAccess = [[MemoryAccess alloc] initWithPID: wowPID];
                [self didChangeValueForKey: @"wowMemoryAccess"];
                
                // send notification of validity
                if(_wowMemoryAccess && [_wowMemoryAccess isValid]) {
                    log(LOG_CONTROLLER, @"Memory access is valid for PID %d.", wowPID);
                    [self setCurrentState: memoryValidState];
                    [[NSNotificationCenter defaultCenter] postNotificationName: MemoryAccessValidNotification object: nil];
                    return [[_wowMemoryAccess retain] autorelease];
                } else {
                    log(LOG_CONTROLLER, @"Even after re-creation, memory access is nil (wowPID = %d).", wowPID);
                    return nil;
                }
            } else {
                log(LOG_CONTROLLER, @"Error %d while retrieving WoW's PID.", err);
            }
        } else {
            [self setCurrentState: wowNotOpenState];
        }
    }
    
    //log(LOG_CONTROLLER, @"Unable to get a handle on WoW's memory.");
    return nil;
}

- (BOOL)isWoWFront {
	NSDictionary *frontProcess;
	if( (frontProcess = [[NSWorkspace sharedWorkspace] activeApplication]) ) {
		NSString *bundleID = [frontProcess objectForKey: @"NSApplicationBundleIdentifier"];
		if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)isWoWHidden {
    ProcessSerialNumber wowPSN = [self getWoWProcessSerialNumber];
    NSDictionary *infoDict = (NSDictionary*)ProcessInformationCopyDictionary(&wowPSN, kProcessDictionaryIncludeAllInformationMask);
    [infoDict autorelease];
    return [[infoDict objectForKey: @"IsHiddenAttr"] boolValue];
}

- (BOOL)isWoWOpen {
    for(NSDictionary *processDict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
		NSString *bundleID = [processDict objectForKey: @"NSApplicationBundleIdentifier"];
		if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			return YES;
		}
	}
	return NO;
}

- (NSString*)wowPath {
    for(NSDictionary *processDict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
		NSString *bundleID = [processDict objectForKey: @"NSApplicationBundleIdentifier"];
		if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			return [processDict objectForKey: @"NSApplicationPath"];
		}
	}
	return @"";
}

- (NSString*)wtfAccountPath {
    if([[self wowMemoryAccess] isValid]) {
        NSString *fullPath = [self wowPath];
        fullPath = [fullPath stringByDeletingLastPathComponent];
        fullPath = [fullPath stringByAppendingPathComponent: @"WTF"];
        fullPath = [fullPath stringByAppendingPathComponent: @"Account"];
        fullPath = [fullPath stringByAppendingPathComponent: [playerData accountName]];
        
        BOOL isDir;
        if ([[NSFileManager defaultManager] fileExistsAtPath: fullPath isDirectory: &isDir] && isDir) {
            //log(LOG_CONTROLLER, @"Got full path: %@", fullPath);
            return fullPath;
        }
        //log(LOG_CONTROLLER, @"Unable to get path (%@)", fullPath);
    }
    return @"";
}

- (NSString*)wtfCharacterPath {
    if([[self wowMemoryAccess] isValid]) {
        // create the path
        NSString *path = [self wtfAccountPath];
        if([path length]) {
            path = [path stringByAppendingPathComponent: [playerData serverName]];
            path = [path stringByAppendingPathComponent: [playerData playerName]];
        }
        
        // see if it exists
        BOOL isDir;
        if ([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDir] && isDir) {
            return path;
        }
    }
    return @"";
}

- (BOOL)isWoWVersionValid {
    if( [VALID_WOW_VERSION isEqualToString: [self wowVersionShort]])
        return YES;
    return NO;
}

- (BOOL)makeWoWFront {
    if([self isWoWOpen]) {
        ProcessSerialNumber psn = [self getWoWProcessSerialNumber];
        SetFrontProcess( &psn );
        usleep(50000);
        return YES;
    }
    return NO;
}

- (NSString*)wowVersionShort {
    NSBundle *wowBundle = nil;
    if([self isWoWOpen]) {
        for(NSDictionary *processDict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
            NSString *bundleID = [processDict objectForKey: @"NSApplicationBundleIdentifier"];
            if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
                wowBundle = [NSBundle bundleWithPath: [processDict objectForKey: @"NSApplicationPath"]];
            }
        }
    } else {
        wowBundle = [NSBundle bundleWithPath: [[NSWorkspace sharedWorkspace] fullPathForApplication: @"World of Warcraft"]];
    }
    return [[wowBundle infoDictionary] objectForKey: @"CFBundleVersion"];
}

- (NSString*)wowVersionLong {
    NSBundle *wowBundle = nil;
    if([self isWoWOpen]) {
        for(NSDictionary *processDict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
            NSString *bundleID = [processDict objectForKey: @"NSApplicationBundleIdentifier"];
            if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
                wowBundle = [NSBundle bundleWithPath: [processDict objectForKey: @"NSApplicationPath"]];
            }
        }
    } else {
        wowBundle = [NSBundle bundleWithPath: [[NSWorkspace sharedWorkspace] fullPathForApplication: @"World of Warcraft"]];
    }
    return [[wowBundle infoDictionary] objectForKey: @"BlizzardFileVersion"];
}

- (ProcessSerialNumber)getWoWProcessSerialNumber {
	ProcessSerialNumber pSN = {kNoProcess, kNoProcess};
	pid_t wowPID = 0;
    for(NSDictionary *processDict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
		if( [[processDict objectForKey: @"NSApplicationBundleIdentifier"] isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			pSN.highLongOfPSN = [[processDict objectForKey: @"NSApplicationProcessSerialNumberHigh"] longValue];
			pSN.lowLongOfPSN  = [[processDict objectForKey: @"NSApplicationProcessSerialNumberLow"] longValue];
			
			OSStatus err = GetProcessPID(&pSN, &wowPID);
			_lastAttachedPID = wowPID;
			if( err == noErr && wowPID > 0 && wowPID == _selectedPID) {
				return pSN;
			}
		}
	}

	// This is ONLY the case when we load PG!
	if ( wowPID != _selectedPID ){
		_selectedPID = wowPID;
		
		// Now rebuild menu!
		[self populateWowInstances];
	}

	return pSN;
}

- (IBAction)pidSelected: (id)sender{
	// Only switch if the user chose a new one!
	if ( _selectedPID != _lastAttachedPID ){
		_wowMemoryAccess = nil;
		[self wowMemoryAccess];
	}
}

- (void)populateWowInstances{
	NSMutableArray *PIDs = [[NSMutableArray array] retain];
	
	// Lets find all available processes!
	ProcessSerialNumber pSN = {kNoProcess, kNoProcess};
    for(NSDictionary *processDict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
		if( [[processDict objectForKey: @"NSApplicationBundleIdentifier"] isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			pSN.highLongOfPSN = [[processDict objectForKey: @"NSApplicationProcessSerialNumberHigh"] longValue];
			pSN.lowLongOfPSN  = [[processDict objectForKey: @"NSApplicationProcessSerialNumberLow"] longValue];
			
			pid_t wowPID = 0;
			OSStatus err = GetProcessPID(&pSN, &wowPID);
			
			if((err == noErr) && (wowPID > 0)) {
				[PIDs addObject:[NSNumber numberWithInt:wowPID]];
			}
		}
	}
	
	// Build our menu! I'm sure I could use bindings to do this another way, but I'm a n00b :(
	NSMenu *wowInstanceMenu = [[[NSMenu alloc] initWithTitle: @"Instances"] autorelease];
	NSMenuItem *wowInstanceItem;
	int tagToSelect = 0;
    
	// WoW isn't open then :(
	if ( [PIDs count] == 0 ){
		wowInstanceItem = [[NSMenuItem alloc] initWithTitle: @"WoW is not open" action: nil keyEquivalent: @""];
		[wowInstanceItem setTag: 0];
		[wowInstanceItem setRepresentedObject: 0];
		[wowInstanceItem setIndentationLevel: 0];
		[wowInstanceMenu addItem: [wowInstanceItem autorelease]];
	}
	// We have some instances running!
	else{
		// Add all of them to the menu!
		for ( NSNumber *pid in PIDs ){
			wowInstanceItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@", pid] action: nil keyEquivalent: @""];
			[wowInstanceItem setTag: [pid intValue]];
			[wowInstanceItem setRepresentedObject: pid];
			[wowInstanceItem setIndentationLevel: 0];
			[wowInstanceMenu addItem: [wowInstanceItem autorelease]];
		}
		
		if ( _selectedPID != 0 ){
			tagToSelect = _selectedPID;
		}
		else{
			tagToSelect = [[PIDs objectAtIndex:0] intValue];;
		}
	}

    [wowInstancePopUpButton setMenu: wowInstanceMenu];
    [wowInstancePopUpButton selectItemWithTag: tagToSelect];
	
	[PIDs release];
}

-(int)getWOWWindowID  {
	CGError err = 0;
	int count = 0;
    ProcessSerialNumber pSN = [self getWoWProcessSerialNumber];
	CGSConnection connectionID = 0;
	CGSConnection myConnectionID = _CGSDefaultConnection();
	
    err = CGSGetConnectionIDForPSN(0, &pSN, &connectionID);
    if( err == noErr ) {
	
        //err = CGSGetOnScreenWindowCount(myConnectionID, connectionID, &count);
		err = CGSGetWindowCount(myConnectionID, connectionID, &count);
        if( (err == noErr) && (count > 0) ) {
        
            int i = 0, actualIDs = 0, windowList[count];
			
            //err = CGSGetOnScreenWindowList(myConnectionID, connectionID, count, windowList, &actualIDs);
			err = CGSGetWindowList(myConnectionID, connectionID, count, windowList, &actualIDs);
			
            for(i = 0; i < actualIDs; i++) {
				CGSValue windowTitle;
				CGSWindow window = windowList[i];
				//CFStringRef titleKey = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, "kCGSWindowTitle", kCFStringEncodingUTF8, kCFAllocatorNull); 
				err = CGSGetWindowProperty(myConnectionID, window, (CGSValue)CFSTR("kCGSWindowTitle"), &windowTitle);
                //if(titleKey) CFRelease(titleKey);
				if((err == noErr) && windowTitle) {
                    // log(LOG_CONTROLLER, @"%d: %@", window, windowTitle);
					return window;
				}
            }
        }
    }
	return 0;
}

- (BOOL)isWoWChatBoxOpen {
    unsigned value = 0;
    [[self wowMemoryAccess] loadDataForObject: self atAddress: [offsetController offset:@"CHAT_BOX_OPEN_STATIC"] Buffer: (Byte *)&value BufLength: sizeof(value)];
    return value;
}

- (unsigned)refreshDelay {
	
	return 50000;
	
	/*
    UInt32 refreshDelay = [self refreshDelayReal];

    if(refreshDelay > 1000000)  refreshDelay = 50000;   // incase we get a bogus number
    if(refreshDelay < 15000)    refreshDelay = 15000;   // incase we get a bogus number

    return refreshDelay*2;*/
}

- (CGRect)wowWindowRect {
    CGRect windowRect;
	int Connection = _CGSDefaultConnection();
	int windowID = [self getWOWWindowID];
	log(LOG_CONTROLLER, @"Connection: %d, Window id: %d", Connection, windowID);
    CGSGetWindowBounds(Connection, windowID, &windowRect);
    windowRect.origin.y += 22;      // cut off the title bar
    windowRect.size.height -= 22;

    return windowRect;
}

- (Position*)cameraPosition {
    if(IS_X86) {
        float pos[3] = { -1, -1, -1 };
        [[self wowMemoryAccess] loadDataForObject: self atAddress: 0xD6B198 Buffer: (Byte *)&pos BufLength: sizeof(pos)];
        return [Position positionWithX: pos[0] Y: pos[1] Z: pos[2]];
        
    }
    return nil;
}

- (float)cameraFacing {
    if(IS_X86) {
        float value = 0;
        [[self wowMemoryAccess] loadDataForObject: self atAddress: 0xD6B1BC Buffer: (Byte *)&value BufLength: sizeof(value)];
        return value;
    }
    return 0;
}

- (float)cameraTilt {
    if(IS_X86) {
        float value = 0;
        [[self wowMemoryAccess] loadDataForObject: self atAddress: 0xD6B1B8 Buffer: (Byte *)&value BufLength: sizeof(value)];
        return asinf(value);
    }
    return 0;
}

- (CGPoint)screenPointForGamePosition: (Position*)gP {
    Position *cP = [self cameraPosition];
    if(!gP || !cP) return CGPointZero;
    
    float ax = -[gP xPosition];
    float ay = -[gP zPosition];
    float az = [gP yPosition];
    
    log(LOG_CONTROLLER, @"Game position: { %.2f, %.2f, %.2f } (%@)", ax, ay, az, gP);
    
    float cx = -[cP xPosition];
    float cy = -[cP zPosition];
    float cz = [cP yPosition];

    log(LOG_CONTROLLER, @"Camera position: { %.2f, %.2f, %.2f } (%@)", cx, cy, cz, cP);
    
    float facing = [self cameraFacing];
    if(facing > M_PI) facing -= 2*M_PI;
    log(LOG_CONTROLLER, @"Facing: %.2f (%.2f), tilt = %.2f", facing, [self cameraFacing], [self cameraTilt]);
    
    float ox = [self cameraTilt];
    float oy = -facing;
    float oz = 0;
    
    log(LOG_CONTROLLER, @"Camera direction: { %.2f, %.2f, %.2f }", ox, oy, oz);

    
    float dx = cosf(oy) * ( sinf(oz) * (ay - cy) + cosf(oz) * (ax - cx)) - sinf(oy) * (az - cz);
    float dy = sinf(ox) * ( cosf(oy) * (az - cz) + sinf(oy) * ( sinf(oz) * (ay - cy) + cosf(oz) * (ax - cx))) + cosf(ox) * ( cosf(oz) * (ay - cy) - sinf(oz) * (ax - cx) );
    float dz = cosf(ox) * ( cosf(oy) * (az - cz) + sinf(oy) * ( sinf(oz) * (ay - cy) + cosf(oz) * (ax - cx))) - sinf(ox) * ( cosf(oz) * (ay - cy) - sinf(oz) * (ax - cx) );
    
    log(LOG_CONTROLLER, @"Calcu position: { %.2f, %.2f, %.2f }", dx, dy, dz);
    
    float bx = (dx - cx) * (cz/dz);
    float by = (dy - cy) * (cz/dz);

    log(LOG_CONTROLLER, @"Projected 2d position: { %.2f, %.2f }", bx, by);
    
    if(dz <= 0) {
        log(LOG_CONTROLLER, @"behind the camera1");
        //return CGPointMake(-1, -1);
    }
    
    CGRect wowSize = [self wowWindowRect];
    CGPoint wowCenter = CGPointMake( wowSize.origin.x+wowSize.size.width/2.0f, wowSize.origin.y+wowSize.size.height/2.0f);
    
    log(LOG_CONTROLLER, @"WowWindowSize: %@", NSStringFromRect(NSRectFromCGRect(wowSize)));
    log(LOG_CONTROLLER, @"WoW Center: %@", NSStringFromPoint(NSPointFromCGPoint(wowCenter)));
    
    float FOV1 = 0.1;
    float FOV2 = 3 /* 7.4 */ * wowSize.size.width;
    int sx = dx * (FOV1 / (dz + FOV1)) * FOV2 + wowCenter.x;
    int sy = dy * (FOV1 / (dz + FOV1)) * FOV2 + wowCenter.y;
    
    // ensure on screen
    if(sx < wowSize.origin.x || sy < wowSize.origin.y || sx >= wowSize.origin.x+wowSize.size.width || sy >= wowSize.origin.y+wowSize.size.height) {
        log(LOG_CONTROLLER, @"behind the camera2");
        //return CGPointMake(-1, -1);
    }
    return CGPointMake(sx, sy);
}

#pragma mark -
#pragma mark Faction Information

    // Keys:
    //  @"ReactMask",       Number
    //  @"FriendMask",      Number
    //  @"EnemyMask",       Number
    //  @"EnemyFactions",   Array
    //  @"FriendFactions"   Array
    
- (NSDictionary*)factionDict {
    return [[factionTemplate retain] autorelease];
}

- (UInt32)reactMaskForFaction: (UInt32)faction {
    NSNumber *mask = [[[self factionDict] objectForKey: [NSString stringWithFormat: @"%d", faction]] objectForKey: @"ReactMask"];
    if(mask)
        return [mask unsignedIntValue];
    return 0;
}

- (UInt32)friendMaskForFaction: (UInt32)faction {
    NSNumber *mask = [[[self factionDict] objectForKey: [NSString stringWithFormat: @"%d", faction]] objectForKey: @"FriendMask"];
    if(mask)
        return [mask unsignedIntValue];
    return 0;
}

- (UInt32)enemyMaskForFaction: (UInt32)faction {
    NSNumber *mask = [[[self factionDict] objectForKey: [NSString stringWithFormat: @"%d", faction]] objectForKey: @"EnemyMask"];
    if(mask)
        return [mask unsignedIntValue];
    return 0;
}


#pragma mark -

- (void)showMemoryView {
    [self performSelector: [memoryToolbarItem action] withObject: memoryToolbarItem];
}

#pragma mark Toolbar Delegate

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
            [botToolbarItem itemIdentifier], 
            [chatLogToolbarItem itemIdentifier],
            NSToolbarSpaceItemIdentifier,
            [playerToolbarItem itemIdentifier], 
            [spellsToolbarItem itemIdentifier],
            NSToolbarSpaceItemIdentifier,
			[objectsToolbarItem itemIdentifier], 
            NSToolbarSpaceItemIdentifier,
			[pvpToolbarItem itemIdentifier],
            [routesToolbarItem itemIdentifier], 
            [behavsToolbarItem itemIdentifier],
			[profilesToolbarItem itemIdentifier],
            NSToolbarFlexibleSpaceItemIdentifier,
			[statisticsToolbarItem itemIdentifier],
            [memoryToolbarItem itemIdentifier],
            [prefsToolbarItem itemIdentifier], nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar;
{
    // Optional delegate method: Returns the identifiers of the subset of
    // toolbar items that are selectable. In our case, all of them
    return [NSArray arrayWithObjects:  [botToolbarItem itemIdentifier], 
            [playerToolbarItem itemIdentifier], 
            [spellsToolbarItem itemIdentifier],
            [routesToolbarItem itemIdentifier], 
            [behavsToolbarItem itemIdentifier],
            [memoryToolbarItem itemIdentifier],
            [prefsToolbarItem itemIdentifier],
            [chatLogToolbarItem itemIdentifier], 
			[statisticsToolbarItem itemIdentifier],
			[objectsToolbarItem itemIdentifier],
			[pvpToolbarItem itemIdentifier], 
			[profilesToolbarItem itemIdentifier], nil];
}

#pragma mark -
#pragma mark Growl Delegate

/*	 The dictionary should have the required key object pairs:
 *	 key: GROWL_NOTIFICATIONS_ALL		object: <code>NSArray</code> of <code>NSString</code> objects
 *	 key: GROWL_NOTIFICATIONS_DEFAULT	object: <code>NSArray</code> of <code>NSString</code> objects
 */
 
- (NSDictionary *) registrationDictionaryForGrowl {
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Growl Registration Ticket" ofType: @"growlRegDict"]];
    return dict;
}

- (NSString *) applicationNameForGrowl {
    // NSLog(@"applicationNameForGrowl: %@", [self appName]);
    return [self appName]; //@"Pocket Gnome";
}

- (NSImage *) applicationIconForGrowl {
    //log(LOG_CONTROLLER, @"applicationIconForGrowl");
    return [NSApp applicationIconImage]; // [NSImage imageNamed: @"gnome2"];
}

- (NSData *) applicationIconDataForGrowl {
    //log(LOG_CONTROLLER, @"applicationIconDataForGrowl");
    return [[NSApp applicationIconImage] TIFFRepresentation];
}

#pragma mark Sparkle - Auto Updater

// Sent when a valid update is found by the update driver.		
- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {		
	PGLog(@"[Update] didFindValidUpdate: %@", [update fileURL]);		
}		
	
- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update {		
	PGLog(@"[Update] willInstallUpdate: %@", [update fileURL]);		
}


- (BOOL)updater: (SUUpdater *)updater shouldPostponeRelaunchForUpdate: (SUAppcastItem *)update untilInvoking: (NSInvocation *)invocation {
	
    if( ![[self appName] isEqualToString: @"Pocket Gnome"] ) {
		// log(LOG_CONTROLLER, @"[Update] We've been renamed.");
        
        NSAlert *alert = [NSAlert alertWithMessageText: @"SECURITY ALERT: PLEASE BE AWARE" 
                                         defaultButton: @"Understood" 
                                       alternateButton: nil
                                           otherButton: nil 
                             informativeTextWithFormat: @"During the update process, the file name of the downloaded version of Pocket Gnome will be changed to \"%@\".\n\nHowever, the executable, signature, and identifier inside the new version WILL NOT BE CHANGED. In order for rename settings to stay in effect, you must manually reapply them from the \"Security\" panel.", [self appName]];
        [alert setAlertStyle: NSCriticalAlertStyle]; 
        [alert beginSheetModalForWindow: mainWindow 
                          modalDelegate: self 
                         didEndSelector: @selector(updateAlertConfirmed:returnCode:contextInfo:)
                            contextInfo: (void*)[invocation retain]];
        return YES;
    }
    //log(LOG_CONTROLLER, @"[Update] Relaunching as expected.");
    return NO;
}

- (void)updateAlertConfirmed:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSInvocation *invocation = (NSInvocation*)contextInfo;
    [invocation invoke];
}

- (void)killWOW{
	ProcessSerialNumber pSN = [self getWoWProcessSerialNumber];
	if( pSN.lowLongOfPSN == kNoProcess) return;
	NSLog(@"Quitting WoW");
	
	// send Quit apple event
	OSStatus status;
	AEDesc targetProcess = {typeNull, NULL};
	AppleEvent theEvent = {typeNull, NULL};
	AppleEvent eventReply = {typeNull, NULL}; 
	
	status = AECreateDesc(typeProcessSerialNumber, &pSN, sizeof(pSN), &targetProcess);
	require_noerr(status, AECreateDesc);
	
	status = AECreateAppleEvent(kCoreEventClass, kAEQuitApplication, &targetProcess, kAutoGenerateReturnID, kAnyTransactionID, &theEvent);
	require_noerr(status, AECreateAppleEvent);
	
	status = AESend(&theEvent, &eventReply, kAENoReply + kAEAlwaysInteract, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
	require_noerr(status, AESend);
	
AESend:;
AECreateAppleEvent:;
AECreateDesc:;
	
	AEDisposeDesc(&eventReply); 
	AEDisposeDesc(&theEvent);
AEDisposeDesc(&targetProcess);
}

// 3.3.3a: 0xC9241C ClientServices_GetCurrent
- (float)getPing{
	
	MemoryAccess *memory = [self wowMemoryAccess];
	int totalPings = 0, v5 = 0, v6 = 0, samples = 0, ping = 0;
	UInt32 gCurrentClientServices = 0;
	[memory loadDataForObject: self atAddress: 0xC9241C Buffer: (Byte*)&gCurrentClientServices BufLength: sizeof(gCurrentClientServices)];
	[memory loadDataForObject: self atAddress: gCurrentClientServices + 0x2E74 Buffer: (Byte*)&v6 BufLength: sizeof(v6)];
	[memory loadDataForObject: self atAddress: gCurrentClientServices + 0x2E78 Buffer: (Byte*)&v5 BufLength: sizeof(v5)];
	
	if ( v6 == v5 ){
		return 0.0f;
	}
	
	do
	{
		if ( v6 >= 16 ){
			v6 = 0;
			if ( !v5 )
				break;
		}
		
		[memory loadDataForObject: self atAddress: gCurrentClientServices + 0x2E34 + (v6++ * 4) Buffer: (Byte*)&ping BufLength: sizeof(ping)];
		totalPings += ping;
		++samples;
	}
	while ( v6 != v5 );
	
	if ( samples > 0 ){
		float averagePing = (float)totalPings / (float)samples;
		return averagePing;
	}

	return 0.0f;
}

- (void)selectCombatProfileTab{
	[self toolbarItemSelected: profilesToolbarItem];
	[mainToolbar setSelectedItemIdentifier: [profilesToolbarItem itemIdentifier]];
	[profileController openEditor:TabCombat];
}

- (void)selectBehaviorTab{
	[self toolbarItemSelected: behavsToolbarItem];
	[mainToolbar setSelectedItemIdentifier: [behavsToolbarItem itemIdentifier]];
}

- (void)selectRouteTab{
	[self toolbarItemSelected: routesToolbarItem];
	[mainToolbar setSelectedItemIdentifier: [routesToolbarItem itemIdentifier]];
}

- (void)selectPvPRouteTab{
	[self toolbarItemSelected: pvpToolbarItem];
	[mainToolbar setSelectedItemIdentifier: [pvpToolbarItem itemIdentifier]];
}

@end
