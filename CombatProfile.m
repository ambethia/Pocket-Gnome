//
//  CombatProfileActionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "CombatProfile.h"
#import "Unit.h"
#import "Mob.h"
#import "IgnoreEntry.h"
#import "Offsets.h"
#import "FileObject.h"

#import "PlayerDataController.h"

@implementation CombatProfile

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.entries = [NSArray array];
        self.combatEnabled = YES;
        self.onlyRespond = NO;
        self.attackNeutralNPCs = YES;
        self.attackHostileNPCs = YES;
        self.attackPlayers = NO;
        self.attackPets = NO;
        self.attackAnyLevel = YES;
        self.ignoreElite = YES;
        self.ignoreLevelOne = YES;
		self.ignoreFlying = YES;
		
		// Party mode
		self.partyEnabled = NO;
		self.assistUnit = NO;
		self.tankUnit = NO;
		self.assistUnitGUID = 0x0;
		self.tankUnitGUID = 0x0;
		self.followUnitGUID = 0x0;
		self.followUnit = NO;
		self.yardsBehindTargetStart = 10.0;
		self.yardsBehindTargetStop = 15.0;
		self.followDistanceToMove = 20.0;
		self.followEnemyFlagCarriers = NO;
		self.followFriendlyFlagCarriers = NO;
		
		self.disableRelease = NO;

		// New additions
		self.partyDoNotInitiate = YES;
		self.partyIgnoreOtherFriendlies = YES;
		self.partyEmotes = NO;
		self.partyEmotesIdleTime = 120;
		self.partyEmotesInterval = 100;
		self.followEnabled = NO;
		self.followStopFollowingOOR = NO;
		self.followStopFollowingRange = 50.0f;
		self.followDoNotAssignLeader = NO;
		self.followDoNotAssignLeaderRange = 50.0f;

		self.resurrectWithSpiritHealer = NO;
		self.checkForCampers = NO;
		self.checkForCampersRange = 50.0f;
		self.avoidMobsWhenResurrecting = YES;
		self.moveToCorpseRange = 35.0f;
		self.partyLeaderWait = NO;
		self.partyLeaderWaitRange = 35.0f;

		// Healing
		self.healingEnabled = NO;
		self.autoFollowTarget = NO;
		self.healingRange = 40.0f;
		self.mountEnabled = NO;

        self.attackRange = 20.0f;
		self.engageRange = 30.0f;
        self.attackLevelMin = 2;
        self.attackLevelMax = PLAYER_LEVEL_CAP;
		
		// PvP
		self.pvpQueueForRandomBattlegrounds = NO;
		self.pvpStopHonor = NO;
		self.pvpStopHonorTotal = 75000;
		self.pvpLeaveIfInactive = YES;
		self.pvpDontMoveWithPreparation = NO;
		self.pvpWaitToLeave = YES;
		self.pvpWaitToLeaveTime = 10.0;
		self.pvpStayInWintergrasp = YES;
		
		self.DoMining = NO;
		self.MiningLevel = 0;
		self.DoHerbalism = NO;
		self.HerbalismLevel = 0;
		self.GatheringDistance = 50.0;
		self.DoNetherwingEggs = NO;
		self.ShouldLoot = NO;
		self.DoSkinning = NO;
		self.SkinningLevel = 0;
		self.DoNinjaSkin = NO;
		self.GatherUseCrystallized = NO;
		self.GatherNodesHostilePlayerNear = NO;
		self.GatherNodesHostilePlayerNearRange = 50.0;
		self.GatherNodesFriendlyPlayerNear = NO;
		self.GatherNodesFriendlyPlayerNearRange = 50.0;
		self.GatherNodesMobNear = NO;
		self.GatherNodesMobNearRange = 50.0;
		self.DoFishing = NO;
		self.FishingApplyLure = 0;
		self.FishingLureID = NO;
		self.FishingUseContainers = NO;
		self.FishingOnlySchools = NO;
		self.FishingRecast = NO;
		self.FishingGatherDistance = 15.0;
		
		_observers = [[NSArray arrayWithObjects:
					   @"combatEnabled",
					   @"onlyRespond",
					   @"attackNeutralNPCs",
					   @"attackHostileNPCs",
					   @"attackPlayers",
					   @"attackPets",
					   @"attackAnyLevel",
					   @"ignoreElite",
					   @"ignoreLevelOne",
					   @"ignoreFlying",
					   @"assistUnit",
					   @"assistUnitGUID",
					   @"tankUnit",
					   @"tankUnitGUID",
					   @"followUnit",
					   @"followUnitGUID",
					   @"partyEnabled",
					   @"followDistanceToMove",
					   @"yardsBehindTargetStart",
					   @"yardsBehindTargetStop",
					   @"ignoreFlying",
					   @"healingEnabled",
					   @"autoFollowTarget",
					   @"healingRange",
					   @"mountEnabled",
					   @"disableRelease",
					   @"engageRange",
					   @"attackRange",
					   @"attackLevelMin",
					   @"attackLevelMax",
					   @"partyDoNotInitiate",
					   @"partyIgnoreOtherFriendlies",
					   @"partyEmotes",
					   @"partyEmotesIdleTime",
					   @"partyEmotesInterval",
					   @"followEnabled",
					   @"followStopFollowingOOR",
					   @"followStopFollowingRange",
					   @"resurrectWithSpiritHealer",
					   @"checkForCampers",
					   @"checkForCampersRange",
					   @"avoidMobsWhenResurrecting",
					   @"moveToCorpseRange",
					   @"partyLeaderWait",
					   @"partyLeaderWaitRange",
					   @"pvpQueueForRandomBattlegrounds",
					   @"pvpStopHonor",
					   @"pvpStopHonorTotal",
					   @"pvpLeaveIfInactive",
					   @"pvpDontMoveWithPreparation",
					   @"pvpWaitToLeave",
					   @"pvpWaitToLeaveTime",
					   @"pvpStayInWintergrasp",
					   @"DoMining",
					   @"MiningLevel",
					   @"DoHerbalism",
					   @"HerbalismLevel",
					   @"GatheringDistance",
					   @"DoNetherwingEggs",
					   @"ShouldLoot",
					   @"DoSkinning",
					   @"SkinningLevel",
					   @"DoNinjaSkin",
					   @"GatherUseCrystallized",
					   @"GatherNodesHostilePlayerNear",
					   @"GatherNodesHostilePlayerNearRange",
					   @"GatherNodesFriendlyPlayerNear",
					   @"GatherNodesFriendlyPlayerNearRange",
					   @"GatherNodesMobNear",
					   @"GatherNodesMobNearRange",
					   @"DoFishing",
					   @"FishingApplyLure",
					   @"FishingLureID",
					   @"FishingUseContainers",
					   @"FishingOnlySchools",
					   @"FishingRecast",
					   @"FishingGatherDistance",
					   
					   nil] retain];
    }
    return self;
}

- (id)initWithName: (NSString*)name {
    self = [self init];
    if (self != nil) {
        self.name = name;
    }
    return self;
}

+ (id)combatProfile {
    return [[[CombatProfile alloc] init] autorelease];
}

+ (id)combatProfileWithName: (NSString*)name {
    return [[[CombatProfile alloc] initWithName: name] autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    CombatProfile *copy = [[[self class] allocWithZone: zone] initWithName: self.name];
    
    copy.entries = self.entries;
    copy.combatEnabled = self.combatEnabled;
    copy.onlyRespond = self.onlyRespond;
    copy.attackNeutralNPCs = self.attackNeutralNPCs;
    copy.attackHostileNPCs = self.attackHostileNPCs;
    copy.attackPlayers = self.attackPlayers;
    copy.attackPets = self.attackPets;
    copy.attackAnyLevel = self.attackAnyLevel;
    copy.ignoreElite = self.ignoreElite;
    copy.ignoreLevelOne = self.ignoreLevelOne;
	copy.ignoreFlying = self.ignoreFlying;
	
	copy.assistUnit = self.assistUnit;
	copy.assistUnitGUID = self.assistUnitGUID;
	copy.tankUnit = self.tankUnit;
	copy.tankUnitGUID = self.tankUnitGUID;
	copy.partyEnabled = self.partyEnabled;
	copy.followUnit = self.followUnit;
	copy.followUnitGUID = self.followUnitGUID;
	copy.followDistanceToMove = self.followDistanceToMove;
	copy.yardsBehindTargetStart = self.yardsBehindTargetStart;
	copy.yardsBehindTargetStop = self.yardsBehindTargetStop;
	copy.disableRelease = self.disableRelease;
	
	copy.healingEnabled = self.healingEnabled;
    copy.autoFollowTarget = self.autoFollowTarget;
	copy.healingRange = self.healingRange;
	copy.mountEnabled = self.mountEnabled;
	
    copy.attackRange = self.attackRange;
	copy.engageRange = self.engageRange;
    copy.attackLevelMin = self.attackLevelMin;
    copy.attackLevelMax = self.attackLevelMax;

	// New additions
	copy.partyDoNotInitiate = self.partyDoNotInitiate;
	copy.partyIgnoreOtherFriendlies = self.partyIgnoreOtherFriendlies;
	copy.partyEmotes = self.partyEmotes;
	copy.partyEmotesIdleTime = self.partyEmotesIdleTime;
	copy.partyEmotesInterval = self.partyEmotesInterval;
	copy.followEnabled = self.followEnabled;
	copy.followStopFollowingOOR = self.followStopFollowingOOR;
	copy.followStopFollowingRange = self.followStopFollowingRange;
	copy.followDoNotAssignLeader = self.followDoNotAssignLeader;
	copy.followDoNotAssignLeaderRange = self.followDoNotAssignLeaderRange;

	copy.followEnemyFlagCarriers = self.followEnemyFlagCarriers;
	copy.followFriendlyFlagCarriers = self.followFriendlyFlagCarriers;
	
	copy.resurrectWithSpiritHealer = self.resurrectWithSpiritHealer;
	copy.checkForCampers = self.checkForCampers;
	copy.checkForCampersRange = self.checkForCampersRange;
	copy.avoidMobsWhenResurrecting = self.avoidMobsWhenResurrecting;
	copy.moveToCorpseRange = self.moveToCorpseRange;
	copy.partyLeaderWait = self.partyLeaderWait;
	copy.partyLeaderWaitRange = self.partyLeaderWaitRange;
	
	copy.pvpQueueForRandomBattlegrounds = self.pvpQueueForRandomBattlegrounds;
	copy.pvpStopHonor = self.pvpStopHonor;
	copy.pvpStopHonorTotal = self.pvpStopHonorTotal;
	copy.pvpLeaveIfInactive = self.pvpLeaveIfInactive;
	copy.pvpDontMoveWithPreparation = self.pvpDontMoveWithPreparation;
	copy.pvpWaitToLeave = self.pvpWaitToLeave;
	copy.pvpWaitToLeaveTime = self.pvpWaitToLeaveTime;
	copy.pvpStayInWintergrasp = self.pvpStayInWintergrasp;

	copy.DoMining = self.DoMining;
	copy.MiningLevel = self.MiningLevel;
	copy.DoHerbalism = self.DoHerbalism;
	copy.HerbalismLevel = self.HerbalismLevel;
	copy.GatheringDistance = self.GatheringDistance;
	copy.DoNetherwingEggs = self.DoNetherwingEggs;
	copy.ShouldLoot = self.ShouldLoot;
	copy.DoSkinning = self.DoSkinning;
	copy.SkinningLevel = self.SkinningLevel;
	copy.DoNinjaSkin = self.DoNinjaSkin;
	copy.GatherUseCrystallized = self.GatherUseCrystallized;
	copy.GatherNodesHostilePlayerNear = self.GatherNodesHostilePlayerNear;
	copy.GatherNodesHostilePlayerNearRange = self.GatherNodesHostilePlayerNearRange;
	copy.GatherNodesFriendlyPlayerNear = self.GatherNodesFriendlyPlayerNear;
	copy.GatherNodesFriendlyPlayerNearRange = self.GatherNodesFriendlyPlayerNearRange;
	copy.GatherNodesMobNear = self.GatherNodesMobNear;
	copy.GatherNodesMobNearRange = self.GatherNodesMobNearRange;
	copy.DoFishing = self.DoFishing;
	copy.FishingApplyLure = self.FishingApplyLure;
	copy.FishingLureID = self.FishingLureID;
	copy.FishingUseContainers = self.FishingUseContainers;
	copy.FishingOnlySchools = self.FishingOnlySchools;
	copy.FishingRecast = self.FishingRecast;
	copy.FishingGatherDistance = self.FishingGatherDistance;
	
	copy.changed = YES;

    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if ( self ) {
        self.entries = [decoder decodeObjectForKey: @"IgnoreList"] ? [decoder decodeObjectForKey: @"IgnoreList"] : [NSArray array];

        self.combatEnabled = [[decoder decodeObjectForKey: @"CombatEnabled"] boolValue];
        self.onlyRespond = [[decoder decodeObjectForKey: @"OnlyRespond"] boolValue];
        self.attackNeutralNPCs = [[decoder decodeObjectForKey: @"AttackNeutralNPCs"] boolValue];
        self.attackHostileNPCs = [[decoder decodeObjectForKey: @"AttackHostileNPCs"] boolValue];
        self.attackPlayers = [[decoder decodeObjectForKey: @"AttackPlayers"] boolValue];
        self.attackPets = [[decoder decodeObjectForKey: @"AttackPets"] boolValue];
        self.attackAnyLevel = [[decoder decodeObjectForKey: @"AttackAnyLevel"] boolValue];
        self.ignoreElite = [[decoder decodeObjectForKey: @"IgnoreElite"] boolValue];
        self.ignoreLevelOne = [[decoder decodeObjectForKey: @"IgnoreLevelOne"] boolValue];
		self.ignoreFlying = [[decoder decodeObjectForKey: @"IgnoreFlying"] boolValue];
		
		self.assistUnit = [[decoder decodeObjectForKey: @"AssistUnit"] boolValue];
		self.assistUnitGUID = [[decoder decodeObjectForKey: @"AssistUnitGUID"] unsignedLongLongValue];
		self.tankUnit = [[decoder decodeObjectForKey: @"TankUnit"] boolValue];
		self.tankUnitGUID = [[decoder decodeObjectForKey: @"TankUnitGUID"] unsignedLongLongValue];
		self.followUnit = [[decoder decodeObjectForKey: @"FollowUnit"] boolValue];
		self.followUnitGUID = [[decoder decodeObjectForKey: @"FollowUnitGUID"] unsignedLongLongValue];
		self.partyEnabled = [[decoder decodeObjectForKey: @"PartyEnabled"] boolValue];
		self.followDistanceToMove = [[decoder decodeObjectForKey: @"FollowDistanceToMove"] floatValue];
		self.yardsBehindTargetStart = [[decoder decodeObjectForKey: @"YardsBehindTargetStart"] floatValue];
		self.yardsBehindTargetStop = [[decoder decodeObjectForKey: @"YardsBehindTargetStop"] floatValue];
		self.disableRelease = [[decoder decodeObjectForKey: @"DisableRelease"] boolValue];

		self.healingEnabled = [[decoder decodeObjectForKey: @"HealingEnabled"] boolValue];
        self.autoFollowTarget = [[decoder decodeObjectForKey: @"AutoFollowTarget"] boolValue];
		self.healingRange = [[decoder decodeObjectForKey: @"HealingRange"] floatValue];
		self.mountEnabled = [[decoder decodeObjectForKey: @"MountEnabled"] boolValue];
		
		self.engageRange = [[decoder decodeObjectForKey: @"EngageRange"] floatValue];
        self.attackRange = [[decoder decodeObjectForKey: @"AttackRange"] floatValue];
        self.attackLevelMin = [[decoder decodeObjectForKey: @"AttackLevelMin"] intValue];
        self.attackLevelMax = [[decoder decodeObjectForKey: @"AttackLevelMax"] intValue];

		// New additions
		self.partyDoNotInitiate = [[decoder decodeObjectForKey: @"PartyDoNotInitiate"] boolValue];
		self.partyIgnoreOtherFriendlies = [[decoder decodeObjectForKey: @"PartyIgnoreOtherFriendlies"] boolValue];
		self.partyEmotes = [[decoder decodeObjectForKey: @"PartyEmotes"] boolValue];
		self.partyEmotesIdleTime = [[decoder decodeObjectForKey: @"PartyEmotesIdleTime"] intValue];
		self.partyEmotesInterval = [[decoder decodeObjectForKey: @"PartyEmotesInterval"] intValue];
		self.followEnabled = [[decoder decodeObjectForKey: @"FollowEnabled"] boolValue];
		self.followStopFollowingOOR = [[decoder decodeObjectForKey: @"FollowStopFollowingOOR"] boolValue];
		self.followStopFollowingRange = [[decoder decodeObjectForKey: @"FollowStopFollowingRange"] floatValue];
		self.followDoNotAssignLeader = [[decoder decodeObjectForKey: @"FollowDoNotAssignLeader"] boolValue];
		self.followDoNotAssignLeaderRange = [[decoder decodeObjectForKey: @"FollowDoNotAssignLeaderRange"] floatValue];
		self.followEnemyFlagCarriers = [[decoder decodeObjectForKey: @"FollowEnemyFlagCarriers"] boolValue];
		self.followFriendlyFlagCarriers = [[decoder decodeObjectForKey: @"FollowFriendlyFlagCarriers"] boolValue];

		self.resurrectWithSpiritHealer = [[decoder decodeObjectForKey: @"ResurrectWithSpiritHealer"] boolValue];
		self.checkForCampers = [[decoder decodeObjectForKey: @"CheckForCampers"] boolValue];
		self.checkForCampersRange = [[decoder decodeObjectForKey: @"CheckForCampersRange"] floatValue];
		self.avoidMobsWhenResurrecting = [[decoder decodeObjectForKey: @"AvoidMobsWhenResurrecting"] boolValue];
		self.moveToCorpseRange = [[decoder decodeObjectForKey: @"MoveToCorpseRange"] floatValue];

		self.partyLeaderWait = [[decoder decodeObjectForKey: @"PartyLeaderWait"] boolValue];
		self.partyLeaderWaitRange = [[decoder decodeObjectForKey: @"PartyLeaderWaitRange"] floatValue];
		
		self.pvpQueueForRandomBattlegrounds = [[decoder decodeObjectForKey: @"PvpQueueForRandomBattlegrounds"] boolValue];
		self.pvpStopHonor = [[decoder decodeObjectForKey: @"PvpStopHonor"] boolValue];
		self.pvpStopHonorTotal = [[decoder decodeObjectForKey: @"PvpStopHonorTotal"] intValue];
		self.pvpLeaveIfInactive = [[decoder decodeObjectForKey: @"PvpLeaveIfInactive"] boolValue];
		self.pvpDontMoveWithPreparation = [[decoder decodeObjectForKey: @"PvpDontMoveWithPreparation"] boolValue];
		self.pvpWaitToLeave = [[decoder decodeObjectForKey: @"PvpWaitToLeave"] boolValue];
		self.pvpWaitToLeaveTime = [[decoder decodeObjectForKey: @"PvpWaitToLeaveTime"] floatValue];
		self.pvpStayInWintergrasp = [[decoder decodeObjectForKey: @"pvpStayInWintergrasp"] boolValue];
		
		self.DoMining = [[decoder decodeObjectForKey: @"DoMining"] boolValue];
		self.MiningLevel = [[decoder decodeObjectForKey: @"MiningLevel"] intValue];
		self.DoHerbalism = [[decoder decodeObjectForKey: @"DoHerbalism"] boolValue];
		self.HerbalismLevel = [[decoder decodeObjectForKey: @"HerbalismLevel"] intValue];
		self.GatheringDistance = [[decoder decodeObjectForKey: @"GatheringDistance"] floatValue];
		self.DoNetherwingEggs = [[decoder decodeObjectForKey: @"DoNetherwingEggs"] boolValue];
		self.ShouldLoot = [[decoder decodeObjectForKey: @"ShouldLoot"] boolValue];
		self.DoSkinning = [[decoder decodeObjectForKey: @"DoSkinning"] boolValue];
		self.SkinningLevel = [[decoder decodeObjectForKey: @"SkinningLevel"] intValue];
		self.DoNinjaSkin = [[decoder decodeObjectForKey: @"DoNinjaSkin"] boolValue];
		self.GatherUseCrystallized = [[decoder decodeObjectForKey: @"GatherUseCrystallized"] boolValue];
		self.GatherNodesHostilePlayerNear = [[decoder decodeObjectForKey: @"GatherNodesHostilePlayerNear"] boolValue];
		self.GatherNodesHostilePlayerNearRange = [[decoder decodeObjectForKey: @"GatherNodesHostilePlayerNearRange"] floatValue];
		self.GatherNodesFriendlyPlayerNear = [[decoder decodeObjectForKey: @"GatherNodesFriendlyPlayerNear"] boolValue];
		self.GatherNodesFriendlyPlayerNearRange = [[decoder decodeObjectForKey: @"GatherNodesFriendlyPlayerNearRange"] floatValue];
		self.GatherNodesMobNear = [[decoder decodeObjectForKey: @"GatherNodesMobNear"] boolValue];
		self.GatherNodesMobNearRange = [[decoder decodeObjectForKey: @"GatherNodesMobNearRange"] floatValue];
		self.DoFishing = [[decoder decodeObjectForKey: @"DoFishing"] boolValue];
		self.FishingApplyLure = [[decoder decodeObjectForKey: @"FishingApplyLure"] boolValue];
		self.FishingLureID = [[decoder decodeObjectForKey: @"FishingLureID"] intValue];
		self.FishingUseContainers = [[decoder decodeObjectForKey: @"FishingUseContainers"] boolValue];
		self.FishingOnlySchools = [[decoder decodeObjectForKey: @"FishingOnlySchools"] boolValue];
		self.FishingRecast = [[decoder decodeObjectForKey: @"FishingRecast"] boolValue];
		self.FishingGatherDistance = [[decoder decodeObjectForKey: @"FishingGatherDistance"] floatValue];
		
		[super initWithCoder:decoder];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
    [coder encodeObject: [NSNumber numberWithBool: self.combatEnabled] forKey: @"CombatEnabled"];
    [coder encodeObject: [NSNumber numberWithBool: self.onlyRespond] forKey: @"OnlyRespond"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackNeutralNPCs] forKey: @"AttackNeutralNPCs"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackHostileNPCs] forKey: @"AttackHostileNPCs"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackPlayers] forKey: @"AttackPlayers"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackPets] forKey: @"AttackPets"];
    [coder encodeObject: [NSNumber numberWithBool: self.attackAnyLevel] forKey: @"AttackAnyLevel"];
    [coder encodeObject: [NSNumber numberWithBool: self.ignoreElite] forKey: @"IgnoreElite"];
    [coder encodeObject: [NSNumber numberWithBool: self.ignoreLevelOne] forKey: @"IgnoreLevelOne"];
	[coder encodeObject: [NSNumber numberWithBool: self.ignoreFlying] forKey: @"IgnoreFlying"];
	
	[coder encodeObject: [NSNumber numberWithBool: self.assistUnit] forKey: @"AssistUnit"];
	[coder encodeObject: [NSNumber numberWithUnsignedLongLong: self.assistUnitGUID] forKey: @"AssistUnitGUID"];
	[coder encodeObject: [NSNumber numberWithBool: self.tankUnit] forKey: @"TankUnit"];
	[coder encodeObject: [NSNumber numberWithUnsignedLongLong: self.tankUnitGUID] forKey: @"TankUnitGUID"];
	[coder encodeObject: [NSNumber numberWithBool: self.followUnit] forKey: @"FollowUnit"];
	[coder encodeObject: [NSNumber numberWithUnsignedLongLong: self.followUnitGUID] forKey: @"FollowUnitGUID"];
	[coder encodeObject: [NSNumber numberWithBool: self.partyEnabled] forKey: @"PartyEnabled"];
	[coder encodeObject: [NSNumber numberWithFloat: self.followDistanceToMove] forKey: @"FollowDistanceToMove"];
	[coder encodeObject: [NSNumber numberWithFloat: self.yardsBehindTargetStart] forKey: @"YardsBehindTargetStart"];
	[coder encodeObject: [NSNumber numberWithFloat: self.yardsBehindTargetStop] forKey: @"YardsBehindTargetStop"];
	[coder encodeObject: [NSNumber numberWithBool: self.disableRelease] forKey: @"DisableRelease"];
	
	[coder encodeObject: [NSNumber numberWithBool: self.healingEnabled] forKey: @"HealingEnabled"];
    [coder encodeObject: [NSNumber numberWithBool: self.autoFollowTarget] forKey: @"AutoFollowTarget"];
	[coder encodeObject: [NSNumber numberWithFloat: self.healingRange] forKey: @"HealingRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.mountEnabled] forKey: @"MountEnabled"];
	
	[coder encodeObject: [NSNumber numberWithFloat: self.engageRange] forKey: @"EngageRange"];
    [coder encodeObject: [NSNumber numberWithFloat: self.attackRange] forKey: @"AttackRange"];
    [coder encodeObject: [NSNumber numberWithInt: self.attackLevelMin] forKey: @"AttackLevelMin"];
    [coder encodeObject: [NSNumber numberWithInt: self.attackLevelMax] forKey: @"AttackLevelMax"];

	// New additions
	[coder encodeObject: [NSNumber numberWithBool: self.partyDoNotInitiate] forKey: @"PartyDoNotInitiate"];
	[coder encodeObject: [NSNumber numberWithBool: self.partyIgnoreOtherFriendlies] forKey: @"PartyIgnoreOtherFriendlies"];
	[coder encodeObject: [NSNumber numberWithBool: self.partyEmotes] forKey:@"PartyEmotes"];
	[coder encodeObject: [NSNumber numberWithInt: self.partyEmotesIdleTime] forKey: @"PartyEmotesIdleTime"];
	[coder encodeObject: [NSNumber numberWithInt: self.partyEmotesInterval] forKey: @"PartyEmotesInterval"];
	[coder encodeObject: [NSNumber numberWithBool: self.followEnabled] forKey: @"FollowEnabled"];
	[coder encodeObject: [NSNumber numberWithBool: self.followStopFollowingOOR] forKey: @"FollowStopFollowingOOR"];
	[coder encodeObject: [NSNumber numberWithFloat: self.followStopFollowingRange] forKey: @"FollowStopFollowingRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.followDoNotAssignLeader] forKey: @"FollowDoNotAssignLeader"];
	[coder encodeObject: [NSNumber numberWithFloat: self.followDoNotAssignLeaderRange] forKey: @"FollowDoNotAssignLeaderRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.followEnemyFlagCarriers] forKey: @"FollowEnemyFlagCarriers"];
	[coder encodeObject: [NSNumber numberWithBool: self.followFriendlyFlagCarriers] forKey: @"FollowFriendlyFlagCarriers"];	
	[coder encodeObject: [NSNumber numberWithBool: self.resurrectWithSpiritHealer] forKey: @"ResurrectWithSpiritHealer"];
	[coder encodeObject: [NSNumber numberWithBool: self.checkForCampers] forKey: @"CheckForCampers"];
	[coder encodeObject: [NSNumber numberWithFloat: self.checkForCampersRange] forKey: @"CheckForCampersRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.avoidMobsWhenResurrecting] forKey: @"AvoidMobsWhenResurrecting"];
	[coder encodeObject: [NSNumber numberWithFloat: self.moveToCorpseRange] forKey: @"MoveToCorpseRange"];

	[coder encodeObject: [NSNumber numberWithBool: self.partyLeaderWait] forKey: @"PartyLeaderWait"];
	[coder encodeObject: [NSNumber numberWithFloat: self.partyLeaderWaitRange] forKey: @"PartyLeaderWaitRange"];

	[coder encodeObject: [NSNumber numberWithBool: self.pvpQueueForRandomBattlegrounds] forKey: @"PvpQueueForRandomBattlegrounds"];
	[coder encodeObject: [NSNumber numberWithBool: self.pvpStopHonor] forKey: @"PvpStopHonor"];
	[coder encodeObject: [NSNumber numberWithInt: self.pvpStopHonorTotal] forKey: @"PvpStopHonorTotal"];
	[coder encodeObject: [NSNumber numberWithBool: self.pvpLeaveIfInactive] forKey: @"PvpLeaveIfInactive"];
	[coder encodeObject: [NSNumber numberWithBool: self.pvpDontMoveWithPreparation] forKey: @"PvpDontMoveWithPreparation"];
	[coder encodeObject: [NSNumber numberWithBool: self.pvpWaitToLeave] forKey: @"PvpWaitToLeave"];
	[coder encodeObject: [NSNumber numberWithFloat: self.pvpWaitToLeaveTime] forKey: @"PvpWaitToLeaveTime"];
	[coder encodeObject: [NSNumber numberWithBool: self.pvpStayInWintergrasp] forKey: @"PvpStayInWintergrasp"];
	
	[coder encodeObject: [NSNumber numberWithBool: self.DoMining] forKey: @"DoMining"];
	[coder encodeObject: [NSNumber numberWithInt: self.MiningLevel] forKey: @"MiningLevel"];
	[coder encodeObject: [NSNumber numberWithBool: self.DoHerbalism] forKey: @"DoHerbalism"];
	[coder encodeObject: [NSNumber numberWithInt: self.HerbalismLevel] forKey: @"HerbalismLevel"];
	[coder encodeObject: [NSNumber numberWithFloat: self.GatheringDistance] forKey: @"GatheringDistance"];
	[coder encodeObject: [NSNumber numberWithBool: self.DoNetherwingEggs] forKey: @"DoNetherwingEggs"];
	[coder encodeObject: [NSNumber numberWithBool: self.ShouldLoot] forKey: @"ShouldLoot"];
	[coder encodeObject: [NSNumber numberWithBool: self.DoSkinning] forKey: @"DoSkinning"];
	[coder encodeObject: [NSNumber numberWithInt: self.SkinningLevel] forKey: @"SkinningLevel"];
	[coder encodeObject: [NSNumber numberWithBool: self.DoNinjaSkin] forKey: @"DoNinjaSkin"];
	[coder encodeObject: [NSNumber numberWithBool: self.GatherUseCrystallized] forKey: @"GatherUseCrystallized"];
	[coder encodeObject: [NSNumber numberWithBool: self.GatherNodesHostilePlayerNear] forKey: @"GatherNodesHostilePlayerNear"];
	[coder encodeObject: [NSNumber numberWithFloat: self.GatherNodesHostilePlayerNearRange] forKey: @"GatherNodesHostilePlayerNearRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.GatherNodesFriendlyPlayerNear] forKey: @"GatherNodesFriendlyPlayerNear"];
	[coder encodeObject: [NSNumber numberWithFloat: self.GatherNodesFriendlyPlayerNearRange] forKey: @"GatherNodesFriendlyPlayerNearRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.GatherNodesMobNear] forKey: @"GatherNodesMobNear"];
	[coder encodeObject: [NSNumber numberWithFloat: self.GatherNodesMobNearRange] forKey: @"GatherNodesMobNearRange"];
	[coder encodeObject: [NSNumber numberWithBool: self.DoFishing] forKey: @"DoFishing"];
	[coder encodeObject: [NSNumber numberWithBool: self.FishingApplyLure] forKey: @"FishingApplyLure"];
	[coder encodeObject: [NSNumber numberWithInt: self.FishingLureID] forKey: @"FishingLureID"];
	[coder encodeObject: [NSNumber numberWithBool: self.FishingUseContainers] forKey: @"FishingUseContainers"];
	[coder encodeObject: [NSNumber numberWithBool: self.FishingOnlySchools] forKey: @"FishingOnlySchools"];
	[coder encodeObject: [NSNumber numberWithBool: self.FishingRecast] forKey: @"FishingRecast"];
	[coder encodeObject: [NSNumber numberWithFloat: self.FishingGatherDistance] forKey: @"FishingGatherDistance"];
	
    [coder encodeObject: self.entries forKey: @"IgnoreList"];
}

- (void) dealloc
{
    self.name = nil;
    self.entries = nil;
    [super dealloc];
}

@synthesize name = _name;
@synthesize entries = _combatEntries;
@synthesize combatEnabled;
@synthesize onlyRespond;
@synthesize attackNeutralNPCs;
@synthesize attackHostileNPCs;
@synthesize attackPlayers;
@synthesize attackPets;
@synthesize attackAnyLevel;
@synthesize ignoreElite;
@synthesize ignoreLevelOne;
@synthesize ignoreFlying;

@synthesize assistUnit;
@synthesize assistUnitGUID;
@synthesize tankUnit;
@synthesize tankUnitGUID;
@synthesize followUnit;
@synthesize followUnitGUID;
@synthesize partyEnabled;
@synthesize followDistanceToMove;
@synthesize yardsBehindTargetStart;
@synthesize yardsBehindTargetStop;

@synthesize healingEnabled;
@synthesize autoFollowTarget;
@synthesize healingRange;
@synthesize mountEnabled;
@synthesize disableRelease;

@synthesize engageRange;
@synthesize attackRange;
@synthesize attackLevelMin;
@synthesize attackLevelMax;

// New additions
@synthesize partyDoNotInitiate;
@synthesize partyIgnoreOtherFriendlies;
@synthesize partyEmotes;
@synthesize partyEmotesIdleTime;
@synthesize partyEmotesInterval;
@synthesize followEnabled;
@synthesize followStopFollowingOOR;
@synthesize followStopFollowingRange;
@synthesize followDoNotAssignLeader;
@synthesize followDoNotAssignLeaderRange;

@synthesize followFriendlyFlagCarriers;
@synthesize followEnemyFlagCarriers;

@synthesize resurrectWithSpiritHealer;
@synthesize checkForCampers;
@synthesize checkForCampersRange;
@synthesize avoidMobsWhenResurrecting;
@synthesize moveToCorpseRange;
@synthesize partyLeaderWait;
@synthesize partyLeaderWaitRange;

@synthesize pvpQueueForRandomBattlegrounds;
@synthesize pvpStopHonor;
@synthesize pvpStopHonorTotal;
@synthesize pvpLeaveIfInactive;
@synthesize pvpDontMoveWithPreparation;
@synthesize pvpWaitToLeave;
@synthesize pvpWaitToLeaveTime;
@synthesize pvpStayInWintergrasp;

@synthesize DoMining;
@synthesize MiningLevel;
@synthesize DoHerbalism;
@synthesize HerbalismLevel;
@synthesize GatheringDistance;
@synthesize DoNetherwingEggs;
@synthesize ShouldLoot;
@synthesize DoSkinning;
@synthesize SkinningLevel;
@synthesize DoNinjaSkin;
@synthesize GatherUseCrystallized;
@synthesize GatherNodesHostilePlayerNear;
@synthesize GatherNodesHostilePlayerNearRange;
@synthesize GatherNodesFriendlyPlayerNear;
@synthesize GatherNodesFriendlyPlayerNearRange;
@synthesize GatherNodesMobNear;
@synthesize GatherNodesMobNearRange;
@synthesize DoFishing;
@synthesize FishingApplyLure;
@synthesize FishingLureID;
@synthesize FishingUseContainers;
@synthesize FishingOnlySchools;
@synthesize FishingRecast;
@synthesize FishingGatherDistance;


- (BOOL)unitShouldBeIgnored: (Unit*)unit{
	
	// check our internal blacklist
    for ( IgnoreEntry *entry in [self entries] ) {
        if( [entry type] == IgnoreType_EntryID) {
            if( [[entry ignoreValue] intValue] == [unit entryID])
                return YES;
        }
        if( [entry type] == IgnoreType_Name) {
            if(![entry ignoreValue] || ![[entry ignoreValue] length] || ![unit name])
                continue;
			
            NSRange range = [[unit name] rangeOfString: [entry ignoreValue] 
                                               options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            if(range.location != NSNotFound) {
                return YES;
            }
        }
    }
	
	return NO;
}

- (void)setEntries: (NSArray*)newEntries {
    [self willChangeValueForKey: @"entries"];
    [_combatEntries autorelease];
    if(newEntries) {
        _combatEntries = [[NSMutableArray alloc] initWithArray: newEntries copyItems: YES];
    } else {
        _combatEntries = nil;
    }
	self.changed = YES;
    [self didChangeValueForKey: @"entries"];
}

- (unsigned)entryCount {
    return [self.entries count];
}

- (IgnoreEntry*)entryAtIndex: (unsigned)index {
    if(index >= 0 && index < [self entryCount])
        return [[[_combatEntries objectAtIndex: index] retain] autorelease];
    return nil;
}

- (void)addEntry: (IgnoreEntry*)entry {
    if(entry != nil){
        [_combatEntries addObject: entry];
		self.changed = YES;
	}
}

- (void)removeEntry: (IgnoreEntry*)entry {
    if(entry == nil) return;
    [_combatEntries removeObject: entry];
	self.changed = YES;
}

- (void)removeEntryAtIndex: (unsigned)index; {
    if(index >= 0 && index < [self entryCount]){
        [_combatEntries removeObjectAtIndex: index];
		self.changed = YES;
	}
}

@end
