//
//  CombatProfileActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IgnoreEntry.h"
#import "FileObject.h"

@class Unit;
@class Player;

@interface CombatProfile : FileObject {
    NSMutableArray *_combatEntries;
    
    BOOL combatEnabled, onlyRespond, attackNeutralNPCs, attackHostileNPCs, attackPlayers, attackPets;
    BOOL attackAnyLevel, ignoreElite, ignoreLevelOne, ignoreFlying;
	
	// Healing
	BOOL healingEnabled, autoFollowTarget, mountEnabled;
	float healingRange;
	
	// Party
	UInt64 tankUnitGUID;
	UInt64 assistUnitGUID;
	UInt64 followUnitGUID;
	float followDistanceToMove, yardsBehindTargetStart, yardsBehindTargetStop;
	BOOL assistUnit, tankUnit, followUnit, partyEnabled;
	BOOL disableRelease;
    
    float attackRange, engageRange;
    int attackLevelMin, attackLevelMax;
	
	// New additions
	BOOL partyDoNotInitiate;
	BOOL partyIgnoreOtherFriendlies;
	BOOL partyEmotes;
	int partyEmotesIdleTime;
	int partyEmotesInterval;
	BOOL followEnabled;
	BOOL followStopFollowingOOR;
	float followStopFollowingRange;
	BOOL followDoNotAssignLeader;
	float followDoNotAssignLeaderRange;
	BOOL followEnemyFlagCarriers;
	BOOL followFriendlyFlagCarriers;
	
	// PvP
	BOOL pvpQueueForRandomBattlegrounds;
	BOOL pvpStopHonor;
	int pvpStopHonorTotal;
	BOOL pvpLeaveIfInactive;
	BOOL pvpDontMoveWithPreparation;
	BOOL pvpWaitToLeave;
	float pvpWaitToLeaveTime;	
	BOOL pvpStayInWintergrasp;
	
	BOOL resurrectWithSpiritHealer;
	BOOL checkForCampers;
	float checkForCampersRange;
	BOOL avoidMobsWhenResurrecting;	
	float moveToCorpseRange;

	BOOL partyLeaderWait;
	float partyLeaderWaitRange;

	// Looting and Gathering
	BOOL DoMining;
	int MiningLevel;
	BOOL DoHerbalism;
	int HerbalismLevel;
	float GatheringDistance;
	BOOL DoNetherwingEggs;
	BOOL ShouldLoot;
	BOOL DoSkinning;
	int SkinningLevel;
	BOOL DoNinjaSkin;
	BOOL GatherUseCrystallized;
	BOOL GatherNodesHostilePlayerNear;
	float GatherNodesHostilePlayerNearRange;
	BOOL GatherNodesFriendlyPlayerNear;
	float GatherNodesFriendlyPlayerNearRange;
	BOOL GatherNodesMobNear;
	float GatherNodesMobNearRange;
	BOOL DoFishing;
	BOOL FishingApplyLure;
	int FishingLureID;
	BOOL FishingUseContainers;
	BOOL FishingOnlySchools;
	BOOL FishingRecast;
	float FishingGatherDistance;
	
}

+ (id)combatProfile;
+ (id)combatProfileWithName: (NSString*)name;

- (BOOL)unitShouldBeIgnored: (Unit*)unit;

- (unsigned)entryCount;
- (IgnoreEntry*)entryAtIndex: (unsigned)index;

- (void)addEntry: (IgnoreEntry*)entry;
- (void)removeEntry: (IgnoreEntry*)entry;
- (void)removeEntryAtIndex: (unsigned)index;

@property (readwrite, retain) NSArray *entries;
@property (readwrite, assign) UInt64 tankUnitGUID;
@property (readwrite, assign) UInt64 assistUnitGUID;
@property (readwrite, assign) UInt64 followUnitGUID;
@property (readwrite, assign) BOOL combatEnabled;
@property (readwrite, assign) BOOL onlyRespond;
@property (readwrite, assign) BOOL attackNeutralNPCs;
@property (readwrite, assign) BOOL attackHostileNPCs;
@property (readwrite, assign) BOOL attackPlayers;
@property (readwrite, assign) BOOL attackPets;
@property (readwrite, assign) BOOL attackAnyLevel;
@property (readwrite, assign) BOOL ignoreElite;
@property (readwrite, assign) BOOL ignoreLevelOne;
@property (readwrite, assign) BOOL ignoreFlying;
@property (readwrite, assign) BOOL assistUnit;
@property (readwrite, assign) BOOL tankUnit;
@property (readwrite, assign) BOOL followUnit;
@property (readwrite, assign) BOOL partyEnabled;

@property (readwrite, assign) BOOL healingEnabled;
@property (readwrite, assign) BOOL autoFollowTarget;
@property (readwrite, assign) float followDistanceToMove;
@property (readwrite, assign) float yardsBehindTargetStart;
@property (readwrite, assign) float yardsBehindTargetStop;
@property (readwrite, assign) float healingRange;
@property (readwrite, assign) BOOL mountEnabled;
@property (readwrite, assign) BOOL disableRelease;
@property (readwrite, assign) float attackRange;
@property (readwrite, assign) float engageRange;
@property (readwrite, assign) int attackLevelMin;
@property (readwrite, assign) int attackLevelMax;

// New additions
@property (readwrite, assign) BOOL checkForCampers;
@property (readwrite, assign) BOOL partyDoNotInitiate;
@property (readwrite, assign) BOOL partyIgnoreOtherFriendlies;
@property (readwrite, assign) BOOL partyEmotes;
@property (readwrite, assign) int partyEmotesIdleTime;
@property (readwrite, assign) int partyEmotesInterval;
@property (readwrite, assign) BOOL followEnabled;
@property (readwrite, assign) BOOL followStopFollowingOOR;
@property (readwrite, assign) float followStopFollowingRange;
@property (readwrite, assign) BOOL followDoNotAssignLeader;
@property (readwrite, assign) float followDoNotAssignLeaderRange;

@property (readwrite, assign) BOOL followEnemyFlagCarriers;
@property (readwrite, assign) BOOL followFriendlyFlagCarriers;

@property (readwrite, assign) BOOL resurrectWithSpiritHealer;
@property (readwrite, assign) float checkForCampersRange;
@property (readwrite, assign) BOOL avoidMobsWhenResurrecting;
@property (readwrite, assign) float moveToCorpseRange;
@property (readwrite, assign) BOOL partyLeaderWait;
@property (readwrite, assign) float partyLeaderWaitRange;

// PvP
@property (readwrite, assign) BOOL pvpQueueForRandomBattlegrounds;
@property (readwrite, assign) BOOL pvpStopHonor;
@property (readwrite, assign) int pvpStopHonorTotal;
@property (readwrite, assign) BOOL pvpLeaveIfInactive;
@property (readwrite, assign) BOOL pvpDontMoveWithPreparation;
@property (readwrite, assign) BOOL pvpWaitToLeave;
@property (readwrite, assign) float pvpWaitToLeaveTime;
@property (readwrite, assign) BOOL pvpStayInWintergrasp;

// Gathering and Looting
@property (readwrite, assign) BOOL DoMining;
@property (readwrite, assign) int MiningLevel;
@property (readwrite, assign) BOOL DoHerbalism;
@property (readwrite, assign) int HerbalismLevel;
@property (readwrite, assign) float GatheringDistance;
@property (readwrite, assign) BOOL DoNetherwingEggs;
@property (readwrite, assign) BOOL ShouldLoot;
@property (readwrite, assign) BOOL DoSkinning;
@property (readwrite, assign) int SkinningLevel;
@property (readwrite, assign) BOOL DoNinjaSkin;
@property (readwrite, assign) BOOL GatherUseCrystallized;
@property (readwrite, assign) BOOL GatherNodesHostilePlayerNear;
@property (readwrite, assign) float GatherNodesHostilePlayerNearRange;
@property (readwrite, assign) BOOL GatherNodesFriendlyPlayerNear;
@property (readwrite, assign) float GatherNodesFriendlyPlayerNearRange;
@property (readwrite, assign) BOOL GatherNodesMobNear;
@property (readwrite, assign) float GatherNodesMobNearRange;
@property (readwrite, assign) BOOL DoFishing;
@property (readwrite, assign) BOOL FishingApplyLure;
@property (readwrite, assign) int FishingLureID;
@property (readwrite, assign) BOOL FishingUseContainers;
@property (readwrite, assign) BOOL FishingOnlySchools;
@property (readwrite, assign) BOOL FishingRecast;
@property (readwrite, assign) float FishingGatherDistance;

@end
