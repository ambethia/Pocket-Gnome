/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import "BotController.h"
#import "Controller.h"
#import "ChatController.h"
#import "PlayerDataController.h"
#import "MobController.h"
#import "SpellController.h"
#import "NodeController.h"
#import "CombatController.h"
#import "MovementController.h"
#import "AuraController.h"
#import "WaypointController.h"
#import "ProcedureController.h"
#import "InventoryController.h"
#import "PlayersController.h"
#import "QuestController.h"
#import "CorpseController.h"
#import "LootController.h"
#import "ChatLogController.h"
#import "FishController.h"
#import "MacroController.h"
#import "OffsetController.h"
#import "MemoryViewController.h"
#import "EventController.h"
#import "BlacklistController.h"
#import "StatisticsController.h"
#import "BindingsController.h"
#import "PvPController.h"
#import "ProfileController.h"

#import "ChatLogEntry.h"
#import "BetterSegmentedControl.h"
#import "Behavior.h"
#import "RouteCollection.h"
#import "RouteSet.h"
#import "Route.h"
#import "Condition.h"
#import "Mob.h"
#import "Unit.h"
#import "Player.h"
#import "Item.h"
#import "Offsets.h"
#import "PTHeader.h"
#import "CGSPrivate.h"
#import "Macro.h"
#import "CombatProfile.h"
#import "Errors.h"
#import "PvPBehavior.h"
#import "Battleground.h"

#import "ScanGridView.h"
#import "TransparentWindow.h"
#import "DatabaseManager.h"

#import <Growl/GrowlApplicationBridge.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <ScreenSaver/ScreenSaver.h>

#define DeserterSpellID		26013
#define HonorlessTargetSpellID	2479 
#define HonorlessTarget2SpellID 46705
#define IdleSpellID		43680
#define InactiveSpellID		43681
#define PreparationSpellID	44521
#define WaitingToRezSpellID	2584
#define HearthstoneItemID		6948
#define HearthStoneSpellID		8690

#define RefreshmentTableID		193061	// "Refreshment Table"
#define SoulwellID				193169	// "Soulwell"


// For strand of the ancients
#define StrandFlagpole					191311
#define StrandAllianceBanner			191310
#define StrandAllianceBannerAura		180100
#define StrandHordeBanner				191307
#define StrandeHordeBannerAura			180101
#define StrandAntipersonnelCannon		27894
#define StrandBattlegroundDemolisher	28781
#define StrandPrivateerZierhut			32658		// right boat
#define StrandPrivateerStonemantle		32657		// left boat

@interface BotController ()

@property (readwrite, retain) Behavior *theBehavior;
@property (readwrite, retain) Behavior *theBehaviorPvP;
@property (readwrite, retain) PvPBehavior *pvpBehavior;
@property (readwrite, retain) NSDate *lootStartTime;
@property (readwrite, retain) NSDate *skinStartTime;

@property (readwrite, retain) NSDate *startDate;
@property (readwrite, retain) Mob *mobToSkin;
@property (readwrite, retain) Mob *mobJustSkinned;
@property (readwrite, retain) WoWObject *unitToLoot;
@property (readwrite, retain) WoWObject *lastAttemptedUnitToLoot;
@property (readwrite, retain) Unit *preCombatUnit;
// @property (readwrite, retain) Unit *castingUnit;
@property (readwrite, retain) Unit *followUnit;
@property (readwrite, retain) Unit *assistUnit;
@property (readwrite, retain) Unit *tankUnit;

// @property (readwrite, retain) RouteCollection *theRouteCollection;
// @property (readwrite, retain) RouteCollection *theRouteCollectionPvP;
// @property (readwrite, retain) RouteCollection *theRouteSet;
// @property (readwrite, retain) RouteCollection *theRouteSetPvP;

@property (readwrite, retain) Route *followRoute;

// pvp
@property (readwrite, assign) BOOL pvpPlayWarning;

// @property (readwrite, assign) BOOL doLooting;
// @property (readwrite, assign) float gatherDistance;

@property (readwrite, assign) BOOL useRoute;
@property (readwrite, assign) BOOL useRoutePvP;

// @property (readwrite, assign) BOOL evaluationIsActive;

@end

@interface BotController (Internal)

- (void)timeUp: (id)sender;

- (void)preRegen;
- (void)evaluateRegen: (NSDictionary*)regenDict;

- (void)performProcedureWithState: (NSDictionary*)state;
- (void)playerHasDied: (NSNotification*)notification;

// pvp
- (void)pvpGetBGInfo;
- (void)pvpMonitor: (NSTimer*)timer;
- (void)corpseRelease: (NSNumber *)count;

- (void)followMonitor: (NSTimer*)timer;

- (void)skinMob: (Mob*)mob;
- (void)skinToFinish;
- (BOOL)unitValidToHeal: (Unit*)unit;
- (void)lootNode: (WoWObject*) unit;
- (void)resetLootScanTimer;

- (BOOL)mountNow;

- (BOOL)scaryUnitsNearNode: (WoWObject*)node doMob:(BOOL)doMobCheck doFriendy:(BOOL)doFriendlyCheck doHostile:(BOOL)doHostileCheck;

- (BOOL)combatProcedureValidForUnit: (Unit*)unit;

- (void)executeRegen: (BOOL)delay;

- (NSString*)isRouteSetSound: (RouteSet*)route;

// new pvp
- (void)pvpQueueOrStart;
- (BOOL)pvpQueueBattleground;
- (BOOL)pvpSetEnvironmentForZone;

@end

@implementation BotController

+ (void)initialize {
    
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:NO],		@"UseRoutePvP",
								   [NSNumber numberWithBool:YES],		@"UseRoute",
								   [NSNumber numberWithBool: YES],	@"AttackAnyLevel",
								   [NSNumber numberWithFloat: 50.0],	@"GatheringDistance",
								   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoJoin",
								   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoQueue",
								   [NSNumber numberWithInt: NSOnState], @"PvPAddonAutoRelease",
								   [NSNumber numberWithInt: NSOnState], @"PvPPlayWarningSound",
								   [NSNumber numberWithInt: NSOnState], @"PvPLeaveWhenInactive",
								   [NSNumber numberWithInt:0],			@"MovementType",
								   [NSNumber numberWithInt: NSOffState],@"DoLogOutCheck",
								   [NSNumber numberWithInt:20],		    @"LogOutOnBrokenItemsPercentage",
								   [NSNumber numberWithBool:NO],		@"DisableReleasingOnDeath",
								   nil];

    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
}

- (id)init {
	self = [super init];
    if (self == nil) return self;
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasRevived:) name: PlayerHasRevivedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerIsInvalid:) name: PlayerIsInvalidNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(auraGain:) name: BuffGainNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(auraFade:) name: BuffFadeNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(itemsLooted:) name: AllItemsLootedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(itemLooted:) name: ItemLootedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(whisperReceived:) name: WhisperReceived object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(eventZoneChanged:) name: EventZoneChanged object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(eventBattlegroundStatusChange:) name: EventBattlegroundStatusChange object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(unitDied:) name: UnitDiedNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(invalidTarget:) name: ErrorInvalidTarget object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(haveNoTarget:) name: ErrorHaveNoTarget object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetNotInLOS:) name: ErrorTargetNotInLOS object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(morePowerfullSpellActive:) name: ErrorMorePowerfullSpellActive object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cantDoThatWhileStunned:) name: ErrorCantDoThatWhileStunned object: nil];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(unitEnteredCombat:) name: UnitEnteredCombat object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachedObject:) name: ReachedObjectNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachedFollowUnit:) name: ReachedFollowUnitNotification object: nil];

	_sleepTimer = 0;
	_theRouteCollection = nil;
	_theRouteCollectionPvP = nil;
	_theRouteSet = nil;
	_theRouteSetPvP = nil;
	_useRoute = NO;
	_useRoutePvP = NO;
	_pvpBehavior = nil;
	_procedureInProgress = nil;
	_evaluationInProgress = nil;

	_evaluationIsActive = NO;

	_lastProcedureExecuted = nil;
	_didPreCombatProcedure = NO;
	_lastSpellCastGameTime = 0;
	self.startDate = nil;
	_unitToLoot = nil;
	_mobToSkin = nil;
	_mobJustSkinned = nil;
	_wasLootWindowOpen = NO;
	_shouldFollow = YES;
	_lastUnitAttemptedToHealed = nil;
	_pvpIsInBG = NO;
	self.lootStartTime = nil;
	self.skinStartTime = nil;
	_lootMacroAttempt = 0;
	_zoneBeforeHearth = -1;
	_attackingInStrand = NO;
	_strandDelay = NO;
	_strandDelayTimer = 0;
	_waitingToLeaveBattleground = NO;
	_waitForPvPQueue = NO;
	_needToTakeQueue = NO;
	_waitForPvPPreparation = NO;
	_isPvpMonitoring = NO;

	_jumpAttempt = 0;
	_includeFriendly = NO;
	_includeFriendlyPatrol = NO;
	_includeCorpsesPatrol = NO;
	_lastSpellCast = 0;
	_mountAttempt = 0;
	_movingTowardMobCount = 0;
	_movingTowardNodeCount = 0;
	_lootDismountCount = [[NSMutableDictionary dictionary] retain];
	_mountLastAttempt = nil;
	_castingUnit = nil;
	_followUnit	= nil;
	_assistUnit	= nil;
	_tankUnit = nil;

	_followRoute = [[Route route] retain];
	_followingFlagCarrier = NO;
	_followSuspended = NO;
	_followLastSeenPosition = NO;
	_leaderBeenWaiting = NO;
	
	_lastCombatProcedureTarget = 0x0;
	_lootScanIdleTimer = 0;
//	_lootScanCycles = 0;

	_partyEmoteIdleTimer = 0;
	_partyEmoteTimeSince = 0;
	_lastEmote = nil;
	_lastEmoteShuffled = 0;
	
	_routesChecked = [[NSMutableArray array] retain];
	_mobsToLoot = [[NSMutableArray array] retain];
	
	// wipe pvp options
	self.isPvPing = NO;
	self.pvpPlayWarning = NO;
	
	// anti afk
	_lastPressedWasForward = NO;
	_afkTimerCounter = 0;
	
	// wg stuff
	_lastNumWGMarks = 0;
	_dateWGEnded = nil;
	
	_logOutTimer = nil;

	_movingToCorpse = NO;

	// Every 30 seconds for an anti-afk
	_afkTimer = [NSTimer scheduledTimerWithTimeInterval: 30.0f target: self selector: @selector(afkTimer:) userInfo: nil repeats: YES];
	
	
	[NSBundle loadNibNamed: @"Bot" owner: self];
	
	return self;
}

- (void)dealloc {
//	[_theRouteCollection release]; _theRouteCollection = nil;
//	[_theRouteCollectionPvP release]; _theRouteCollectionPvP = nil;
//	[_theRouteSet release]; _theRouteSet = nil;
//	[_theRouteSetPvP release]; _theRouteSetPvP = nil;
	[_followRoute release];
	[_followUnit release];
	[_castingUnit release];
	[_tankUnit release];
	[_assistUnit release];
	[_lootDismountCount release];
	[_routesChecked release];
	[_mobsToLoot release];

	[super dealloc];
}

- (void)awakeFromNib {
	self.minSectionSize = [self.view frame].size;
	self.maxSectionSize = [self.view frame].size;
    
	[startstopRecorder setCanCaptureGlobalHotKeys: YES];
	
	// remove old key bindings
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HotkeyCode"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HotkeyFlags"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PetAttackCode"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PetAttackFlags"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MouseOverTargetCode"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MouseOverTargetFlags"];
	
    KeyCombo combo2 = { NSCommandKeyMask, kSRKeysEscape };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopCode"])
		combo2.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopFlags"])
		combo2.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"StartstopFlags"] intValue];
	
    [startstopRecorder setDelegate: self];
    [startstopRecorder setKeyCombo: combo2];
	
    // set up overlay window
    [overlayWindow setLevel: NSFloatingWindowLevel];
    if([overlayWindow respondsToSelector: @selector(setCollectionBehavior:)])
		[overlayWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
	
	//routePvPPopup
    
	// auto select if we need to
	if ( [[NSUserDefaults standardUserDefaults] objectForKey: @"RoutePvP"] == nil ) 
		if ( [[pvpController behaviors] count] ) [routePvPPopup selectItemAtIndex:0];

    [self updateStatus: nil];
}

@synthesize theRouteCollection = _theRouteCollection;
@synthesize theRouteCollectionPvP = _theRouteCollectionPvP;
@synthesize theRouteSet = _theRouteSet;
@synthesize theRouteSetPvP = _theRouteSetPvP;
@synthesize theBehavior;
@synthesize theBehaviorPvP;
@synthesize pvpBehavior = _pvpBehavior;
@synthesize theCombatProfile;
@synthesize evaluationIsActive = _evaluationIsActive;
@synthesize lootStartTime;
@synthesize skinStartTime;

@synthesize logOutAfterStuckCheckbox;
@synthesize view;
@synthesize isBotting = _isBotting;
@synthesize isPvPing = _isPvPing;
@synthesize procedureInProgress = _procedureInProgress;
@synthesize evaluationInProgress = _evaluationInProgress;
@synthesize mobToSkin = _mobToSkin;
@synthesize mobJustSkinned = _mobJustSkinned;
@synthesize unitToLoot = _unitToLoot;
@synthesize wasLootWindowOpen = _wasLootWindowOpen;
@synthesize lastAttemptedUnitToLoot = _lastAttemptedUnitToLoot;
@synthesize minSectionSize;
@synthesize maxSectionSize;
@synthesize preCombatUnit;
@synthesize castingUnit = _castingUnit;
@synthesize followUnit = _followUnit;
@synthesize assistUnit = _assistUnit;
@synthesize tankUnit = _tankUnit;
@synthesize pvpPlayWarning = _pvpPlayWarning;
@synthesize pvpIsInBG = _pvpIsInBG;
@synthesize waitForPvPQueue = _waitForPvPQueue;
@synthesize waitForPvPPreparation = _waitForPvPPreparation;
@synthesize needToTakeQueue = _needToTakeQueue;
@synthesize startDate;
@synthesize followSuspended  = _followSuspended;
@synthesize followRoute = _followRoute;

@synthesize useRoute = _useRoute;
@synthesize useRoutePvP = _useRoutePvP;

@synthesize includeCorpsesPatrol = _includeCorpsesPatrol;
@synthesize movingToCorpse = _movingToCorpse;
@synthesize mobsToLoot = _mobsToLoot;

- (NSString*)sectionTitle {
	return @"Start/Stop Bot";
}

#pragma mark -

int DistanceFromPositionCompare(id <UnitPosition> unit1, id <UnitPosition> unit2, void *context) {
	Position *position = (Position*)context; 
	float d1 = [position distanceToPosition: [unit1 position]];
	float d2 = [position distanceToPosition: [unit2 position]];
	if (d1 < d2) return NSOrderedAscending;
	else if (d1 > d2) return NSOrderedDescending;
	else return NSOrderedSame;
}

#pragma mark -

#define RULE_EVAL_DELAY_SHORT	0.25f
#define RULE_EVAL_DELAY_NORMAL	0.5f
#define RULE_EVAL_DELAY_LONG	0.5f

- (void)testRule: (Rule*)rule {
	Unit *unit = [mobController playerTarget];
	if(!unit) unit = [playersController playerTarget];
	log(LOG_RULE, @"Testing rule with target: %@", unit);
	BOOL result = [self evaluateRule: rule withTarget: unit asTest: YES];
	NSRunAlertPanel(TRUE_FALSE(result), [NSString stringWithFormat: @"%@", rule], @"Okay", NULL, NULL);
}

- (BOOL)evaluateRule: (Rule*)rule withTarget: (Unit*)target asTest: (BOOL)test {

	// Determine whether or not the given target should have a rule applied
    int numMatched = 0, needToMatch = 0;
    if ([rule isMatchAll]) for(Condition *condition in [rule conditions]) if ( [condition enabled]) needToMatch++;

    if (needToMatch == 0) needToMatch = 1;

	Player *thePlayer = [playerController player];

	// target checks
	if ( [rule target] != TargetNone ){

		if ( ([rule target] == TargetFriend || [rule target] == TargetFriendlies || [rule target] == TargetPet ) && ![playerController isFriendlyWithFaction: [target factionTemplate]] ){
			log(LOG_RULE, @"%@ isn't friendly!", target);
			return NO;
		}

		if ( ([rule target] == TargetEnemy || [rule target] == TargetAdd || [rule target] == TargetPat) && [playerController isFriendlyWithFaction: [target factionTemplate]] ){
			log(LOG_RULE, @"@% isn't an enemy!", target);
			return NO;
		}

		// set the correct target if it's self
		if ( [rule target] == TargetSelf ) {
			target = thePlayer;
		}
	}

	// check to see if we can even cast this spell
	if ( [[rule action] type] == ActionType_Spell && ![spellController isUsableAction:[[rule action] actionID]] ){
		log(LOG_RULE, @"Action %d isn't usable!", [[rule action] actionID]);
		return NO;
	}

	// check to see if the spell is on cooldown, obviously the rule will fail!
	if ( [[rule action] type] == ActionType_Spell && [spellController isSpellOnCooldown:[[rule action] actionID]] ){
		log(LOG_RULE, @"%@ Spell is on cooldown.", rule);
		return NO;
	}

	Unit *aUnit = nil;
	
    for ( Condition *condition in [rule conditions] ) {
		if (![condition enabled]) continue;
		BOOL conditionEval = NO;
		if ([condition unit] == UnitTarget && !target) goto loopEnd;
		if ([condition unit] == UnitFriendlies && !target) goto loopEnd;
		if ([condition unit] == UnitNone && 
			[condition variety] != VarietySpellCooldown && 
			[condition variety] != VarietyLastSpellCast && 
			[condition variety] != VarietyPlayerLevel && 
			[condition variety] != VarietyPlayerZone && 
			[condition variety] != VarietyQuest && 
			[condition variety] != VarietyRouteRunCount && 
			[condition variety] != VarietyRouteRunTime && 
			[condition variety] != VarietyInventoryFree && 
			[condition variety] != VarietyDurability &&
			[condition variety] != VarietyMobsKilled && 
			[condition variety] != VarietyGate && 
			[condition variety] != VarietyStrandStatus) 
			goto loopEnd;

		switch ([condition variety]) {
			case VarietyNone:;
				log(LOG_ERROR, @"%@ in %@ is of an unknown type.", condition, rule);
				break;

			case VarietyPower:;
				log(LOG_CONDITION, @"Doing Health/Power condition...");	
				
				NSArray *units = [NSArray array];
				// testing against multiple units
				if ( [condition unit] == UnitFriendlies || [condition unit] == UnitEnemies ){
					if ( [condition unit] == UnitFriendlies )	units = [combatController friendlyUnits];
					if ( [condition unit] == UnitEnemies )		units = [combatController allAdds];
				}
				// looking at one unit!
				else{
					if ( [condition unit] == UnitPlayer ){
						if( ![playerController playerIsValid:self] || ![thePlayer isValid]) goto loopEnd;
						units = [NSArray arrayWithObject:thePlayer];
					}
					else if ( [condition unit] == UnitTarget ){
						units = [NSArray arrayWithObject:target];
					}
					else if ( [condition unit] == UnitPlayerPet ){
						units = [NSArray arrayWithObject:[playerController pet]];
					}
					else{
						PGLog(@"[Condition] Unable to identify a target for VarietyPower");
						goto loopEnd;
					}
				}
				
				// loop through targets
				for ( target in units ) {
					if ( ![target isValid] ) continue;
					int qualityValue = [target unitPowerWithQuality:[condition quality] andType:[condition type]];
					
					// now we have the value of the quality
					if( [condition comparator] == CompareMore) {
						conditionEval = ( qualityValue > [[condition value] unsignedIntValue] ) ? YES : NO;
						log(LOG_CONDITION, @"	%d > %@ is %d", qualityValue, [condition value], conditionEval);
					} else if ([condition comparator] == CompareEqual) {
						conditionEval = ( qualityValue == [[condition value] unsignedIntValue] ) ? YES : NO;
						log(LOG_CONDITION, @"	%d = %@ is %d", qualityValue, [condition value], conditionEval);
					} else if ([condition comparator] == CompareLess) {
						conditionEval = ( qualityValue < [[condition value] unsignedIntValue] ) ? YES : NO;
						log(LOG_CONDITION, @"	%d > %@ is %d", qualityValue, [condition value], conditionEval);
					} else goto loopEnd;
					break;
				}
				break;
				
			case VarietyStatus:;
				log(LOG_CONDITION, @"Doing Status condition...");	
				// check alive status
				if( [condition state] == StateAlive ) {
					if( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? ![playerController isDead] : [playerController isDead];
					else if( [condition unit] == UnitTarget ) conditionEval = ( [condition comparator] == CompareIs ) ? ![target isDead] : [target isDead];
				    else if( [condition unit] == UnitFriendlies ) conditionEval = [self  evaluateConditionFriendlies:condition];
					else if( [condition unit] == UnitEnemies ) conditionEval = [self  evaluateConditionEnemies:condition];
					else if( [condition unit] == UnitPlayerPet) {
						if (playerController.pet == nil) conditionEval = ([condition comparator] == CompareIs) ? NO : YES;
						else conditionEval = ( [condition comparator] == CompareIs ) ? ![playerController.pet isDead] : [playerController.pet isDead];
					} else goto loopEnd;
					log(LOG_CONDITION, @"	Alive? %d", conditionEval);
				}
				
				// check combat status
				if( [condition state] == StateCombat ) {
					if( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? [combatController inCombat] : ![combatController inCombat];
					else if( [condition unit] == UnitTarget ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isInCombat] : ![target isInCombat];
				    else if( [condition unit] == UnitFriendlies ) conditionEval = [self  evaluateConditionFriendlies:condition];
					else if( [condition unit] == UnitEnemies ) conditionEval = [self  evaluateConditionEnemies:condition];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isInCombat] : ![playerController.pet isInCombat];
					else goto loopEnd;
					log(LOG_CONDITION, @"	Combat? %d", conditionEval);
				}
				
				// check casting status
				if( [condition state] == StateCasting ) {
					if( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController isCasting] : ![playerController isCasting];
					else if( [condition unit] == UnitTarget ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isCasting] : ![target isCasting];
				    else if( [condition unit] == UnitFriendlies ) conditionEval = [self  evaluateConditionFriendlies:condition];
					else if( [condition unit] == UnitEnemies ) conditionEval = [self  evaluateConditionEnemies:condition];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isCasting] : ![playerController.pet isCasting];
					goto loopEnd;
					log(LOG_CONDITION, @"	Casting? %d", conditionEval);
				}

				// check swimming status
				if( [condition state] == StateSwimming ) {
					if ( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? [[playerController player]isSwimming] : ![[playerController player]isSwimming];
					else if( [condition unit] == UnitTarget ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isSwimming] : ![target isSwimming];
				    else if( [condition unit] == UnitFriendlies ) conditionEval = [self  evaluateConditionFriendlies:condition];
					else if( [condition unit] == UnitEnemies ) conditionEval = [self  evaluateConditionEnemies:condition];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isSwimming] : ![playerController.pet isSwimming];
					goto loopEnd;
					log(LOG_CONDITION, @"	Swimming? %d", conditionEval);
				}

				// check targeting me status
				if( [condition state] == StateTargetingMe ) {
					if ( [condition unit] == UnitPlayer) conditionEval = ( [condition comparator] == CompareIs ) ? [[playerController player] isTargetingMe] : ![[playerController player] isTargetingMe];
					else if( [condition unit] == UnitTarget ) conditionEval = ( [condition comparator] == CompareIs ) ? [target isTargetingMe] : ![target isTargetingMe];
				    else if( [condition unit] == UnitFriendlies ) conditionEval = [self  evaluateConditionFriendlies:condition];
					else if( [condition unit] == UnitEnemies ) conditionEval = [self  evaluateConditionEnemies:condition];
					else if( [condition unit] == UnitPlayerPet) conditionEval = ( [condition comparator] == CompareIs ) ? [playerController.pet isTargetingMe] : ![playerController.pet isTargetingMe];
					goto loopEnd;

					log(LOG_CONDITION, @"	Targeting me? %d", conditionEval);
				}

				// check tank status
				if( [condition state] == StateTank ) {
					if ( [condition unit] == UnitTarget ) conditionEval = ( [condition comparator] == CompareIs ) ? [self isTank: (Unit*)target] : ![self isTank: (Unit*)target];
					else if( [condition unit] == UnitFriendlies ) conditionEval = [self  evaluateConditionFriendlies:condition];

					goto loopEnd;

					log(LOG_CONDITION, @"	Tank? %d", conditionEval);
				}

				// IS THE UNIT MOUNTED?
				if( [condition state] == StateMounted ) {
					if (test) log(LOG_CONDITION, @"Doing State IsMounted condition...");
					if( [condition unit] == UnitFriendlies ) {
						conditionEval = [self  evaluateConditionFriendlies:condition];
					} else 
					if( [condition unit] == UnitEnemies ) {
						conditionEval = [self  evaluateConditionEnemies:condition];
					} else {
						Unit *aUnit = nil;
						if( [condition unit] == UnitPlayer)		aUnit = thePlayer;
						else if( [condition unit] == UnitTarget || [condition unit] == UnitFriendlies )	   aUnit = target;
						else if( [condition unit] == UnitPlayerPet) aUnit = playerController.pet;
						if (test) log(LOG_CONDITION, @" --> Testing unit %@", aUnit);
					
						if ([aUnit isValid]) {
							conditionEval = ( [condition comparator] == CompareIs ) ? [aUnit isMounted] : ![aUnit isMounted];
							if (test) log(LOG_CONDITION, @" --> Unit is mounted? %@", YES_NO(conditionEval));
						} else {
							if (test) log(LOG_CONDITION, @" --> Unit is invalid.");
						}
					}
				}
	
				break;
				
			case VarietyAura:;
				log(LOG_CONDITION, @"-- Checking aura condition --");
				unsigned spellID = 0;
				NSString *dispelType = nil;
				BOOL doDispelCheck = ([condition quality] == QualityBuffType) || ([condition quality] == QualityDebuffType);
				// sanity checks
				if(!doDispelCheck) {
					if( [condition type] == TypeValue) spellID = [[condition value] unsignedIntValue];
					
					if( ([condition type] == TypeValue) && !spellID) {
						// invalid spell ID
						goto loopEnd;
					} else if( [condition type] == TypeString && (![condition value] || ![[condition value] length])) {
						// invalid spell name
						goto loopEnd;
					}
				} else {
					if( ([condition state] < StateMagic) || ([condition state] > StatePoison)) {
						// invalid dispel type
						goto loopEnd;
					} else {
						if([condition state] == StateMagic)	dispelType = DispelTypeMagic;
						if([condition state] == StateCurse)	dispelType = DispelTypeCurse;
						if([condition state] == StatePoison)	dispelType = DispelTypePoison;
						if([condition state] == StateDisease)	dispelType = DispelTypeDisease;
					}
				}
				
				log(LOG_CONDITION, @"  Searching for spell '%@'", [condition value]);
				
				if( [condition unit] == UnitFriendlies ) {
					conditionEval = [self  evaluateConditionFriendlies:condition];
				} else
				if( [condition unit] == UnitEnemies ) {
					conditionEval = [self  evaluateConditionEnemies:condition];
				} else {
					if( [condition unit] == UnitPlayer ) {
						if( ![playerController playerIsValid:self]) goto loopEnd;
						aUnit = thePlayer;
					} else {
						aUnit = ([condition unit] == UnitTarget || [condition unit] == UnitFriendlies) ? target : [playerController pet];
					}
				
					if( [aUnit isValid]) {
						if( [condition quality] == QualityBuff ) {
							if([condition type] == TypeValue)
								conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasBuff: spellID] : ![auraController unit: aUnit hasBuff: spellID];
							if([condition type] == TypeString)
								conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasBuffNamed: [condition value]] : ![auraController unit: aUnit hasBuffNamed: [condition value]];
						} else if([condition quality] == QualityDebuff) {
							if([condition type] == TypeValue)
								conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasDebuff: spellID] : ![auraController unit: aUnit hasDebuff: spellID];
							if([condition type] == TypeString)
								conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasDebuffNamed: [condition value]] : ![auraController unit: aUnit hasDebuffNamed: [condition value]];
						} else if([condition quality] == QualityBuffType) {
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasBuffType: dispelType] : ![auraController unit: aUnit hasBuffType: dispelType];
						} else if([condition quality] == QualityDebuffType) {
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: aUnit hasDebuffType: dispelType] : ![auraController unit: aUnit hasDebuffType: dispelType];
						}
					}
					
				}
				
				break;
				
			case VarietyAuraStack:;
				spellID = 0;
				dispelType = nil;
				log(LOG_CONDITION, @"Doing Aura Stack condition...");		
				// sanity checks
				if(([condition type] != TypeValue) && ([condition type] != TypeString)) {
					if(test) log(LOG_CONDITION, @" --> Invalid condition type.");
					goto loopEnd;
				}
				if( [condition type] == TypeValue) {
					spellID = [[condition value] unsignedIntValue];
					if(spellID == 0) { // invalid spell ID
						if(test) log(LOG_CONDITION, @" --> Invalid spell number");
						goto loopEnd;
					} else {
						if(test) log(LOG_CONDITION, @" --> Scanning for aura %u", spellID);
					}
				}
				if( [condition type] == TypeString) {
					if( ![[condition value] isKindOfClass: [NSString class]] || ![[condition value] length] ) {
						if(test) log(LOG_CONDITION, @" --> Invalid or blank Spell name.");
						goto loopEnd;
					} else {
						if(test) log(LOG_CONDITION, @" --> Scanning for aura \"%@\"", [condition value]);
					}
				}
				
				
				if( [condition unit] == UnitFriendlies ) {
					conditionEval = [self  evaluateConditionFriendlies:condition];
				} else
				if( [condition unit] == UnitEnemies ) {
					conditionEval = [self  evaluateConditionEnemies:condition];
				} else {
						
					aUnit = nil;
					if( [condition unit] == UnitPlayer ) {
						if( ![playerController playerIsValid:self]) goto loopEnd;
						aUnit = thePlayer;
					} else {
						aUnit = ([condition unit] == UnitTarget || [condition unit] == UnitFriendlies) ? target : [playerController pet];
					}
						
					if( [aUnit isValid]) {
						log(LOG_CONDITION, @"Testing unit %@ for %d", aUnit, spellID);
						int stackCount = 0;
						if( [condition quality] == QualityBuff ) {
							if([condition type] == TypeValue)   stackCount = [auraController unit: aUnit hasBuff: spellID];
							if([condition type] == TypeString)  stackCount = [auraController unit: aUnit hasBuffNamed: [condition value]];
						} else if([condition quality] == QualityDebuff) {
							if([condition type] == TypeValue)   stackCount = [auraController unit: aUnit hasDebuff: spellID];
							if([condition type] == TypeString)  stackCount = [auraController unit: aUnit hasDebuffNamed: [condition value]];
						}
					
						if([condition comparator] == CompareMore) conditionEval = (stackCount > [condition state]);
						if([condition comparator] == CompareEqual) conditionEval = (stackCount == [condition state]);
						if([condition comparator] == CompareLess) conditionEval = (stackCount < [condition state]);
						if(test) log(LOG_CONDITION, @" --> Found %d stacks for result %@", stackCount, (conditionEval ? @"TRUE" : @"FALSE"));
						// conditionEval = ([condition comparator] == CompareMore) ? (stackCount > [condition state]) : (([condition comparator] == CompareEqual) ? (stackCount == [condition state]) : (stackCount < [condition state]));
					}
				}

				break;
				
			case VarietyDistance:;
				if( [condition unit] == UnitTarget && [condition quality] == QualityDistance && target) {
					float distanceToTarget = [[(PlayerDataController*)playerController position] distanceToPosition: [target position]];
					log(LOG_CONDITION, @"-- Checking distance condition --");
					
					if( [condition comparator] == CompareMore) {
						conditionEval = ( distanceToTarget > [[condition value] floatValue] ) ? YES : NO;
						log(LOG_CONDITION, @"  %f > %@ is %d", distanceToTarget, [condition value], conditionEval);
					} else if([condition comparator] == CompareEqual) {
						conditionEval = ( distanceToTarget == [[condition value] floatValue] ) ? YES : NO;
						log(LOG_CONDITION, @"  %f = %@ is %d", distanceToTarget, [condition value], conditionEval);
					} else if([condition comparator] == CompareLess) {
						conditionEval = ( distanceToTarget < [[condition value] floatValue] ) ? YES : NO;
						log(LOG_CONDITION, @"  %f < %@ is %d", distanceToTarget, [condition value], conditionEval);
					} else goto loopEnd;
				}
				
				break;
				
			case VarietyInventory:;
				if( [condition unit] == UnitPlayer && [condition quality] == QualityInventory) {
					log(LOG_CONDITION, @"-- Checking inventory condition --");
					Item *item = ([condition type] == TypeValue) ? [itemController itemForID: [condition value]] : [itemController itemForName: [condition value]];
					int totalCount = [itemController collectiveCountForItemInBags: item];
					if( [condition comparator] == CompareMore) conditionEval = (totalCount > [condition state]) ? YES : NO;
					if( [condition comparator] == CompareEqual) conditionEval = (totalCount == [condition state]) ? YES : NO;		    
					if( [condition comparator] == CompareLess) conditionEval = (totalCount < [condition state]) ? YES : NO;
				}
				break;
				
			case VarietyComboPoints:;
				log(LOG_CONDITION, @"Doing Combo Points condition...");			
				UInt32 class = [thePlayer unitClass];
				if( (class != UnitClass_Rogue) && (class != UnitClass_Druid) ) {
					log(LOG_CONDITION, @" --> You are not a rogue or druid, noob.");
					goto loopEnd;
				}			
				if( ([condition unit] == UnitPlayer) && ([condition quality] == QualityComboPoints) && target) {
					// either we have no CP target, or our CP target matched our current target
					UInt64 cpUID = [playerController comboPointUID];
					if( (cpUID == 0) || ([target cachedGUID] == cpUID)) {
						int comboPoints = [playerController comboPoints];
						log(LOG_CONDITION, @" --> Found %d combo points.", comboPoints);					
						if( [condition comparator] == CompareMore) {
							conditionEval = ( comboPoints > [[condition value] intValue] ) ? YES : NO;
							log(LOG_CONDITION, @" --> %d > %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
						} else if([condition comparator] == CompareEqual) {
							conditionEval = ( comboPoints == [[condition value] intValue] ) ? YES : NO;
							log(LOG_CONDITION, @" --> %d = %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
						} else if([condition comparator] == CompareLess) {
							conditionEval = ( comboPoints < [[condition value] intValue] ) ? YES : NO;
							log(LOG_CONDITION, @" --> %d < %@ is %@.", comboPoints, [condition value], TRUE_FALSE(conditionEval));
						} else goto loopEnd;
					}
				}
				break;
				
			case VarietyTotem:;		
				log(LOG_CONDITION, @"Doing Totem condition...");
				if( ![condition value] || ![[condition value] length] || ![[condition value] isKindOfClass: [NSString class]] ) {
					if(test) log(LOG_CONDITION, @" --> Invalid totem name.");
					goto loopEnd;
				}
				if( ([condition unit] != UnitPlayer) || ([condition quality] != QualityTotem)) {
					log(LOG_CONDITION, @" --> Invalid condition parameters.");
					goto loopEnd;
				}
				if( [thePlayer unitClass] != UnitClass_Shaman ) {
					log(LOG_CONDITION, @" --> You are not a shaman, noob.");
					goto loopEnd;
				}
				
				// we need to rescan the mob list before we check for active totems
				// [mobController enumerateAllMobs];
				BOOL foundTotem = NO;
				for(Mob* mob in [mobController allMobs]) {
					if( [mob isTotem] && ([mob createdBy] == [[playerController player] cachedGUID]) ) {
						NSRange range = [[mob name] rangeOfString: [condition value] options: NSCaseInsensitiveSearch | NSAnchoredSearch | NSDiacriticInsensitiveSearch];
						if(range.location != NSNotFound) {
							foundTotem = YES;
							log(LOG_CONDITION, @" --> Found totem %@ matching \"%@\".", mob, [condition value]);
							break;
						}
					}
				}		
				if(!foundTotem && test) log(LOG_CONDITION, @" --> No totem found with name \"%@\"", [condition value]);
				conditionEval = ([condition comparator] == CompareExists) ? foundTotem : !foundTotem;		
				break;			
				
			case VarietyTempEnchant:;
				log(LOG_CONDITION, @"Doing Temp Enchant condition...");		
				Item *item = [itemController itemForGUID: [thePlayer itemGUIDinSlot: ([condition quality] == QualityMainhand) ? SLOT_MAIN_HAND : SLOT_OFF_HAND]];
				log(LOG_CONDITION, @" --> Got item %@.", item);
				BOOL hadEnchant = [item hasTempEnchantment];
				conditionEval = ([condition comparator] == CompareExists) ? hadEnchant : !hadEnchant;
				log(LOG_CONDITION, @" --> Had enchant? %@. Result is %@.", YES_NO(hadEnchant), TRUE_FALSE(conditionEval));
				break;
				
			case VarietyTargetType:;
				log(LOG_CONDITION, @"Doing Target Type condition...");		
				if([condition quality] == QualityNPC) {
					conditionEval = [target isNPC];
					log(LOG_CONDITION, @" --> Is NPC? %@", YES_NO(conditionEval));
				}
				if([condition quality] == QualityPlayer) {
					conditionEval = [target isPlayer];
					log(LOG_CONDITION, @" --> Is Player? %@", YES_NO(conditionEval));
				}
				break;
				
			case VarietyTargetClass:;
				log(LOG_CONDITION, @"Doing Target Class condition...");
				if([condition quality] == QualityNPC) {
					conditionEval = ( [condition comparator] == CompareIs ) ? ( [target creatureType] == [condition state]) : ([target creatureType] != [condition state]);
//					conditionEval = ([target creatureType] == [condition state]);
					log(LOG_CONDITION, @" --> Unit Creature Type %d == %d? %@", [condition state], [target creatureType], YES_NO(conditionEval));
				}
				if([condition quality] == QualityPlayer) {
					conditionEval = ( [condition comparator] == CompareIs ) ? ( [target unitClass] == [condition state] ) : ([target unitClass] != [condition state]);
//					conditionEval = ([target unitClass] == [condition state]);
					log(LOG_CONDITION, @" --> Unit Class %d == %d? %@", [condition state], [target unitClass], YES_NO(conditionEval));
				}
				break;

			case VarietyCombatCount:;
				log(LOG_CONDITION, @"Doing Combat Count condition...");
				int unitsAttackingMe = [[combatController combatList] count];
				log(LOG_CONDITION, @" --> Found %d units attacking me.", unitsAttackingMe);
				if( [condition comparator] == CompareMore) {
					conditionEval = ( unitsAttackingMe > [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d > %d is %@.", unitsAttackingMe, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( unitsAttackingMe == [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d = %d is %@.", unitsAttackingMe, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( unitsAttackingMe < [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d < %d is %@.", unitsAttackingMe, [condition state], TRUE_FALSE(conditionEval));
				} else goto loopEnd;
				break;
				
			case VarietyProximityCount:;
				log(LOG_CONDITION, @"Doing Proximity Count condition...");
				float distance = [[condition value] floatValue];
				// get list of all possible targets
				NSArray *allTargets = [combatController enemiesWithinRange:distance];
				int inRangeCount = [allTargets count];
				log(LOG_CONDITION, @" --> Found %d total units.", [allTargets count]);		
				// compare with specified number of units
				if( [condition comparator] == CompareMore) {
					conditionEval = ( inRangeCount > [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d > %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( inRangeCount == [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d = %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( inRangeCount < [condition state] ) ? YES : NO;
					log(LOG_CONDITION, @" --> %d < %d is %@.", inRangeCount, [condition state], TRUE_FALSE(conditionEval));
				} else goto loopEnd;
				break;
				
			case VarietySpellCooldown:;
				log(LOG_CONDITION, @"Doing Spell Cooldown condition...");
				BOOL onCD = NO;
				
				// checking by spell ID
				if ( [condition type] == TypeValue ){
					unsigned spellID = [[condition value] unsignedIntValue];
					if ( !spellID ) goto loopEnd;
					// check
					onCD = [spellController isSpellOnCooldown:spellID];
					conditionEval = ( [condition comparator] == CompareIs ) ? onCD : !onCD;
					log(LOG_CONDITION, @" Spell %d is (not? %d) on cooldown? %d", spellID, [condition comparator] == CompareIsNot, onCD);
				}
				// checking by spell ID
				else if ( [condition type] == TypeString ){
					// sanity check
					if ( ![condition value] || ![[condition value] length] ) goto loopEnd;					
					Spell *spell = [spellController spellForName:[condition value]];
					if ( spell && [spell ID] ){
						onCD = [spellController isSpellOnCooldown:[[spell ID] unsignedIntValue]];
						conditionEval = ( [condition comparator] == CompareIs ) ? onCD : !onCD;
						log(LOG_CONDITION, @" Spell %@ is (not? %d) on cooldown? %d", spell, [condition comparator] == CompareIsNot, conditionEval);
					}
				}
				break;
				
			case VarietyLastSpellCast:;
				// checking by spell ID
				if ( [condition type] == TypeValue ){
					unsigned spellID = [[condition value] unsignedIntValue];
					if ( !spellID ) goto loopEnd;

					// check
					BOOL spellCast = (_lastSpellCast == spellID);
					conditionEval = ( [condition comparator] == CompareIs ) ? spellCast : !spellCast;
					log(LOG_CONDITION, @" Spell %d was%@ the last spell cast. (%d was)", spellID, (([condition comparator] == CompareIs ) ? @"" : @" not"), _lastSpellCast);
				}
				// checking by spell ID
				else if ( [condition type] == TypeString ){
					// sanity check
					if ( ![condition value] || ![[condition value] length] ) goto loopEnd;
					Spell *spell = [spellController spellForName:[condition value]];
					if ( spell && [spell ID] ){
						BOOL spellCast = (_lastSpellCast == [[spell ID] unsignedIntValue]);
						conditionEval = ( [condition comparator] == CompareIs ) ? spellCast : !spellCast;
						log(LOG_CONDITION, @" Spell %d was%@ the last spell cast. (%d was)", [[spell ID] unsignedIntValue], (([condition comparator] == CompareIs ) ? @"" : @" not"), _lastSpellCast);
					}
				}
				break;

			case VarietyRune:;
				if(test) log(LOG_GENERAL, @"Doing Rune condition...");
				// get our rune type
				int runeType = RuneType_Blood;
				if ( [condition quality] == QualityRuneUnholy ) runeType = RuneType_Unholy;
				else if ( [condition quality] == QualityRuneFrost ) runeType = RuneType_Frost;
				else if ( [condition quality] == QualityRuneDeath ) runeType = RuneType_Death;
				
				// quality value
				int runesAvailable = [playerController runesAvailable:runeType];
				// now we have the value of the quality
				if( [condition comparator] == CompareMore) {
					conditionEval = ( runesAvailable > [[condition value] unsignedIntValue] ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d > %@ is %d", runesAvailable, [condition value], conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( runesAvailable == [[condition value] unsignedIntValue] ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d = %@ is %d", runesAvailable, [condition value], conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( runesAvailable < [[condition value] unsignedIntValue] ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d < %@ is %d", runesAvailable, [condition value], conditionEval);
				} else goto loopEnd;
				if (test) log(LOG_GENERAL, @" Checking type %d - is %d equal to %@", runeType, [playerController runesAvailable:runeType], [condition value]);
				break;
				
			case VarietyPlayerLevel:;
				if(test) log(LOG_GENERAL, @"Doing Player level condition...");
				int level = [[condition value] intValue];
				int playerLevel = [playerController level];
				
				// check level
				if( [condition comparator] == CompareMore) {
					conditionEval = ( playerLevel > level ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d > %d is %d", playerLevel, level, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( playerLevel == level ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d = %d is %d", playerLevel, level, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( playerLevel < level ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d < %d is %d", playerLevel, level, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyPlayerZone:;
				if(test) log(LOG_GENERAL, @"Doing Player zone condition...");
				int zone = [[condition value] intValue];
				int playerZone = [playerController zone];
				// check zone
				if( [condition comparator] == CompareIs) {
					conditionEval = ( zone == playerZone ) ? YES : NO;
					log(LOG_GENERAL, @"  %d = %d is %d", zone, playerZone, conditionEval);
				} else if([condition comparator] == CompareIsNot) {
					conditionEval = ( zone != playerZone ) ? YES : NO;
					log(LOG_GENERAL, @"  %d != %d is %d", zone, playerZone, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyInventoryFree:;
				if(test) log(LOG_GENERAL, @"Doing free inventory condition...");				
				int freeSpaces = [[condition value] intValue];
				int totalFree = [itemController bagSpacesAvailable];
				
				// check free spaces
				if( [condition comparator] == CompareMore) {
					conditionEval = ( totalFree > freeSpaces ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d > %d is %d", totalFree, freeSpaces, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( totalFree == freeSpaces ) ? YES : NO;
					//log(LOG_GENERAL, @"  %d = %d is %d", totalFree, freeSpaces, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( totalFree < freeSpaces ) ? YES : NO;
					//log(LOG_GENERAL, @"	%d < %d is %d", totalFree, freeSpaces, conditionEval);
				} else goto loopEnd;
				
				break;
				
			case VarietyDurability:;
				log(LOG_CONDITION, @"Doing durability condition...");
				float averageDurability = [itemController averageWearableDurability];
				float durabilityPercentage = [[condition value] floatValue];
				log(LOG_CONDITION, @"%0.2f %0.2f", averageDurability, durabilityPercentage);
				// generally means we haven't updated our arrays yet in inventoryController
				if ( averageDurability == 0 ) goto loopEnd;
				// check free spaces
				if( [condition comparator] == CompareMore) {
					conditionEval = ( averageDurability > durabilityPercentage ) ? YES : NO;
					log(LOG_CONDITION, @"  %0.2f > %0.2f is %d", averageDurability, durabilityPercentage, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( averageDurability == durabilityPercentage ) ? YES : NO;
					log(LOG_CONDITION, @"  %0.2f = %0.2f is %d", averageDurability, durabilityPercentage, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( averageDurability < durabilityPercentage ) ? YES : NO;
					log(LOG_CONDITION, @"	%0.2f < %0.2f is %d", averageDurability, durabilityPercentage, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyMobsKilled:;
				log(LOG_CONDITION, @"Doing mobs killed condition...");
				int entryID = [[condition value] intValue];
				int killCount = [condition state];
				int realKillCount = [statisticsController killCountForEntryID:entryID];				
				// check free spaces
				if( [condition comparator] == CompareMore) {
					conditionEval = ( realKillCount > killCount ) ? YES : NO;
					log(LOG_CONDITION, @"  %d > %d is %d", realKillCount, killCount, conditionEval);
				} else if([condition comparator] == CompareEqual) {
					conditionEval = ( realKillCount == killCount ) ? YES : NO;
					log(LOG_CONDITION, @"  %d = %d is %d", realKillCount, killCount, conditionEval);
				} else if([condition comparator] == CompareLess) {
					conditionEval = ( realKillCount < killCount ) ? YES : NO;
					log(LOG_CONDITION, @"  %d < %d is %d", realKillCount, killCount, conditionEval);
				} else goto loopEnd;
				
				break;
				
			case VarietyGate:;
				log(LOG_CONDITION, @"Doing gate condition...");
				// grab our gate ID
				int quality = [condition quality];
				int gateEntryID = 0;
				if ( quality == QualityBlueGate ) gateEntryID = StrandGateOfTheBlueSapphire;
				else if ( quality == QualityGreenGate ) gateEntryID = StrandGateOfTheGreenEmerald;
				else if ( quality == QualityPurpleGate ) gateEntryID = StrandGateOfThePurpleAmethyst;
				else if ( quality == QualityRedGate ) gateEntryID = StrandGateOfTheRedSun;
				else if ( quality == QualityYellowGate) gateEntryID = StrandGateOfTheYellowMoon;
				else if ( quality == QualityChamber) gateEntryID = StrandChamberOfAncientRelics;
				Node *gate = [nodeController nodeWithEntryID:gateEntryID];
				if ( !gate ) goto loopEnd;				
				BOOL destroyed = ([gate objectHealth] == 0) ? YES : NO;
				if ( [condition comparator] == CompareIs ) {
					conditionEval = destroyed;
					log(LOG_CONDITION, @"  %d is destroyed? %d", gateEntryID, conditionEval);
				} else if ( [condition comparator] == CompareIsNot ) {
					conditionEval = !destroyed;
					log(LOG_CONDITION, @"  %d is not destroyed? %d", gateEntryID, conditionEval);
				} else goto loopEnd;
				break;
				
			case VarietyStrandStatus:;
				log(LOG_CONDITION, @"Doing battleground status condition...");
				if ( [condition quality] == QualityAttacking ){
					conditionEval = _attackingInStrand;
					log(LOG_CONDITION, @"  checking if we're attacking in strand? %d", conditionEval);
				} else if ( [condition quality] == QualityDefending ){
					conditionEval = !_attackingInStrand;
					log(LOG_CONDITION, @"  checking if we're defending in strand? %d", conditionEval);
				} else goto loopEnd;
				break;
				
			default:;
				log(LOG_CONDITION, @"checking for %d", [condition variety]);
				break;
		}
		
	loopEnd:
		if(conditionEval) numMatched++;
		// shortcut bail if we can
		if ([rule isMatchAll]) {
			if(!conditionEval) return NO;
		} else {
			if(conditionEval) return YES;
		}
	}
	
	if(numMatched >= needToMatch) return YES;
	return NO;
}

- (BOOL)evaluateConditionFriendlies: (Condition*)condition {

	BOOL conditionEval = NO;
	Unit *target = nil;
	NSArray *friends = nil;

	switch ( [condition variety] ) {

		case VarietyStatus:;
			log(LOG_CONDITION, @"Doing Status condition for friendlies...");	

			if (!friends) friends = [combatController friendlyUnits];
			
			// Let's loop through friends to find a target
			for ( target in friends ) {
				
				// check alive status
				if( [condition state] == StateAlive ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? ![target isDead] : [target isDead];
					log(LOG_CONDITION, @"	Alive? %d", conditionEval);
				}

				// check combat status
				if( [condition state] == StateCombat ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isInCombat] : ![target isInCombat];
					log(LOG_CONDITION, @"	Combat? %d", conditionEval);
				}

				// check casting status
				if( [condition state] == StateCasting ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isCasting] : ![target isCasting];
					log(LOG_CONDITION, @"	Casting? %d", conditionEval);
				}

				// check swimming status
				if( [condition state] == StateSwimming ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isSwimming] : ![target isSwimming];
					log(LOG_CONDITION, @"	Swimming? %d", conditionEval);
				}
			
				// check targeting me status
				if( [condition state] == StateTargetingMe ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isTargetingMe] : ![target isTargetingMe];
					log(LOG_CONDITION, @"	Targeting me? %d", conditionEval);
				}
			
				// check tank status
				if( [condition state] == StateTank ) {
				conditionEval = ( [condition comparator] == CompareIs ) ? [self isTank: (Unit*)target] : ![self isTank: (Unit*)target];
				log(LOG_CONDITION, @"	Tank? %d", conditionEval);
				}

				// IS THE UNIT MOUNTED?
				if( [condition state] == StateMounted ) {
					log(LOG_CONDITION, @"Doing State IsMounted condition...");
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isMounted] : ![target isMounted];
				}
			}
			
			break;

		case VarietyAura:;
			
			log(LOG_CONDITION, @"-- Checking aura condition --");
			unsigned spellID = 0;
			NSString *dispelType = nil;
			BOOL doDispelCheck = ([condition quality] == QualityBuffType) || ([condition quality] == QualityDebuffType);
			
			// sanity checks
			if(!doDispelCheck) {
				if( [condition type] == TypeValue) spellID = [[condition value] unsignedIntValue];
				
				if( ([condition type] == TypeValue) && !spellID) {
					// invalid spell ID
					goto loopEnd;
				} else if( [condition type] == TypeString && (![condition value] || ![[condition value] length])) {
					// invalid spell name
					goto loopEnd;
				}
			} else {
				if( ([condition state] < StateMagic) || ([condition state] > StatePoison)) {
					// invalid dispel type
					goto loopEnd;
				} else {
					if([condition state] == StateMagic)	dispelType = DispelTypeMagic;
					if([condition state] == StateCurse)	dispelType = DispelTypeCurse;
					if([condition state] == StatePoison)	dispelType = DispelTypePoison;
					if([condition state] == StateDisease)	dispelType = DispelTypeDisease;
				}
			}
			
			log(LOG_CONDITION, @"  Searching for spell '%@'", [condition value]);
			
			if (!friends) friends = [combatController friendlyUnits];
			
			// Let's loop through friends to find a target
			for ( target in friends ) {
				
				if( [condition quality] == QualityBuff ) {
					if([condition type] == TypeValue)
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasBuff: spellID] : ![auraController unit: target hasBuff: spellID];
					if([condition type] == TypeString)
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasBuffNamed: [condition value]] : ![auraController unit: target hasBuffNamed: [condition value]];
				} else 
					
				if([condition quality] == QualityDebuff) {
					if([condition type] == TypeValue)
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasDebuff: spellID] : ![auraController unit: target hasDebuff: spellID];
					if([condition type] == TypeString)
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasDebuffNamed: [condition value]] : ![auraController unit: target hasDebuffNamed: [condition value]];
				} else 
					
				if([condition quality] == QualityBuffType) {
					conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasBuffType: dispelType] : ![auraController unit: target hasBuffType: dispelType];
				} else 
				
				if([condition quality] == QualityDebuffType) {
					conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasDebuffType: dispelType] : ![auraController unit: target hasDebuffType: dispelType];
				}
				
			}
			
			break;
			
		case VarietyAuraStack:;
			spellID = 0;
			dispelType = nil;
			log(LOG_CONDITION, @"Doing Aura Stack condition...");		
			// sanity checks
			if(([condition type] != TypeValue) && ([condition type] != TypeString)) {
				log(LOG_CONDITION, @" --> Invalid condition type.");
				goto loopEnd;
			}
			if( [condition type] == TypeValue) {
				spellID = [[condition value] unsignedIntValue];
				if(spellID == 0) { // invalid spell ID
					log(LOG_CONDITION, @" --> Invalid spell number");
					goto loopEnd;
				} else {
					log(LOG_CONDITION, @" --> Scanning for aura %u", spellID);
				}
			}
			if( [condition type] == TypeString) {
				if( ![[condition value] isKindOfClass: [NSString class]] || ![[condition value] length] ) {
					log(LOG_CONDITION, @" --> Invalid or blank Spell name.");
					goto loopEnd;
				} else {
					log(LOG_CONDITION, @" --> Scanning for aura \"%@\"", [condition value]);
				}
			}
			
			log(LOG_CONDITION, @"Testing for %d", spellID);
			
			if (!friends) friends = [combatController friendlyUnits];
			
			// Let's loop through friends to find a target
			for ( target in friends ) {
				
				int stackCount = 0;
				if( [condition quality] == QualityBuff ) {
					if([condition type] == TypeValue)   stackCount = [auraController unit: target hasBuff: spellID];
					if([condition type] == TypeString)  stackCount = [auraController unit: target hasBuffNamed: [condition value]];
				} else if([condition quality] == QualityDebuff) {
					if([condition type] == TypeValue)   stackCount = [auraController unit: target hasDebuff: spellID];
					if([condition type] == TypeString)  stackCount = [auraController unit: target hasDebuffNamed: [condition value]];
				}
				
				if([condition comparator] == CompareMore) conditionEval = (stackCount > [condition state]);
				if([condition comparator] == CompareEqual) conditionEval = (stackCount == [condition state]);
				if([condition comparator] == CompareLess) conditionEval = (stackCount < [condition state]);
				log(LOG_CONDITION, @" --> Found %d stacks for result %@", stackCount, (conditionEval ? @"TRUE" : @"FALSE"));
			}
			
			break;
			
		default:;
			if (conditionEval) return YES;
			break;
			
	loopEnd:
		if (conditionEval) return YES;

	}
	
	if (conditionEval) return YES;
	return NO;
}

- (BOOL)evaluateConditionEnemies: (Condition*)condition {
	
	BOOL conditionEval = NO;
	Unit *target = nil;
	NSArray *enemies = nil;
	
	switch ( [condition variety] ) {
			
		case VarietyStatus:;
			log(LOG_CONDITION, @"Doing Status condition for friendlies...");	
			
			if (!enemies) enemies = [combatController allAdds];
			
			// Let's loop through friends to find a target
			for ( target in enemies ) {
				
				// check alive status
				if( [condition state] == StateAlive ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? ![target isDead] : [target isDead];
					log(LOG_CONDITION, @"	Alive? %d", conditionEval);
				}
				
				// check combat status
				if( [condition state] == StateCombat ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isInCombat] : ![target isInCombat];
					log(LOG_CONDITION, @"	Combat? %d", conditionEval);
				}
				
				// check casting status
				if( [condition state] == StateCasting ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isCasting] : ![target isCasting];
					log(LOG_CONDITION, @"	Casting? %d", conditionEval);
				}
				
				// check swimming status
				if( [condition state] == StateSwimming ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isSwimming] : ![target isSwimming];
					log(LOG_CONDITION, @"	Swimming? %d", conditionEval);
				}
				
				// check targeting me status
				if( [condition state] == StateTargetingMe ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isTargetingMe] : ![target isTargetingMe];
					log(LOG_CONDITION, @"	Targeting me? %d", conditionEval);
				}
				
				// check tank status
				if( [condition state] == StateTank ) {
					conditionEval = ( [condition comparator] == CompareIs ) ? [self isTank: (Unit*)target] : ![self isTank: (Unit*)target];
					log(LOG_CONDITION, @"	Tank? %d", conditionEval);
				}
				
				// IS THE UNIT MOUNTED?
				if( [condition state] == StateMounted ) {
					log(LOG_CONDITION, @"Doing State IsMounted condition...");
					conditionEval = ( [condition comparator] == CompareIs ) ? [target isMounted] : ![target isMounted];
				}
			}
			
			break;
			
		case VarietyAura:;
			
			log(LOG_CONDITION, @"-- Checking aura condition --");
			unsigned spellID = 0;
			NSString *dispelType = nil;
			BOOL doDispelCheck = ([condition quality] == QualityBuffType) || ([condition quality] == QualityDebuffType);
			
			// sanity checks
			if(!doDispelCheck) {
				if( [condition type] == TypeValue) spellID = [[condition value] unsignedIntValue];
				
				if( ([condition type] == TypeValue) && !spellID) {
					// invalid spell ID
					goto loopEnd;
				} else if( [condition type] == TypeString && (![condition value] || ![[condition value] length])) {
					// invalid spell name
					goto loopEnd;
				}
			} else {
				if( ([condition state] < StateMagic) || ([condition state] > StatePoison)) {
					// invalid dispel type
					goto loopEnd;
				} else {
					if([condition state] == StateMagic)	dispelType = DispelTypeMagic;
					if([condition state] == StateCurse)	dispelType = DispelTypeCurse;
					if([condition state] == StatePoison)	dispelType = DispelTypePoison;
					if([condition state] == StateDisease)	dispelType = DispelTypeDisease;
				}
			}

			log(LOG_CONDITION, @"  Searching for spell '%@'", [condition value]);
			
			if (!enemies) enemies = [combatController allAdds];
			
			// Let's loop through friends to find a target
			for ( target in enemies ) {
				
				if( [condition quality] == QualityBuff ) {
					if([condition type] == TypeValue)
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasBuff: spellID] : ![auraController unit: target hasBuff: spellID];
					if([condition type] == TypeString)
						conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasBuffNamed: [condition value]] : ![auraController unit: target hasBuffNamed: [condition value]];
				} else 
					
					if([condition quality] == QualityDebuff) {
						if([condition type] == TypeValue)
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasDebuff: spellID] : ![auraController unit: target hasDebuff: spellID];
						if([condition type] == TypeString)
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasDebuffNamed: [condition value]] : ![auraController unit: target hasDebuffNamed: [condition value]];
					} else 
						
						if([condition quality] == QualityBuffType) {
							conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasBuffType: dispelType] : ![auraController unit: target hasBuffType: dispelType];
						} else 
							
							if([condition quality] == QualityDebuffType) {
								conditionEval = ([condition comparator] == CompareExists) ? [auraController unit: target hasDebuffType: dispelType] : ![auraController unit: target hasDebuffType: dispelType];
							}
				
			}
			
			break;
			
		case VarietyAuraStack:;
			spellID = 0;
			dispelType = nil;
			log(LOG_CONDITION, @"Doing Aura Stack condition...");		
			// sanity checks
			if(([condition type] != TypeValue) && ([condition type] != TypeString)) {
				log(LOG_CONDITION, @" --> Invalid condition type.");
				goto loopEnd;
			}
			if( [condition type] == TypeValue) {
				spellID = [[condition value] unsignedIntValue];
				if(spellID == 0) { // invalid spell ID
					log(LOG_CONDITION, @" --> Invalid spell number");
					goto loopEnd;
				} else {
					log(LOG_CONDITION, @" --> Scanning for aura %u", spellID);
				}
			}
			if( [condition type] == TypeString) {
				if( ![[condition value] isKindOfClass: [NSString class]] || ![[condition value] length] ) {
					log(LOG_CONDITION, @" --> Invalid or blank Spell name.");
					goto loopEnd;
				} else {
					log(LOG_CONDITION, @" --> Scanning for aura \"%@\"", [condition value]);
				}
			}
			
			log(LOG_CONDITION, @"Testing for %d", spellID);
			
			if (!enemies) enemies = [combatController allAdds];
			
			// Let's loop through friends to find a target
			for ( target in enemies ) {
				
				int stackCount = 0;
				if( [condition quality] == QualityBuff ) {
					if([condition type] == TypeValue)   stackCount = [auraController unit: target hasBuff: spellID];
					if([condition type] == TypeString)  stackCount = [auraController unit: target hasBuffNamed: [condition value]];
				} else if([condition quality] == QualityDebuff) {
					if([condition type] == TypeValue)   stackCount = [auraController unit: target hasDebuff: spellID];
					if([condition type] == TypeString)  stackCount = [auraController unit: target hasDebuffNamed: [condition value]];
				}
				
				if([condition comparator] == CompareMore) conditionEval = (stackCount > [condition state]);
				if([condition comparator] == CompareEqual) conditionEval = (stackCount == [condition state]);
				if([condition comparator] == CompareLess) conditionEval = (stackCount < [condition state]);
				log(LOG_CONDITION, @" --> Found %d stacks for result %@", stackCount, (conditionEval ? @"TRUE" : @"FALSE"));
			}
			
			break;
			
		default:;
			if (conditionEval) return YES;
			break;
			
		loopEnd:
			if (conditionEval) return YES;
			
	}
	
	if (conditionEval) return YES;
	return NO;
}

- (void)cancelCurrentEvaluation {

    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateSituation) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForGhost) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForPVPQueue) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForPVPBattleGround) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForParty) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForFollow) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForCombatContinuation) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForCombatStart) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForRegen) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForLoot) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForPartyEmotes) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForFishing) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForMiningAndHerbalism) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(evaluateForPatrol) object: nil];

	_evaluationIsActive = NO;
	self.evaluationInProgress = nil;
}

- (void)cancelCurrentProcedure {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
	[_lastProcedureExecuted release]; _lastProcedureExecuted = nil;
	[_castingUnit release]; _castingUnit = nil;
	[combatController cancelAllCombat];

	if ( self.procedureInProgress ) _lastProcedureExecuted = [NSString stringWithString:self.procedureInProgress];

	[self setProcedureInProgress: nil];

}

- (void)finishCurrentProcedure: (NSDictionary*)state {
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
	if ( !self.isBotting ) return;
	[_castingUnit release]; _castingUnit = nil;

	// Make sure we're done casting before we end the procedure
    if ( [playerController isCasting] ) {
		log(LOG_DEV, @"Player is casting, waiting.");
		[self performSelector: @selector(finishCurrentProcedure:) withObject: state afterDelay: 0.25f];
		return;
    }

	// Finish Regen.
	if ( [[state objectForKey: @"Procedure"] isEqualToString: RegenProcedure] ) {
		if ( [[state objectForKey: @"ActionsPerformed"] intValue] > 0 ) {
			self.evaluationInProgress = @"Regen";
			log(LOG_REGEN, @"Starting regen!");
			[self performSelector: @selector(monitorRegen:) withObject: [[NSDate date] retain] afterDelay: 0.25f];
			return;
		} else {
			// or if we didn't regen, go back to evaluate
			log(LOG_PROCEDURE, @"No regen, back to evaluate");
			[controller setCurrentStatus: @"Bot: Enabled"];
			[self cancelCurrentProcedure];
			[self cancelCurrentEvaluation];
			[self evaluateSituation];
			return;
		}
	}

	// Finish Patrolling.
    if([[state objectForKey: @"Procedure"] isEqualToString: PatrollingProcedure]) {

		// Raise up a little bit
		if ( [[playerController player] isFlyingMounted] && ![[playerController player] isSwimming] ) [movementController raiseUpAfterAirMount];
		[controller setCurrentStatus: @"Bot: Enabled"];
		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[self evaluateSituation];
		return;
	}

	[self cancelCurrentEvaluation];

	log(LOG_PROCEDURE, @"Finishing Procedure: %@", [state objectForKey: @"Procedure"]);

	// Finish PreCombat.
    if ( [[state objectForKey: @"Procedure"] isEqualToString: PreCombatProcedure] ) {
		log(LOG_DEV, @"[Eval] After PreCombat");
		Unit *target = [state objectForKey: @"Target"];
		// start the combat procedure
		[self performProcedureWithState: [NSDictionary dictionaryWithObjectsAndKeys: 
										  CombatProcedure,				@"Procedure",
										  [NSNumber numberWithInt: 0],	@"CompletedRules",
										  target,						@"Target", nil]];

		return;
    }

	// Finish PostCombat.
    if ( [[state objectForKey: @"Procedure"] isEqualToString: PostCombatProcedure]) {
		log(LOG_DEV, @"[Eval] After PostCombat");
		[controller setCurrentStatus: @"Bot: Enabled"];
		[self cancelCurrentProcedure];
		[self evaluateSituation];
		return;
	}

	// Finish Combat.
	if ( [[state objectForKey: @"Procedure"] isEqualToString: CombatProcedure] ) {

		//Call back the pet if needed
		if ( [self.theBehavior usePet] && [playerController pet] && ![[playerController pet] isDead] ) [macroController useMacroOrSendCmd:@"PetFollow"];

		if ( [combatController inCombat] ) [combatController cancelCombatAction];

		// If we're still in combat then return to evaluation
		if ( [combatController inCombat] ) {
			[controller setCurrentStatus: @"Bot: Enabled"];
			[self cancelCurrentProcedure];
			[self evaluateSituation];
			return;
		} else {
			// Start PostCombat
			log(LOG_PROCEDURE, @"Combat completed, moving to PostCombat.");
			[self performSelector: @selector(performProcedureWithState:) 
				   withObject:	[NSDictionary dictionaryWithObjectsAndKeys: 
										PostCombatProcedure,			@"Procedure", 
										[NSNumber numberWithInt: 0],	@"CompletedRules", nil]];
			return;
		}
	}
}

- (void)performProcedureWithState: (NSDictionary*)state {
	if ( !self.isBotting ) return;

	log(LOG_FUNCTION, @"performProcedureWithState called");

	// Set some variables we'll need
	Unit *target = [state objectForKey: @"Target"];		// This value may get changed
    Unit *originalTarget = target;						// Preserve the original target

	// if there's another procedure running, we gotta stop it
    if( self.procedureInProgress && ![self.procedureInProgress isEqualToString: [state objectForKey: @"Procedure"]]) {
		log(LOG_DEV, @"Cancelling %@ to begin %@.", self.procedureInProgress, [state objectForKey: @"Procedure"]);
		[self cancelCurrentProcedure];
    }

    if ( !self.procedureInProgress ) {

		[self setProcedureInProgress: [state objectForKey: @"Procedure"]];
		
		log(LOG_DEV, @"No Procedure in progress, setting it to: %@", self.procedureInProgress);

		if ( ![[self procedureInProgress] isEqualToString: CombatProcedure] ) {
			if( [[self procedureInProgress] isEqualToString: PreCombatProcedure]) {
				[controller setCurrentStatus: @"Bot: Pre-Combat Phase"];
			} else 
			if ( [[self procedureInProgress] isEqualToString: PostCombatProcedure]) {
				[controller setCurrentStatus: @"Bot: Post-Combat Phase"];
			} else 
			if( [[self procedureInProgress] isEqualToString: RegenProcedure]) {
				[controller setCurrentStatus: @"Bot: Regen Phase"];
				self.evaluationInProgress = @"Regen";
			} else 
			if( [[self procedureInProgress] isEqualToString: PatrollingProcedure]) {
				[controller setCurrentStatus: @"Bot: Patrolling Phase"];
				self.evaluationInProgress = @"Patrol";
			}
		}
    }

	// Check the unit to make sure we don't need to bail.
	if  ( ![self performProcedureUnitCheck: target withState:state] ) return;

	// See if we need to record our follow units route
//	[self followRouteStartRecord];

	// Delay until we can cast
    if ( [playerController isCasting] ) {
		// We'll do this, just in case our spell is interrupted
		log(LOG_DEV, @"Player is casting, waiting.");
		[self performSelector: @selector(performProcedureWithState:) withObject: state afterDelay: 0.25f];
		return;
	}

	// Wait if our GCD is active!
	if ( [spellController isGCDActive] ) {
		log(LOG_DEV, @"GCD is active, waiting...");
		[self performSelector: @selector(performProcedureWithState:) withObject: state afterDelay: 0.1f];
		return;
	}

	// If this is a continuation of regen from a bot start durring regen
	if ([[self procedureInProgress] isEqualToString: RegenProcedure] ) {

		// Only do this if we currently have an eating or drinking buff
		if ([auraController unit: [playerController player] hasBuffNamed: @"Food"] || [auraController unit: [playerController player] hasBuffNamed: @"Drink"]) {
			BOOL eatClear = NO;
			// check health
			if ( [playerController health] == [playerController maxHealth] ) eatClear = YES;
			// no buff for eating anyways
			else if ( ![auraController unit: [playerController player] hasBuffNamed: @"Food"] ) eatClear = YES;
			
			BOOL drinkClear = NO;
			// check mana
			if ( [playerController mana] == [playerController maxMana] ) drinkClear = YES;
			// no buff for drinking anyways
			else if ( ![auraController unit: [playerController player] hasBuffNamed: @"Drink"] ) drinkClear = YES;
			
			// we're not done eating/drinking
			if ( !eatClear || !drinkClear ) {

				if ( [playerController targetID] != [[playerController player] cachedGUID] ) {
					log(LOG_PROCEDURE, @"Targeting self.");
					[playerController targetGuid:[[playerController player] cachedGUID]];
				}

				self.evaluationInProgress = @"Regen";
				[self finishCurrentProcedure: state];
				return;
			}
		}
	}

	// Setting more variables
    Procedure *procedure = [self.theBehavior procedureForKey: [state objectForKey: @"Procedure"]];
    int completed = [[state objectForKey: @"CompletedRules"] intValue];
    int attempts = [[state objectForKey: @"RuleAttempts"] intValue];
	int actionsPerformed = [[state objectForKey: @"ActionsPerformed"] intValue];
	int inCombatNoAttack = [[state objectForKey: @"InCombatNoAttack"] intValue];
	int ruleCount = [procedure ruleCount];

	// Create a dictionary to track our tried rules
	NSMutableDictionary *rulesTried = [state objectForKey: @"RulesTried"];
	if ( rulesTried == nil ) rulesTried = [[[NSMutableDictionary dictionary] retain] autorelease];


	if ( [[self procedureInProgress] isEqualToString: CombatProcedure]) {
		log(LOG_DEV, @"Requested procedure is %@", self.procedureInProgress);
		NSArray *combatList = [combatController combatList];
		int count =		[combatList count];
		if (count == 1)	[controller setCurrentStatus: [NSString stringWithFormat: @"Bot: Player in Combat (%d unit)", count]];
		else		[controller setCurrentStatus: [NSString stringWithFormat: @"Bot: Player in Combat (%d units)", count]];
		log(LOG_DEV, @"CombatProcedure called for: %@", target );
	}

    // Bail if there is no procedure
    if ( !procedure ) {
		[self finishCurrentProcedure: state];
		return;
    }

    // have we exceeded our maximum attempts on this rule?
    if ( attempts > 3 ) {
		log(LOG_PROCEDURE, @"Exceeding (%d) attempts on action %@ for %@.", attempts, [spellController spellForID: [NSNumber numberWithUnsignedInt: _lastSpellCast]], _castingUnit );

		if ( ![_castingUnit isInCombat] ) {
			log(LOG_PROCEDURE, @"Unit not in combat, blacklisting (using LoS settings).");
			[blacklistController blacklistObject:_castingUnit withReason:Reason_NotInLoS];
			[self performSelector: @selector(finishCurrentProcedure:) withObject: state afterDelay: 0.25f];
			return;
		}

		[self performSelector: _cmd withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
												 [state objectForKey: @"Procedure"],			@"Procedure",
												 [NSNumber numberWithInt: completed+1],			@"CompletedRules",
												 [NSNumber numberWithInt: inCombatNoAttack],	@"InCombatNoAttack",
												 originalTarget,								@"Target",  nil] afterDelay: 0.25f];
		return;

    }

	// See if we need to target a new hostile
	if ( [[self procedureInProgress] isEqualToString: CombatProcedure] && !_castingUnit && completed == 0 && ![playerController isFriendlyWithFaction: [target factionTemplate]] ) {
		[movementController turnTowardObject: target];
//		usleep([controller refreshDelay]*2);
		[movementController establishPlayerPosition];	// This helps up refresh
	}
	/*
	 * Starting rule/target selection.
	 *
	 * Priority system is Rule based, 1st rule to match gets the action.
	 * This sets the initial target priority as well.
	 */

	Rule *rule;
	int i;
	BOOL matchFound = NO;
	BOOL wasResurrected = NO;

	float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"BlacklistVerticalOffset"] floatValue];
	float attackRange = ( theCombatProfile.attackRange > theCombatProfile.engageRange ) ? theCombatProfile.attackRange : theCombatProfile.engageRange;

	NSArray *adds = nil;
	NSArray *pats = nil;
	NSArray *friendlies = nil;

	Player *player=[playerController player];
	Position *playerPosition = [player position];
	BOOL onTheGround = [playerController isOnGround];
	BOOL isMoving = [movementController isMoving];

	UInt64 playerTargetID = [playerController targetID];
	int32_t actionID;
	
	for ( i = 0; i < ruleCount; i++ ) {
		rule = [procedure ruleAtIndex: i];

		log(LOG_RULE, @"Evaluating rule %@", rule);

		// make sure our rule hasn't continuously failed!
		NSString *triedRuleKey = [NSString stringWithFormat:@"%d_0x%qX", i, [target cachedGUID]];
		NSNumber *tries = [rulesTried objectForKey:triedRuleKey];
		actionID = [rule actionID];

		if ( tries ) {
			if ( [tries intValue] > 3 ){
				log(LOG_RULE, @"Rule %d failed after %@ attempts!", i, tries);
				continue;
			}
		}

		// General checks that apply to all rules
		if ( [rule resultType] == ActionType_Spell ) {

			// If we're moving, if so we only try rules for instant spells
			Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: actionID]];

			if ( ![spell isInstant] && isMoving ) {
				log(LOG_RULE, @"Skipping we're moving and the rule is non instant (%d).", actionID);
				continue;
			}

			if ( ![spell isInstant] && !onTheGround ) {
				log(LOG_RULE, @"Skipping since we're in the air and the rule is non instant (%d).", actionID);
				continue;
			}

			if ( [spellController isSpellOnCooldown: actionID] ) {
				log(LOG_RULE, @"Spell is on cooldown (%d).", actionID);
				continue;
			}

			// check to see if we can even cast this spell
			if ( ![spellController isUsableAction: actionID] ){
				log(LOG_RULE, @"Spell isn't usable (%d).", actionID);
				continue;
			}

		} else

		if ( [rule resultType] == ActionType_Item ) {

			// If we're moving, if so we only try rules for instant spells
			if ( [spellController isSpellOnCooldown: actionID] ) {
				log(LOG_RULE, @"Item is on cooldown (%d).", actionID);
				continue;
			}
/*
 This one doesn't seem to work
 			// check to see if we can even cast this spell
			if ( ![spellController isUsableAction: actionID] ){
				log(LOG_RULE, @"Item isn't usable (%d).", actionID);
				continue;
			}
 */
		}

		// Ourself
		if ( [rule target] == TargetSelf ) {
			target = (Unit*)player;

			if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
				// do something
				log(LOG_RULE, @"Self match for %@.", rule);
				matchFound = YES;
				break;
			}
		}

		// No Target
		else if ( [rule target] == TargetNone ) {
			if ( [self evaluateRule: rule withTarget: nil asTest: NO] ) {
				// do something
				log(LOG_RULE, @"Match for %@ (Target None)", rule);
				matchFound = YES;
				break;
			}
		}

		// Pet
		else if ( [rule target] == TargetPet ) {
			target = (Unit*)[playerController pet];

			if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
				// do something
				log(LOG_RULE, @"Pet match for %@ %@", rule, target);
				matchFound = YES;
				break;
			}
		}

		// Enemy
		else if ( [rule target] == TargetEnemy ) {
			
			// If our procedure target is a friendly lets skip this
			if ( [playerController isFriendlyWithFaction: [target factionTemplate]] ) continue;

			if ([self evaluateRule: rule withTarget: target asTest: NO] ) {
				log(LOG_RULE, @"Enemy match for %@ %@", rule, target);
				matchFound = YES;
				break;
			}
		}

		// Friend
		else if ( [rule target] == TargetFriend ) {

			// If our procedure target is not friendly lets skip this
			if ( ![playerController isFriendlyWithFaction: [target factionTemplate]] ) continue;

			if ([self evaluateRule: rule withTarget: target asTest: NO] ) {
				log(LOG_RULE, @"Friend match for %@ %@", rule, target);
				matchFound = YES;
				break;
			}
		}

		/*
		 * From here down it's checks that may potentially change your target.
		 */

		// Friendlies
		else if ( [rule target] == TargetFriendlies ) {

			if (!friendlies) friendlies = [combatController friendlyUnits];
			Unit *bestUnit = nil;
			int highestWeight = -1000;

			// Let's loop through friends to find a target
			for ( target in friendlies ) {

				if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
					
					if ( !matchFound ) {
						matchFound = YES;
						bestUnit = target;
					}

					int weight = [combatController weight: target PlayerPosition:playerPosition];
					if ( weight > highestWeight ) {
						highestWeight = weight;
						bestUnit = target;
					}
				}

			}

			if ( matchFound ) {
				// do something
				target = bestUnit;
				log(LOG_RULE, @"Friendlies match for %@ with %@", rule, target);
				break;
			}
		}
		
		// Add
		else if ( [rule target] == TargetAdd ) {

			if (!adds) adds = [combatController allAdds];
			Unit *bestUnit = nil;
			int highestWeight = -1000;

			for ( target in adds ) {

				// Only do this check for non primary targets
				if ( [target cachedGUID] == [originalTarget cachedGUID] ) continue;

				if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {

					if ( !matchFound ) {
						matchFound = YES;
						bestUnit = target;
					}
					
					int weight = [combatController weight: target PlayerPosition:playerPosition];
					if ( weight > highestWeight ) {
						highestWeight = weight;
						bestUnit = target;
					}
				}
			}

			if ( matchFound ) {
				// do something
				target = bestUnit;
				log(LOG_RULE, @"Match for %@ with add %@", rule, target);
				break;
			}
		}

		// Pat
		else if ( [rule target] == TargetPat ) {

			if (!pats) pats = [combatController enemiesWithinRange:attackRange];
			Unit *bestUnit = nil;
			int highestWeight = -1000;

			for ( target in pats ){

				// Only do this check for non primary targets
				if ( [target cachedGUID] == [originalTarget cachedGUID] ) continue;

				// If it's in combat it's an add, not a pat
				if ( [target isInCombat] ) continue;

				if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {

					if ( !matchFound ) {
						matchFound = YES;
						bestUnit = target;
					}

					int weight = [combatController weight: target PlayerPosition:playerPosition];
					if ( weight > highestWeight ) {
						highestWeight = weight;
						bestUnit = target;
					}
				}
			}

			if ( matchFound ) {
				// do something
				target = bestUnit;
				log(LOG_RULE, @"Match for %@ with pat %@", rule, target);
				break;
			}
		}

		if ( matchFound ) break;

		// Reset the target
		if ( [target cachedGUID] != [originalTarget cachedGUID] ) target = originalTarget;
	}

	// Raise the dead?
	if ( !matchFound && theCombatProfile.healingEnabled && _includeCorpsesPatrol) {
		NSMutableArray *units = [NSMutableArray array];
		[units addObjectsFromArray: [combatController friendlyCorpses]];
		
		for ( target in units ) {
			if ( ![target isPlayer] || ![target isDead] ) continue;
			
			if ( [blacklistController isBlacklisted: target] ) continue;
			
			if ( [playerPosition distanceToPosition:[target position]] > theCombatProfile.healingRange ) continue;							
			
			if ( [playerPosition verticalDistanceToPosition: [target position]] > vertOffset) continue;
			
			// player: make sure they're not a ghost
			NSArray *auras = [auraController aurasForUnit: target idsOnly: YES];
			if (	[auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || 
					[auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ) continue;

			if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
				log(LOG_RULE, @"Found match for resurrection in patrolling with rule %@", rule);
				matchFound = YES;
				wasResurrected = YES;
				break;
			}
		}
	}

	// take the action here
	if ( matchFound && rule ) {

		// Dismount if mounted.
		if ( [player isMounted] ) [movementController dismount];

		// Set the castingUnit
		if ( target && [rule target] != TargetNone ) {

			if ( !_castingUnit || _castingUnit == nil ) {
				_castingUnit = [(Unit*)target retain];
			} else
				if ( [(Unit*)target cachedGUID] != [_castingUnit cachedGUID] ) {
					[_castingUnit release]; _castingUnit = nil;
					_castingUnit = [(Unit*)target retain];
				}
		}

		// Just in case, we need something to throw to notifications.
		if ( !_castingUnit || _castingUnit == nil ) _castingUnit = [(Unit*)player retain];
		
		NSString *resultType = @"No Action";
		if( rule.action.type == ActionType_Spell) resultType = @"Cast Spell";
		if( rule.action.type == ActionType_Item) resultType = @"Use Item";
		if( rule.action.type == ActionType_Macro) resultType = @"Use Macro";

		if ( [rule resultType] > 0 ) {
			int32_t actionID = [rule actionID];
			
			if ( actionID > 0 ) {
				BOOL canPerformAction = YES;
				// if we are using an item or macro, apply a mask to the item number
				switch([rule resultType]) {
					case ActionType_Item: 
						actionID = (USE_ITEM_MASK + actionID);
						break;
					case ActionType_Macro:
						actionID = (USE_MACRO_MASK + actionID);
						break;
					case ActionType_Spell:
						canPerformAction = ![spellController isSpellOnCooldown: actionID];
						break;
					default:
						break;
				}

				// lets do the action
				if ( canPerformAction ) {

					// Target and begin monitoring from the combatController if needed!
					if ( [rule target] == TargetNone ) {
						[combatController stayWithUnit:_castingUnit withType: TargetNone];
					} else 

					// Target and begin monitoring from the combatController if needed!
					if ( [rule target] == TargetSelf ) {
						if ( !playerTargetID || playerTargetID != [player cachedGUID] ) {
							log(LOG_DEV, @"Targeting self.");
							[playerController targetGuid:[[playerController player] cachedGUID]];
						}
						[combatController stayWithUnit:_castingUnit withType: TargetSelf];
					} else 

					if ( [rule target] == TargetEnemy ) {
						if ( !playerTargetID || playerTargetID != [_castingUnit cachedGUID] ) {
							log(LOG_DEV, @"Targeting Enemy.");
							[playerController targetGuid:[_castingUnit cachedGUID]];
						}
						[combatController stayWithUnit:_castingUnit withType: TargetEnemy];
					} else

					if ( [rule target] == TargetFriend ) {
						if ( !playerTargetID || playerTargetID != [_castingUnit cachedGUID] ) {
							log(LOG_DEV, @"Targeting friend.");
							[playerController targetGuid:[_castingUnit cachedGUID]];
						}
						[combatController stayWithUnit:_castingUnit withType: TargetFriend];
					} else

					if ( [rule target] == TargetAdd ) {
						if ( !playerTargetID || playerTargetID != [_castingUnit cachedGUID] ) {
							log(LOG_DEV, @"Targeting Add.");
							[playerController targetGuid:[_castingUnit cachedGUID]];

						}
						[combatController stayWithUnit:_castingUnit withType: TargetAdd];
					} else

					if ( [rule target] == TargetPet ) {
						if ( !playerTargetID || playerTargetID != [_castingUnit cachedGUID] ) {
							log(LOG_DEV, @"Targeting Pat.");
							[playerController targetGuid:[_castingUnit cachedGUID]];
						}
						[combatController stayWithUnit:_castingUnit withType: TargetPet];
					} else

					if ( [rule target] == TargetFriendlies ) {
						if ( !playerTargetID || playerTargetID != [_castingUnit cachedGUID] ) {
							log(LOG_DEV, @"Targeting friend.");
							[playerController targetGuid:[_castingUnit cachedGUID]];
						}
						[combatController stayWithUnit:target withType: TargetFriendlies];
					}

					if ( [rule target] == TargetPat ) {
						if ( !playerTargetID || playerTargetID != [_castingUnit cachedGUID] ) {
							log(LOG_DEV, @"Targeting Pat.");
							[playerController targetGuid:[_castingUnit cachedGUID]];
						}
						[combatController stayWithUnit:_castingUnit withType: TargetPat];
					}

					// See if we need to send the pet in
					if ( [[self procedureInProgress] isEqualToString: CombatProcedure] &&
						completed == 0 &&														// First loop only
						![playerController isFriendlyWithFaction: [target factionTemplate]]		// It's a hostile target
						) {
						if ( theBehavior.useStartAttack ) {
							[macroController useMacroOrSendCmd:@"StartAttack"];
							usleep( [controller refreshDelay] );
						}
						if ( theBehavior.usePet &&  
							[playerController pet] && ![[playerController pet] isDead] &&
							[[playerController pet] targetID] != [_castingUnit cachedGUID]		// Your pet is not already targeting this target
							) {
							log(LOG_PROCEDURE, @"Sending the pet in!");
							[bindingsController executeBindingForKey:BindingPetAttack];
							usleep( [controller refreshDelay] );
						}
					}

					NSString *ruleFormatted = [NSString stringWithFormat: @"\"%@\"  %@ (%@)>", [rule name], resultType, rule.action.value];
								
					if ( [rule target] == TargetNone || [rule target] == TargetSelf) {
						log(LOG_PROCEDURE, @"%@ %@ %@", [combatController unitHealthBar:player], player, ruleFormatted );
					} else {
						log(LOG_COMBAT, @"%@ %@ %@", [combatController unitHealthBar:_castingUnit], _castingUnit, ruleFormatted );
					}
					
					// If this is a new action we reset the attempts
					if ( _lastSpellCast != actionID ) attempts = 1;
						else attempts++;

					// do it!
					int lastErrorMessage = [self performAction:actionID];
					log(LOG_DEV, @"Action %u taken with result: %d", actionID, lastErrorMessage);

					// error of some kind :/
					if ( lastErrorMessage != ErrNone ) {

						BOOL resetCastingUnit = NO;

						// On some errors we bail as notifications will restart evaluation.
						if ( lastErrorMessage == ErrTargetNotInLOS ) resetCastingUnit = YES;
						else if ( lastErrorMessage == ErrInvalidTarget ) resetCastingUnit = YES;
						else if ( lastErrorMessage == ErrHaveNoTarget ) resetCastingUnit = YES;
						else if ( lastErrorMessage == ErrTargetOutRange ) resetCastingUnit = YES;
						else if ( lastErrorMessage == ErrTargetDead ) resetCastingUnit = YES;
						else if ( lastErrorMessage == ErrMorePowerfullSpellActive ) resetCastingUnit = YES;
						else if ( lastErrorMessage == ErrCantDoThatWhileStunned || lastErrorMessage ==  ErrCantDoThatWhileSilenced || ErrCantDoThatWhileIncapacitated ) resetCastingUnit = YES;

						if ( resetCastingUnit ) return;

						log(LOG_DEV, @"Attempted to do %u on %@ %d %d times", actionID, target, attempts, completed);

						NSString *triedRuleKey = [NSString stringWithFormat:@"%d_0x%qX", i, [target cachedGUID]];
						log(LOG_DEV, @"Looking for key %@", triedRuleKey);

						NSNumber *tries = [rulesTried objectForKey:triedRuleKey];
						
						if ( tries ) {
							int t = [tries intValue];
							tries = [NSNumber numberWithInt:t+1];
						} else {
							tries = [NSNumber numberWithInt:1];
						}

						log(LOG_DEV, @"Setting tried %@ with value %@", triedRuleKey, tries);
						[rulesTried setObject:tries forKey:triedRuleKey];
					} else {

					// success!
						completed++;
						actionsPerformed++;
					}
					
				} else {
					log(LOG_PROCEDURE, @"Unable to perform action %d", actionID);
				}
			} else {
				log(LOG_PROCEDURE, @"No action to take");
			}
		} else {
			log(LOG_PROCEDURE, @"No result type");
		}

		// If we resurected them lets give them a moment to repop before we assess them again
		if (wasResurrected && [playerController isFriendlyWithFaction: [target factionTemplate]] && [target isValid]) {
			log(LOG_DEV, @"Adding resurrection CD to %@", target);
			[blacklistController blacklistObject:target withReason:Reason_RecentlyResurrected];
		}

		// Mount in Patrolling
		if( [[state objectForKey: @"Procedure"] isEqualToString: PatrollingProcedure] ) {

			NSString *mountPlain = @"mount";
			NSString *mountAtStart = @"mount *";

			NSPredicate *predicateMountPlain = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", mountPlain];
			NSPredicate *predicateMountAtStart = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", mountAtStart];

				if ( [predicateMountPlain evaluateWithObject: [rule name]] || [predicateMountAtStart evaluateWithObject: [rule name]]) {
					log(LOG_PROCEDURE, @"Player has mounted.");
					[self performSelector: @selector(finishCurrentProcedure:) withObject: state afterDelay: 2.0f];
					return;
				}
		}

		log(LOG_DEV, @"Rule executed, trying more rules.");

		// if we found a match, try again until we can't anymore!
		[self performSelector: _cmd
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
								[state objectForKey: @"Procedure"],				@"Procedure",
								[NSNumber numberWithInt: completed],			@"CompletedRules",
								[NSNumber numberWithInt: attempts],				@"RuleAttempts",
								rulesTried,										@"RulesTried",		// track how many times we've tried each rule
								[NSNumber numberWithInt:actionsPerformed],		@"ActionsPerformed",
								originalTarget,									@"Target", nil]
				   afterDelay:	0.3f];
		return;
	}

	// If we can't perform any rules, but we're still in combat with a hostile we do not break procedure.
	if ( _castingUnit && [_castingUnit isValid] && ![playerController isFriendlyWithFaction: [_castingUnit factionTemplate]] ) {
		if  ( ![self performProcedureUnitCheck: _castingUnit withState:state] ) return;
		[self performSelector: _cmd
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
								CombatProcedure,				@"Procedure",
								[NSNumber numberWithInt: 0],	@"CompletedRules",
								_castingUnit,					@"Target", nil]
		 
				   afterDelay:	0.3f];
		return;
	}

	log(LOG_DEV, @"Done with Procedure!");
	[self finishCurrentProcedure: state];
}

// This is a pre cast check for targets.
- (BOOL)performProcedureUnitCheck: (Unit*)target withState:(NSDictionary*)state {
	log(LOG_DEV, @"performProcedureUnitCheck: %@", target);

	if ( [playerController isDead] || [[playerController player] percentHealth] == 0 ) {
		log(LOG_PROCEDURE, @"Player is dead! Aborting!");
		[self cancelCurrentProcedure];
		return NO;
	}

	// If targeting ourselves then return.
	if ( [target cachedGUID] == [[playerController player] cachedGUID] ) return YES;

	// If targeting none then return.
	if ( !target || target == nil ) return YES;

	if ( [blacklistController isBlacklisted: target] ) {
		log(LOG_PROCEDURE, @"unitCheck: Target blacklisted!");
		[self finishCurrentProcedure: state];
		return NO;
	}

	if ( ![target isValid] ) {
		log(LOG_PROCEDURE, @"unitCheck: Target not valid!");
		[combatController cancelAllCombat];
		[self finishCurrentProcedure: state];
		return NO;
	}

	if ( ![[self procedureInProgress] isEqualToString: PatrollingProcedure] && [target isPlayer] ) {
		NSArray *auras = [auraController aurasForUnit: target idsOnly: YES];
		if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ) {

			// If they're friendly
			if ( [playerController isFriendlyWithFaction: [target factionTemplate]] ) {
				log(LOG_PROCEDURE, @"unitCheck: Target is a Ghost!");
				[self finishCurrentProcedure: state];
				return NO;
			} else {
			// Hostile
				log(LOG_PROCEDURE, @"unitCheck: Target is a Ghost, must have killed player.");
				[self finishCurrentProcedure: state];
				return NO;
			}
		}
	}

	if ( [target isDead] || [target percentHealth] <= 0 ) {
		log(LOG_PROCEDURE, @"unitCheck: Target dead!");
		[self finishCurrentProcedure: state];
		return NO;
	}

	// Range Checks
	float distanceToTarget = [[playerController position] distanceToPosition: [target position]];
	float range = 0.0f;

	// PreCombat checks (if we're not in combat yet we disengage faster, we also do NOT finishProcedure)
	if ( [[self procedureInProgress] isEqualToString: PreCombatProcedure] ) {

		// Friendly
		if ( [playerController isFriendlyWithFaction: [target factionTemplate]] ) {

			if ( theCombatProfile.attackRange > theCombatProfile.healingRange) range = theCombatProfile.attackRange;
				else range = theCombatProfile.healingRange;

			if ( distanceToTarget > range ) {
				log(LOG_PROCEDURE, @"unitCheck: Friendly target (%0.2f) out of range (%0.2f) in precombat!", distanceToTarget, range);
				[self cancelCurrentProcedure];
				[self performSelector:@selector(evaluateSituation) withObject:nil afterDelay: 0.25f];
				return NO;
			}
		} else {
		// Hostile
			range = theCombatProfile.attackRange;
			if ( distanceToTarget > range ) {
				log(LOG_PROCEDURE, @"unitCheck: Hostile target (%0.2f) out of range (%0.2f) in precombat!", distanceToTarget, range);
				[self cancelCurrentProcedure];
				[self performSelector:@selector(evaluateSituation) withObject:nil afterDelay: 0.25f];
				return NO;
			}
		}
		
	}

	// Patrolling checks (if we're not in combat we disengage faster)
	if ( [[self procedureInProgress] isEqualToString: PatrollingProcedure] ) {

		// Friendly
		if ( [playerController isFriendlyWithFaction: [target factionTemplate]] ) {
			if ( theCombatProfile.attackRange > theCombatProfile.healingRange) range = theCombatProfile.attackRange;
				else range = theCombatProfile.healingRange;

			if ( distanceToTarget > range ) {
				log(LOG_PROCEDURE, @"unitCheck: Friendly target (%0.2f) out of range (%0.2f) in patrolling phase!", distanceToTarget, range);
				[self cancelCurrentProcedure];
				[self performSelector:@selector(evaluateSituation) withObject:nil afterDelay: 0.25f];
				return NO;
			}
		}
	}

	return YES;
}

- (BOOL)performAction: (int32_t) actionID{
	MemoryAccess *memory = [controller wowMemoryAccess];

	if ( !memory ) return NO;

	int barOffset = [bindingsController castingBarOffset];
	if ( barOffset == -1 ){
		log(LOG_ERROR, @"Unable to execute spells! Ahhhhh! Issue with bindings!");
		return NO;
	}

	UInt32 oldActionID = 0;

	// save the old spell + write the new one
	[memory loadDataForObject: self atAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + barOffset) Buffer: (Byte *)&oldActionID BufLength: sizeof(oldActionID)];
	[memory saveDataForAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + barOffset) Buffer: (Byte *)&actionID BufLength: sizeof(actionID)];
	
	// write gibberish to the error location
	char string[3] = {'_', '_', '\0'};
	[[controller wowMemoryAccess] saveDataForAddress: [offsetController offset:@"LAST_RED_ERROR_MESSAGE"] Buffer: (Byte *)&string BufLength:sizeof(string)];
	
	// wow needs time to process the spell change
	usleep( [controller refreshDelay] );

	// send the key command
	[bindingsController executeBindingForKey:BindingPrimaryHotkey];
	_lastSpellCastGameTime = [playerController currentTime];

	// make sure it was a spell and not an item/macro
	if ( !((USE_ITEM_MASK & actionID) || (USE_MACRO_MASK & actionID)) ){
		_lastSpellCast = actionID;
	} else {
		_lastSpellCast = 0;
	}
 
	// wow needs time to process the spell change
	usleep( [controller refreshDelay] *2 );

	// then save our old action back
	// Use a delay to set off the reset
	_oldActionID = oldActionID;
	_oldBarOffset = barOffset;
	
	// We don't want to check lastAttemptedActionID if it's not a spell!
	BOOL wasSpellCast = YES;
	if ( (USE_ITEM_MASK & actionID) || (USE_MACRO_MASK & actionID) ) {
		wasSpellCast = NO;
	}

	_lastActionTime = [playerController currentTime];
	NSString *lastErrorMessageString = [[playerController lastErrorMessage] retain];
	int lastErrorMessage = [self errorValue:lastErrorMessageString];
	
	[self performSelector: @selector(resetHotBarAction) withObject: nil  afterDelay: 0.1f];

	BOOL errorFound = NO;

	if ( ![lastErrorMessageString isEqualToString: @"__"] && lastErrorMessage != ErrYouAreTooFarAway ) {
		errorFound = YES;
	}

	// check for an error
//	if ( ( wasSpellCast && [spellController lastAttemptedActionID] == actionID ) || errorFound ) {
//	if ( errorFound ) {
	if ( wasSpellCast && errorFound ) {

		_lastActionErrorCode = lastErrorMessage;
		log(LOG_PROCEDURE, @"%@ %@ Spell %d didn't cast: %@", [combatController unitHealthBar: _castingUnit], _castingUnit,  actionID, lastErrorMessageString );

		// do something?
/*
 nothing actually uses this notification so I'm uncommenting for now
		if ( lastErrorMessage == ErrSpellNot_Ready) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorSpellNotReady object: [[_castingUnit retain] autorelease]];
		}
		else 
 */
		if ( lastErrorMessage == ErrTargetNotInLOS ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorTargetNotInLOS object: [[_castingUnit retain] autorelease]];
		}
		else if ( lastErrorMessage == ErrInvalidTarget ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorInvalidTarget object: [[_castingUnit retain] autorelease]];
		}
		else if ( lastErrorMessage == ErrHaveNoTarget ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorHaveNoTarget object: [[_castingUnit retain] autorelease]];
		}
		else if ( lastErrorMessage == ErrTargetOutRange ){
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorTargetOutOfRange object: [[_castingUnit retain] autorelease]];
		}
		else if ( lastErrorMessage == ErrTargetNotInFrnt || lastErrorMessage == ErrWrng_Way ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorTargetNotInFront object: [[_castingUnit retain] autorelease]];
		}
// Let the combat controller monitor handle this one...
//		else if ( lastErrorMessage == ErrTargetDead ) {
//			[[NSNotificationCenter defaultCenter] postNotificationName: UnitDiedNotification object: [[_castingUnit retain] autorelease]];
//		}
		else if ( lastErrorMessage == ErrMorePowerfullSpellActive ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorMorePowerfullSpellActive object: [[_castingUnit retain] autorelease]];
		}
		else if ( lastErrorMessage == ErrCantDoThatWhileStunned || lastErrorMessage ==  ErrCantDoThatWhileSilenced || ErrCantDoThatWhileIncapacitated ) {
			[[NSNotificationCenter defaultCenter] postNotificationName: ErrorCantDoThatWhileStunned object: [[_castingUnit retain] autorelease]];
		}
		else if ( lastErrorMessage == ErrCantAttackMounted || lastErrorMessage == ErrYouAreMounted ) {
			if ( [playerController isOnGround] ) [movementController dismount];
		}
		// do we need to log out?
		else if ( lastErrorMessage == ErrInventoryFull ) {
			if ( [logOutOnFullInventoryCheckbox state] )
				[self logOutWithMessage:@"Inventory full, closing game"];
		}

		log(LOG_DEV, @"Action taken with error! Result: %d", lastErrorMessage);
		[lastErrorMessageString release];
		return lastErrorMessage;
	}

	log(LOG_DEV, @"Action taken successfully.");
	[lastErrorMessageString release];
	return ErrNone;
}

-(void)resetHotBarAction {
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory ) return;

	// Save our old action back
	[memory saveDataForAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + _oldBarOffset) Buffer: (Byte *)&_oldActionID BufLength: sizeof(_oldActionID)];
}

- (void)monitorRegen: (NSDate*)start {
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
	log(LOG_FUNCTION, @"monitorRegen");

	Unit *player = [playerController player];
	BOOL eatClear = NO, drinkClear = NO;

	// check health
	if ( [playerController health] == [playerController maxHealth] ) eatClear = YES;
	// no buff for eating anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Food"] ) eatClear = YES;
	
	// check mana
	if ( [playerController mana] == [playerController maxMana] ) drinkClear = YES;
	// no buff for drinking anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Drink"] ) drinkClear = YES;
	
	float timeSinceStart = [[NSDate date] timeIntervalSinceDate: start];

	// we're done eating/drinking! continue
	if ( eatClear && drinkClear ) {
		log(LOG_REGEN, @"Finished after %0.2f seconds.", timeSinceStart);
		if ([[playerController player] isSitting]) [movementController establishPlayerPosition];
		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[controller setCurrentStatus: @"Bot: Enabled"];		
		[self performSelector:@selector(evaluateSituation) withObject:nil afterDelay: 0.25f];
		return;
	} else 
		// should we be done?
		if ( timeSinceStart > 30.0f ) {
			log(LOG_REGEN, @"Ran for 30, done, regen too long!?");
			if ([[playerController player] isSitting]) [movementController establishPlayerPosition];
			[self cancelCurrentProcedure];
			[self cancelCurrentEvaluation];
			[self resetLootScanIdleTimer];
			[controller setCurrentStatus: @"Bot: Enabled"];
			[self performSelector:@selector(evaluateSituation) withObject:nil afterDelay: 0.25f];
			return;
		}
	// Check to see if we neet to start recording
	[self followRouteStartRecord];
	[self performSelector: @selector(monitorRegen:) withObject: start afterDelay: 0.5f];
}

#pragma mark -
#pragma mark [Input] MovementController

- (void)reachedFollowUnit: (NSNotification*)notification {

	[self followRouteClear];

	if ( !self.isBotting ) return;
	if ( [playerController isDead] ) return;

	log(LOG_FUNCTION, @"botController: reachedFollowUnit");

	// Reset the movement controller.  Do we need to switch back to a normal route ?

	// Reset the party emotes idle
	if ( theCombatProfile.partyEmotes ) _partyEmoteIdleTimer = 0;

	log(LOG_FOLLOW, @"Stopping Follow, reached our target.");

	[controller setCurrentStatus: @"Bot: Enabled"];
	[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
}

- (void)reachedObject: (NSNotification*)notification {

	if ( !self.isBotting ) return;

	if ( self.evaluationInProgress == @"Follow" ) self.evaluationInProgress = nil;

	_movingToCorpse = NO;

	if ( ![notification object] ) {
		log(LOG_FUNCTION, @"Reached object called for reach position.");
		// Back to evaluation
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return;
	}

	WoWObject *object = [notification object];

	log(LOG_FUNCTION, @"Reached object called for %@", object);

	// if it's a player, or a non-dead NPC, we must be doing melee combat
	if ( [object isPlayer] || ([object isNPC] && ![(Unit*)object isDead]) ) log(LOG_DEV, @"Reached melee range with %@", object);

	// Reset the party emotes idle
	if ( theCombatProfile.partyEmotes ) _partyEmoteIdleTimer = 0;

	// Back to evaluation
	[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay: 0.25f];
}

// should the notification be here?  or in movementcontroller?
- (void)finishedRoute: (Route*)route {

    if( !self.isBotting ) return;

    if ( !self.theRouteSet || self.pvpIsInBG ) return;

	if ( route != [self.theRouteSet routeForKey: CorpseRunRoute] ) return;

	log(LOG_GHOST, @"Finished Corpse Run. Begin search for body...");
	[controller setCurrentStatus: @"Bot: Searching for body..."];
}

#pragma mark [Input] CombatController

- (void)unitEnteredCombat: (NSNotification*)notification {

	if ( !self.isBotting ) return;
	if ( [playerController isDead] ) return;

	Unit *unit = [notification object];

	log(LOG_DEV, @"%@ %@ entered combat!", [combatController unitHealthBar:unit], unit);

	// If we're supposed to ignore combat while flying
	if (self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted]) {
		log(LOG_DEV, @"Ignoring combat with %@ since we're set to ignore combat while flying.", unit);
		return;
	}

	// If we're in follow mode let's keep cruisin till we catch up to the leader.
	if ( self.evaluationInProgress == @"Follow" ) {
		log(LOG_DEV, @"Ignoring combat with %@ since we're trying to get to our leader.", unit);
		return;		
	}

	// If we're in follow mode let's keep cruisin till we catch up to the leader.
	if ( !theCombatProfile.combatEnabled ) {
		log(LOG_DEV, @"Ignoring combat with %@ since we're not set to attack.", unit);
		return;
	}

	// start a combat procedure if we're not in one!
	if ( self.procedureInProgress != @"CombatProcedure" && self.procedureInProgress != @"PreCombatProcedure" ) {

		// If it's a player attacking us lets attack the player!
		if ( [unit isPlayer] ) {
			log(LOG_COMBAT, @"%@ %@ has jumped me, Targeting Player!", [combatController unitHealthBar:unit], unit);
		} else {
			log(LOG_COMBAT, @"%@ %@ has ambushed me, taking action!", [combatController unitHealthBar:unit], unit);
		}

		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[combatController cancelCombatAction];

		if ( [movementController isActive] ) [movementController resetMovementState];

		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return;
	}

	// We are already in combat
	
	// If it's a player attacking us and we're on a mob then lets attack the player!
	if ( ( [[combatController castingUnit] isKindOfClass: [Mob class]] || [[combatController castingUnit] isPet] ) &&
			[combatController combatEnabled] &&
			!theCombatProfile.healingEnabled &&
			[unit isPlayer] ) {

		// Just to make testing obvious...
		if ( [unit isPlayer] && [playerController isFriendlyWithFaction: [unit factionTemplate]] ) 
			log(LOG_ERROR, @"Are we about to attack a friendly!?");

		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[combatController cancelCombatAction];
		if ( [movementController isActive] ) [movementController resetMovementState];


		log(LOG_COMBAT, @"%@ %@ has jumped me while killing a mob, Targeting Player!", [combatController unitHealthBar:unit], unit);
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return;
	}

	// Check player vs player weight to see if we need to change targets
	if ( [unit isPlayer] ) {
		Position *playerPosition = [playerController position];
		int weightNewTarget = [combatController weight: unit PlayerPosition:playerPosition];
		int weightCurrentTarget = [combatController weight: self.castingUnit PlayerPosition:playerPosition];
		if ( weightNewTarget > weightCurrentTarget ) {
			[self cancelCurrentProcedure];
			[self cancelCurrentEvaluation];
			[combatController cancelCombatAction];
			if ( [movementController isActive] ) [movementController resetMovementState];
			log(LOG_COMBAT, @"%@ %@ has jumped me while killing a player, Targeting Player with higher weight!", [combatController unitHealthBar:unit], unit);
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return;
		}
	}

	if ( [unit isPlayer] && [self castingUnit] && [playerController isFriendlyWithFaction: [[self castingUnit] factionTemplate]] ) {
		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[combatController cancelCombatAction];
		if ( [movementController isActive] ) [movementController resetMovementState];
		log(LOG_COMBAT, @"%@ %@ has jumped me while healing a player, Targeting Hostile Player!", [combatController unitHealthBar:unit], unit);
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return;
	}

	log(LOG_DEV, @"Already in combat procedure! Not acting on unit");
}

- (void)playerEnteringCombat: (NSNotification*)notification {

	if ( !self.isBotting ) return;
	if ( [playerController isDead] || [playerController percentHealth] == 0 ) return;

	log(LOG_DEV, @"Entering combat");
	[blacklistController clearAttempts];

	// If we're supposed to ignore combat while flying
	if ( self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted] ) {
		log(LOG_DEV, @"Ignoring combat since we're set to ignore combat while flying.");
		return;
	}

	// If we're in follow mode let's keep cruisin till we catch up to the leader.
	if ( [[playerController player] isMounted] && self.evaluationInProgress == @"Follow" ) {
		log(LOG_DEV, @"Ignoring combat since we're trying to get to our leader.");
		return;
	}

	// If we're not running combat then let's stop what we're doing and get to it!
	if ( self.procedureInProgress != @"CombatProcedure" && self.procedureInProgress != @"PreCombatProcedure" ) {
		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		if ( [movementController isActive] ) [movementController resetMovementState];
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
	}
}

- (void)playerLeavingCombat: (NSNotification*)notification {

	if ( !self.isBotting ) return;

	_didPreCombatProcedure = NO;

	if ( [playerController isDead] ) return;

	[self resetLootScanIdleTimer];

	log(LOG_COMBAT, @"Left combat! Current procedure: %@  Last executed: %@", self.procedureInProgress, _lastProcedureExecuted);

	[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];

}

#pragma mark [Input] PlayerData

- (void)playerHasRevived: (NSNotification*)notification {

    if ( !self.isBotting ) return;

    log(LOG_GENERAL, @"---- Player has revived ----");
    [controller setCurrentStatus: @"Bot: Player has Revived"];

	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];
	if ( [movementController isActive] ) [movementController resetMovementState];

	_ghostDance = 0;
	if ( [self pvpSetEnvironmentForZone] ) {
		log(LOG_PVP, @"Environment Set.");
	}

	[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
}

- (void)playerHasDied: (NSNotification*)notification {

    if( !self.isBotting ) return;

    log(LOG_GHOST, @"---- Player has died ----");
    [controller setCurrentStatus: @"Bot: Player has Died"];

	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];
	[self followRouteClear]; 
	if ( _followUnit ) [_followUnit release]; _followUnit = nil;

	if ( [_mobsToLoot count] ) [_mobsToLoot removeAllObjects];
	[movementController resetMovementState];

	// If we're following a flag carrier lets make sure they still have the buff
	if ( _followingFlagCarrier ) {
		_followingFlagCarrier = NO;
		[_followUnit release]; _followUnit = nil;
	}

	if ( ![playerController playerIsValid:self] ) return;

	// Check to see if we need to blacklist a node for making us die
	if ( theCombatProfile.resurrectWithSpiritHealer && 
		self.lastAttemptedUnitToLoot && 
		_movingTowardNodeCount > 0 && 
		[self.lastAttemptedUnitToLoot isValid] 
		) {
		log(LOG_NODE, @"%@ made me die, blacklisting.", self.lastAttemptedUnitToLoot);
		[blacklistController blacklistObject: self.lastAttemptedUnitToLoot withReason:Reason_NodeMadeMeDie];
	}

    // send notification to Growl
    if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
		[GrowlApplicationBridge notifyWithTitle: @"Player Has Died!"
									description: @"Sorry :("
							   notificationName: @"PlayerDied"
									   iconData: [[NSImage imageNamed: @"Ability_Warrior_Revenge"] TIFFRepresentation]
									   priority: 0
									   isSticky: NO
								   clickContext: nil];
    }

	// Try to res in a second! (give the addon time to release if they're using one!) - they can disable release in the settings if they need
    [self performSelector: @selector(corpseRelease:) withObject: [NSNumber numberWithInt:0] afterDelay: 0.25f];

	// Play an alarm after we die?
	if ( [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnDeath"] boolValue] ){
		[[NSSound soundNamed: @"alarm"] play];
		log(LOG_GHOST, @"Playing alarm, you have died!");
	}
}

- (void)moveAfterRepop {

	if ( !self.isBotting ) return;

	// don't move if we're in a BG
	if ( self.pvpIsInBG ) return;

	if ( [playerController isDead] && [playerController isGhost] ) {
		log(LOG_DEV, @"We're dead, evaluating.");
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
	}
}

- (void)corpseRelease: (NSNumber *)count {
	
	if ( !self.isBotting ) return;
	if ( ![playerController playerIsValid:self] ) return;

	if ( theCombatProfile.disableRelease ) {
		log(LOG_GHOST, @"Ignoring release due to a combat setting");
		return;
	}

	// We need to repop!
	if ( ![playerController isGhost] && [playerController isDead] ) {

		// Reset the loot scan idle timer
		if ( theCombatProfile.ShouldLoot ) [self resetLootScanIdleTimer];

		int try = [count intValue];

		// ONLY stop bot if we're not in PvP (we'll auto res in PvP!)
		if (++try > 25 && !self.isPvPing && !self.pvpIsInBG ) {
			log(LOG_GHOST, @"Repop failed after 10 tries.  Stopping bot.");
			[self stopBot: nil];
			[controller setCurrentStatus: @"Bot: Failed to Release. Stopped."];
			return;
		}

		if ( try != 1 ) {
			log(LOG_GHOST, @"Releasing (%d attempts).", try);
		} else {
			log(LOG_GHOST, @"Releasing.");
		}

		[macroController useMacroOrSendCmd:@"ReleaseCorpse"];

		// Try again every few seconds
		[self performSelector: @selector(corpseRelease:) withObject: [NSNumber numberWithInt:try] afterDelay: 1.0];
		return;
	}

	[self moveAfterRepop];
}

- (void)playerIsInvalid: (NSNotification*)not {

    if ( !self.isBotting ) return;
	log(LOG_GENERAL, @"Player is no longer valid.");

	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];

	[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];

}

#pragma mark [Input] BotController

- (void)unitDied: (NSNotification*)notification {
	if ( !self.isBotting ) return;
	if ( [playerController isDead] ) return;

	Unit *unit = [notification object];

	log(LOG_COMBAT, @"Unit %@ killed (%@).", unit, [unit class]);

	if ( [unit isPlayer] ) {
		if ( !theCombatProfile.ShouldLoot ) return;
		log(LOG_DEV, @"Player killed, flags: %d %d", [(Mob*)unit isTappedByMe], [(Mob*)unit isLootable] );
	}

	if ( [unit isNPC] ) log(LOG_DEV, @"NPC killed, flags: %d %d", [(Mob*)unit isTappedByMe], [(Mob*)unit isLootable] );

	if ( theCombatProfile.ShouldLoot && [unit isNPC] ) {

		// Reset the loot scan idle timer
		[self resetLootScanIdleTimer];

		if ( ( [(Mob*)unit isTappedByMe] || [(Mob*)unit isLootable] ) && ![unit isPet] ) {
			log(LOG_LOOT, @"Adding %@ to loot list.", unit);
			if ( ![_mobsToLoot containsObject: unit]) [_mobsToLoot addObject: (Mob*)unit];

			if ( ![[combatController unitsAttackingMe] count] && [_mobsToLoot count] == 1 ) {

				if ( ![movementController isMoving] && [[playerController position] distanceToPosition:[unit position]] > 4.0f) {
					[movementController moveToObject: unit];
					return;
				}
				if ( [_mobsToLoot count] == 0 ) [self lootScan];
			}
		}
	}

}

// invalid target
- (void)invalidTarget: (NSNotification*)notification {
	if ( !self.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] Invalid Target (botController): %@", unit);

	// reset!
	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];

	//Call back the pet if needed
	if ( [self.theBehavior usePet] && [playerController pet] && ![[playerController pet] isDead] ) [macroController useMacroOrSendCmd:@"PetFollow"];

	log(LOG_DEV, @"Targeting self.");
	[playerController targetGuid:[[playerController player] cachedGUID]];

	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
}

// have no target
- (void)haveNoTarget: (NSNotification*)notification {
	if ( !self.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] No Target (botController): %@", unit);

	// reset!
	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];

	//Call back the pet if needed
	if ( [self.theBehavior usePet] && [playerController pet] && ![[playerController pet] isDead] ) [macroController useMacroOrSendCmd:@"PetFollow"];

	log(LOG_DEV, @"Targeting self.");
	[playerController targetGuid:[[playerController player] cachedGUID]];

	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
}

// not in LoS
- (void)targetNotInLOS: (NSNotification*)notification {
	if ( !self.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] Not in LoS (botController): %@", unit);

	// reset!
	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];

	//Call back the pet if needed
	if ( [self.theBehavior usePet] && [playerController pet] && ![[playerController pet] isDead] ) [macroController useMacroOrSendCmd:@"PetFollow"];

	log(LOG_DEV, @"Targeting self.");
	[playerController targetGuid:[[playerController player] cachedGUID]];

	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
}

- (void)morePowerfullSpellActive: (NSNotification*)notification {
	if ( !self.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] More powerful spell active (botController): %@", unit);

	log(LOG_ERROR, @"You need to adjust your behavior so the previous spell doesn't cast if the player has a more powerfull buff!");

	// reset!
	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];

	log(LOG_DEV, @"Targeting self.");
	[playerController targetGuid:[[playerController player] cachedGUID]];

	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
}

- (void)cantDoThatWhileStunned: (NSNotification*)notification {
	if ( !self.isBotting ) return;
	Unit *unit = [notification object];

	log(LOG_DEV, @"[Notification] Cant do that while stunned (botController): %@", unit);

	// reset!
	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];

	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
}

#pragma mark -
#pragma mark Combat

- (BOOL)includeFriendlyInCombat {

	// should we include friendly units?
	if ( self.theCombatProfile.healingEnabled ) return YES;

	// if we have friendly spells in our Combat Behavior lets return true
	Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
    int i;
    for ( i = 0; i < [procedure ruleCount]; i++ ) {
		Rule *rule = [procedure ruleAtIndex: i];
		if ( [rule target] == TargetFriend || [rule target] == TargetFriendlies ) return YES;
	}
	return NO;
}

- (BOOL)includeFriendlyInPatrol {	
	
	// should we include friendly units?
	
	// if we have friendly spells in our Patrol Behavior lets return true
	Procedure *procedure = [self.theBehavior procedureForKey: PatrollingProcedure];
    int i;
    for ( i = 0; i < [procedure ruleCount]; i++ ) {
		Rule *rule = [procedure ruleAtIndex: i];
		if ( [rule target] == TargetFriend || [rule target] == TargetFriendlies ) return YES;
	}
	return NO;
}

- (BOOL)includeCorpsesInPatrol {

	// should we include friendly units?

	// if we have friendly spells in our Patrol Behavior lets return true
	Procedure *procedure = [self.theBehavior procedureForKey: PatrollingProcedure];
    int i;
    for ( i = 0; i < [procedure ruleCount]; i++ ) {
		Rule *rule = [procedure ruleAtIndex: i];
		if ( [rule target] == TargetFriend || [rule target] == TargetFriendlies ) {
			// Go through the conditions to see if we have an isDead status
			for ( Condition *condition in [rule conditions] ) {
				
				if ( [condition variety] == VarietyStatus && 
					[condition state] == StateAlive && 
					[condition comparator] == CompareIsNot ) 
					return YES;
			}
		}
	}
	return NO;
}

- (BOOL)combatProcedureValidForUnit: (Unit*)unit {

	log(LOG_DEV, @"combatProcedureValidForUnit called.");

	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] || [playerController percentHealth] == 0 ) return NO;
	if ( !unit || unit == nil || [unit isDead] || [unit percentHealth] == 0 ) return NO;
	if ( [[combatController unitsDied] containsObject: unit] ) return NO;

	BOOL isFriendly = NO;
	if ( [playerController isFriendlyWithFaction: [unit factionTemplate]] ) isFriendly = YES;

	if ( isFriendly && !theCombatProfile.healingEnabled ) {
		log(LOG_DEV, @"combatProcedureValidForUnit: target is friendly, but healing is not enabled.");
		return NO;
	}

	// Range Checks
	float distanceToTarget = [[playerController position] distanceToPosition: [unit position]];
	float range = 0.0f;

	// Friendly
	if ( isFriendly ) {

		if ( theCombatProfile.attackRange > theCombatProfile.healingRange) range = theCombatProfile.attackRange;
			else range = theCombatProfile.healingRange;

			if ( distanceToTarget > range ) {
				log(LOG_DEV, @"combatProcedureValidForUnit: Friendly target (%0.2f) out of range (%0.2f) in precombat!", distanceToTarget, range);
				return NO;
			}
	} else {
		// Hostile
		range = theCombatProfile.attackRange;
		if ( distanceToTarget > range ) {
			log(LOG_DEV, @"combatProcedureValidForUnit: Hostile target (%0.2f) out of range (%0.2f) in precombat!", distanceToTarget, range);
			return NO;
		}
	}

	Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
    int ruleCount = [procedure ruleCount];
    if ( !procedure || ruleCount == 0 ) return NO;

	Rule *rule = nil;
	int i;
	BOOL matchFound = NO;
	for ( i = 0; i < ruleCount; i++ ) {
		rule = [procedure ruleAtIndex: i];

		if ( [rule target] != TargetNone ) {
			if ( isFriendly ) {
				if ( [rule target] != TargetFriend && [rule target] != TargetFriendlies ) continue;
			} else {
				if ( [rule target] != TargetEnemy && [rule target] != TargetAdd && [rule target] != TargetPat ) continue;
			}
		}

		if ( [self evaluateRule: rule withTarget: unit asTest: NO] ) {
			log(LOG_RULE, @"Match found for rule %@ on %@", rule, unit);
			matchFound = YES;
			break;
		}
	}
	return matchFound;
}

// this function will actually fire off our combat procedure if needed!
- (void)actOnUnit: (Unit*)unit {

	if ( !self.isBotting ) return;
	if ( [playerController isDead] ) return;

	// in theory we should never be here
	if ( [blacklistController isBlacklisted:unit] ) {
		float distance = [[playerController position] distanceToPosition2D: [unit position]];
		log(LOG_BLACKLIST, @"Ambushed by a blacklisted unit??  Ignoring %@ at %0.2f away", unit, distance);
		return;
	}

	log(LOG_DEV, @"Acting on unit %@", unit);
	log(LOG_COMBAT, @"%@ Engaging %@", [combatController unitHealthBar: unit], unit );

	// cancel current procedure
	[self cancelCurrentProcedure];
	[self cancelCurrentEvaluation];
	if ( [movementController isActive] ) [movementController resetMovementState];

	// I notice that readyToAttack is set here, but not used?? hmmm (older revisions are the same)
	BOOL readyToAttack = NO;

	// check to see if we are supposed to be in melee range
	if ( self.theBehavior.meleeCombat) {

		float distance = [[playerController position] distanceToPosition2D: [unit position]];

		// not in range, continue moving!
		if ( distance > 5.0f ) {
			log(LOG_DEV, @"Still %0.2f away, moving to %@", distance, unit);
			[movementController moveToObject:unit];
		} else {
		// we're in range
			log(LOG_DEV, @"In range, attacking!");
			readyToAttack = YES;
		}
	} else {
/*		
		// If they're a hostile out of casting range
		if ( ![playerController isFriendlyWithFaction: [unit factionTemplate]] ) {
			float distanceToTarget = [[[playerController player] position] distanceToPosition: [unit position]];
			if ( distanceToTarget > theCombatProfile.attackRange &&  distanceToTarget < 41.f ) {
				if ( [movementController jumpTowardsPosition: [unit position]] ) readyToAttack = YES;
			}
		}
*/
		readyToAttack = YES;
	}

	log(LOG_DEV, @"Starting combat procedure (current: %@) for target %@", [self procedureInProgress], unit);

	// start the combat procedure
	[self performProcedureWithState: [NSDictionary dictionaryWithObjectsAndKeys: 
									  CombatProcedure,				@"Procedure",
									  [NSNumber numberWithInt: 0],	@"CompletedRules",
									  unit,							@"Target", nil]];
}

#pragma mark -
#pragma mark Loot Helpers

- (void)resetLootScanIdleTimer {
	if ( !theCombatProfile.ShouldLoot ) return;
	_lootScanIdleTimer = 0;	
}

- (Mob*)mobToLoot {

	if ( !theCombatProfile.ShouldLoot ) return nil;

	// if our loot list is empty scan for missed mobs
    if ( ![_mobsToLoot count] ) return nil;

	[self lootScan];

	Mob *mobToLoot = nil;
	// sort the loot list by distance
	[_mobsToLoot sortUsingFunction: DistanceFromPositionCompare context: [playerController position]];

	// find a valid mob to loot
	for ( mobToLoot in _mobsToLoot ) {
		if ( mobToLoot && [mobToLoot isValid] ) {
			if ( ![blacklistController isBlacklisted:mobToLoot] ) {
				return mobToLoot;
			} else {
				[_mobsToLoot removeObject: mobToLoot];
				log(LOG_BLACKLIST, @"Found unit to loot but it's blacklisted, removing %@", mobToLoot);
			}
		}
	}
	return nil;
}

- (BOOL)lootScan {

	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] ) return NO;

	if ( !theCombatProfile.ShouldLoot ) return NO;

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	log(LOG_DEV, @"[LootScan] Scanning for missed mobs to loot.");

	NSArray *mobs = [mobController mobsWithinDistance: theCombatProfile.GatheringDistance MobIDs:nil position:[playerController position] aliveOnly:NO];
	
	for (Mob *mob in mobs) {
		
		if ( theCombatProfile.DoSkinning && theCombatProfile.DoNinjaSkin && [mob isSkinnable] && mob != self.mobToSkin && ![_mobsToLoot containsObject: mob] && ![blacklistController isBlacklisted:mob]) {
			log(LOG_LOOT, @"[NinjaSkin] Adding %@ to skinning list.", mob);
			[_mobsToLoot addObject: mob];
			return YES;
		}

		if ([mob isLootable] && ![mob isSkinnable] && [mob isDead] && ![_mobsToLoot containsObject: mob] && ![blacklistController isBlacklisted:mob]) {
			log(LOG_LOOT, @"[LootScan] Adding %@ to loot list.", mob);
			[_mobsToLoot addObject: mob];
			return YES;
		}

		if ( [_mobsToLoot containsObject: mob] && [blacklistController isBlacklisted:mob]) {
			log(LOG_LOOT, @"[LootScan] Removing blacklisted object %@ from the loot list.", mob);
			[_mobsToLoot removeObject: mob];
			return YES;
		}
		
	}
	return NO;
}

- (void)lootUnit: (WoWObject*) unit {

	if ( [movementController isMoving] ) [movementController resetMovementState];

	// are we still in the air?  shit we can't loot yet!
	if ( ![[playerController player] isOnGround] ) {

		float delay = 0.25f;
		// once the macro failed, so dismount if we need to
		if ( [[playerController player] isMounted] ) {

			[movementController dismount];
			delay = 0.25f;
		}

		NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[unit cachedGUID]];
		NSNumber *count = [_lootDismountCount objectForKey:guid];

		if ( !count ) count = [NSNumber numberWithInt:1]; else count = [NSNumber numberWithInt:[count intValue] + 1];
		[_lootDismountCount setObject:count forKey:guid];

		log(LOG_DEV, @"Player is still in the air, waiting to loot. Attempt %@", count);

		[self performSelector:@selector(lootUnit:) withObject:unit afterDelay:delay];
		return;
	}

	if ( [movementController isMoving] ) [movementController resetMovementState];
	
	BOOL isNode = [unit isKindOfClass: [Node class]];

	self.wasLootWindowOpen	= NO;

	// looting?
	Position *playerPosition = [playerController position];
	float distanceToUnit = [playerController isOnGround] ? [playerPosition distanceToPosition2D: [unit position]] : [playerPosition distanceToPosition: [unit position]];
//	[movementController turnTowardObject: unit];
//	usleep([controller refreshDelay]*2);

	self.lastAttemptedUnitToLoot = unit;

	if ( ![unit isValid] || ( distanceToUnit > 5.0f ) ) {
		log(LOG_LOOT, @"Unit not within 5 yards (%d) or is invalid (%d), unable to loot - removing %@ from list", distanceToUnit > 5.0f, ![unit isValid], unit );
		// remove from list
		if ( ![unit isKindOfClass: [Node class]] ) [_mobsToLoot removeObject: unit];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return;
	}

	if ( [[playerController player] isMounted] ) [movementController dismount];

	self.lootStartTime = [NSDate date];
	self.unitToLoot = unit;
	self.mobToSkin = (Mob*)unit;
	
	[blacklistController incrementAttemptForObject:unit];
	
	if ( !isNode && theCombatProfile.DoSkinning) {
		
		if ( self.mobToSkin && [self.mobToSkin isSkinnable] ) {
			log(LOG_LOOT, @"Using Skin instead of loot : %@m", unit);
			[self skinToFinish];
			return;
		}
	}

	// Lets do this instead of the loot hotkey!
	[self interactWithMouseoverGUID: [unit cachedGUID]];

	// If we do skinning and it may become skinnable
	if (!theCombatProfile.DoSkinning || ![self.mobToSkin isKindOfClass: [Mob class]] || ![self.mobToSkin isNPC])  self.mobToSkin = nil;
	
	
	// verify delays
	float delayTime = 2.5f;
	if (isNode) delayTime = 4.5f;
	
	log(LOG_LOOT, @"Looting : %@m", unit);
	
	// In the off chance that no items are actually looted
	[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: delayTime];
}

- (void)skinToFinish {
	//	self.evaluationInProgress = @"Loot";
	
	// Up to skinning 100, you can find out the highest level mob you can skin by: ((Skinning skill)/10)+10.
	// From skinning level 100 and up the formula is simply: (Skinning skill)/5.
	int canSkinUpToLevel = 0;
	if (theCombatProfile.SkinningLevel <= 100) canSkinUpToLevel = (theCombatProfile.SkinningLevel/10)+10; else canSkinUpToLevel = (theCombatProfile.SkinningLevel/5);
	
	if ( canSkinUpToLevel >= [self.mobToSkin level] ) {
		_skinAttempt = 0;
		[self skinMob:self.mobToSkin];
		return;
	} else {
		[blacklistController blacklistObject: self.mobToSkin];
		log(LOG_LOOT, @"The mob is above your max %@ level (%d).", ((theCombatProfile.DoSkinning) ? @"skinning" : @"herbalism"), canSkinUpToLevel);
		[[NSNotificationCenter defaultCenter] postNotificationName: AllItemsLootedNotification object: [NSNumber numberWithInt:0]];
	}
	
}

// It actually takes 1.2 - 2.0 seconds for [mob isSkinnable] to change to the correct status, this makes me very sad as a human, seconds wasted!
- (void)skinMob: (Mob*)mob {
    float distanceToUnit = [[playerController position] distanceToPosition2D: [mob position]];
	
	// We tried for 2.0 seconds, lets bail
	if ( _skinAttempt++ > 20 ) {
		log(LOG_LOOT, @"[Skinning] Mob is not valid (%d), not skinnable (%d) or is too far away (%d)", ![mob isValid], ![mob isSkinnable], distanceToUnit > 5.0f );
		
		// We'll give this a blacklist
		[blacklistController blacklistObject: mob withReason:Reason_RecentlySkinned];
		
		[_mobsToLoot removeObject: mob];
		self.mobToSkin = nil;
		self.unitToLoot = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return;
	}
	
	// Set to null so our loot notifier realizes we shouldn't try to skin again :P
	self.mobJustSkinned = self.mobToSkin;
	self.mobToSkin = nil;
	self.skinStartTime = [NSDate date];
	
	// Not able to skin :/
	if( ![mob isValid] || ![mob isSkinnable] || distanceToUnit > 5.0f ) {
		log(LOG_LOOT, @"[Skinning] Mob is not valid (%d), not skinnable (%d) or is too far away (%d)", ![mob isValid], ![mob isSkinnable], distanceToUnit > 5.0f );
		
		// We'll give this a blacklist
		[blacklistController blacklistObject: mob withReason:Reason_RecentlySkinned];
		
		[_mobsToLoot removeObject: mob];
		
		self.mobToSkin = nil;
		self.unitToLoot = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return;
    }
	
	[controller setCurrentStatus: @"Bot: Skinning"];
	
	log(LOG_LOOT, @"Skinning!");
	
	// Lets interact w/the mob!
	[self interactWithMouseoverGUID: [mob cachedGUID]];
	
	// In the off chance that no items are actually looted
	[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 5.0f];
	
}

// Sometimes there isn't an item to loot!  So we'll use this to fire off the notification
- (void)verifyLootSuccess {
	//	self.evaluationInProgress = @"Loot";
	
	// Check if the player is casting still (herbalism/mining/skinning)
	if ( [playerController isCasting] ) {
		float delayTime = (([playerController castTimeRemaining]/2.0f)+0.1f);
		log(LOG_LOOT, @"Player is casting, waiting %.2f seconds.", delayTime);
		[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: delayTime];
		return;
	}
	
	log(LOG_DEV, @"Verifying loot succes...");
	
	// Is the loot window stuck being open?
	if ( [lootController isLootWindowOpen] && _lootMacroAttempt < 3 ) {
		self.wasLootWindowOpen	= YES;
		log(LOG_LOOT, @"Loot window open? ZOMG lets close it!");
		_lootMacroAttempt++;
		[lootController acceptLoot];
		[self performSelector: @selector(verifyLootSuccess) withObject: nil afterDelay: 1.0f];
		return;
	} else 
		if ( _lootMacroAttempt >= 3 ) {
			log(LOG_LOOT, @"Attempted to loot %d times, moving on...", _lootMacroAttempt);
		}
	
	// fire off notification (sometimes needed if the mob only had $$, or the loot failed)
	log(LOG_DEV, @"Firing off loot success");
	
	[[NSNotificationCenter defaultCenter] postNotificationName: AllItemsLootedNotification object: [NSNumber numberWithInt:0]];
}

// This is called when all items have actually been looted (the loot window will NOT be open at this point)
- (void)itemsLooted: (NSNotification*)notification {

	if ( !self.isBotting ) return;
	
	BOOL wasNode = NO;
	BOOL wasSkin = NO;
	
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	// If this event fired, we don't need to verifyLootSuccess! We ONLY need verifyLootSuccess when a body has nothing to loot!
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(verifyLootSuccess) object: nil];
	_movingTowardNodeCount = 0;

	// This lets us know that the LAST loot was just from us looting a corpse (vs. via skinning or herbalism)
	if ( self.unitToLoot ) {
		NSDate *currentTime = [NSDate date];
		
		int attempts = [blacklistController attemptsForObject:self.unitToLoot];
		
		// Unit was looted, remove from list!
		if ( [self.unitToLoot isKindOfClass: [Node class]] ){
			log(LOG_DEV, @"Node looted in %0.2f seconds after %d attempt%@", [currentTime timeIntervalSinceDate: self.lootStartTime], attempts, attempts == 1 ? @"" : @"s");
			// Allow the node to fade
			wasNode =YES;
		} else {
			log(LOG_DEV, @"Mob looted in %0.2f seconds after %d attempt%@. %d mobs to loot remain", [currentTime timeIntervalSinceDate: self.lootStartTime], attempts, attempts == 1 ? @"" : @"s", [_mobsToLoot count]);
		}
		
	}
	
	// Here from looting, but need to skin!
	if ( self.unitToLoot && self.mobToSkin ) {
		self.wasLootWindowOpen = NO;
		
		// Pause for a moment for the unit to become skinnable
		[self performSelector: @selector(skinToFinish) withObject: nil afterDelay: 1.0f];
		return;
	}
	
	// Here from skinning!
	if ( self.mobJustSkinned ) {
		
		NSDate *currentTime = [NSDate date];
		
		log(LOG_LOOT, @"Skinning completed in %0.2f seconds", [currentTime timeIntervalSinceDate: self.skinStartTime]);
		
		// We'll give this a blacklist so we don't try to reskin due to ninja skin
		if ( theCombatProfile.DoNinjaSkin ) [blacklistController blacklistObject: self.mobJustSkinned withReason:Reason_RecentlySkinned];
		
		[_mobsToLoot removeObject: self.mobJustSkinned];
		self.mobJustSkinned = nil;
		wasSkin = YES;
		
	}
	
	if ( self.unitToLoot ) {
		[_mobsToLoot removeObject: self.unitToLoot];
		self.unitToLoot = nil;
	}
	
	if (!self.unitToLoot && !self.mobToSkin) {
		// We're done!	
		NSDate *currentTime = [NSDate date];
		if ( self.evaluationInProgress != @"Fishing") log(LOG_LOOT, @"All looting completed in %0.2f seconds", [currentTime timeIntervalSinceDate: self.lootStartTime]);
		
		// Reset our attempt variables!
		_lootMacroAttempt = 0;
	}
	
	float delay = 0.8f;
	// Allow the lute to fade
	if ( wasNode || wasSkin ) delay = 1.2f;

	self.wasLootWindowOpen = NO;

	self.lastAttemptedUnitToLoot = nil;
	
	// Reset the loot scan idle timer
	[self resetLootScanIdleTimer];

	// Retarget ourselves
	[playerController targetGuid:[[playerController player] cachedGUID]];

//	if ( self.evaluationInProgress != @"Fishing") [movementController establishPlayerPosition];
	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: delay];
}

// called when ONE item is looted
- (void)itemLooted: (NSNotification*)notification {
	
	if ( !self.isBotting ) return;
	
	log(LOG_DEV, @"Looted %@", [notification object]);
	
	// should we try to use the item?
	if ( theCombatProfile.GatherUseCrystallized ){
		int itemID = [[notification object] intValue];
		
		// crystallized <air|earth|fire|shadow|life|water> or mote of <air|earth|fire|life|mana|shadow|water>
		if ( ( itemID >= 37700 && itemID <= 37705 ) || ( itemID >= 22572 && itemID <= 22578 ) ) {
			log(LOG_DEV, @"Useable item looted, checking to see if we have > 10 of %d", itemID);
			Item *item = [itemController itemForID:[notification object]];
			if ( item ) {
				int collectiveCount = [itemController collectiveCountForItem:item];
				if ( collectiveCount >= 10 ) {
					log(LOG_LOOT, @"We have more than 10 of %@, using!", item);
					[self performAction:itemID + USE_ITEM_MASK];
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Follow

// Records the route your follow target
-(void)followRouteStartRecord {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	if ( !self.isBotting || !theCombatProfile.followEnabled ) return;

	// If we're already recording we can skip this
	if ( _followTimer ) return;

	// If we can't verify our unit don't start to record
	if ( ![self verifyFollowUnit] ) return;

	Position *positionFollowUnit = [_followUnit position];
	float distanceToFollowUnit = [[playerController position] distanceToPosition: positionFollowUnit];

	// If we're not out of range then let's reset the route
	if ( distanceToFollowUnit <=  theCombatProfile.followDistanceToMove ) {
		log(LOG_DEV, @"Follow unit is not out of range.");
		return;
	}

	// Having passed all tests we can start the recording timer
	_followTimer = [NSTimer scheduledTimerWithTimeInterval: 0.3f target: self selector: @selector(followMonitor:) userInfo: nil repeats: YES];
}

-(void)followRouteClear {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	if ( !theCombatProfile.followEnabled ) return;

	[self resetFollowTimer];
	_followLastSeenPosition = NO;

	[_followRoute release];
	_followRoute = [[Route route] retain];

	log(LOG_DEV, @"[Follow] Route cleared with count: %d waypoints in array.", [_followRoute waypointCount]);

}

-(BOOL)followMountCheck {

	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] ) return NO;
	
	log(LOG_FUNCTION, @"followMountCheck");

	if ( !theCombatProfile.mountEnabled ) return NO;
	
	if ( !_followUnit ) return NO;
	
	if ( ![_followUnit isValid] ) return NO;

	// Get off the ground if leader is in the air
	if ( ![_followUnit isOnGround] && [[playerController player] isFlyingMounted] ) {
		[self jumpIfAirMountOnGround];
		return NO;
	}

	// Dismount if we're not on an air mount we're supposed to be!
	if ( [_followUnit isFlyingMounted] && ![[playerController player] isFlyingMounted] && [[playerController player] isMounted] ) {
		log(LOG_PARTY, @"[Follow] Looks like I'm supposed to be on an air mount, dismounting.");
		[movementController dismount];
		return NO;
	}

	Position *positionFollowUnit = [_followUnit position];
	float distance = [[[playerController player] position] distanceToPosition: positionFollowUnit];
	
	// If we're on the ground and the leader isn't mounted then dismount
	if ( distance <= theCombatProfile.followDistanceToMove && ![_followUnit isMounted] && 
		[[playerController player] isMounted] && [[playerController player] isOnGround] ) {
		log(LOG_PARTY, @"[Follow] Leader dismounted, so am I.");
		[movementController dismount];
		return NO;
	}
	
	// If we're technically in the air, but still close to the dismoutned leader, dismount
	if ( distance < 15.0f && ![_followUnit isMounted] &&  [[playerController player] isMounted] && [_followUnit isOnGround] ) {
		log(LOG_PARTY, @"[Follow] Leader dismounted, so am I.");
		[movementController dismount];
		return NO;
	}

	if ( [playerController isInCombat] ) return NO;
	if ( [[playerController player] isSwimming] ) return NO;

	// Do we need to mount?
	if ( ![_followUnit isMounted] || [[playerController player] isMounted] ) return NO;

	// Check to make sure our mount spell will fire
	// check to see if we can even cast this spell
	
	int theMountType = 1;	// ground
	if ( [_followUnit isFlyingMounted] ) theMountType = 2;		// air

	Spell *mount = [spellController mountSpell:theMountType andFast:YES];
	
	if ( mount == nil ) {

		// should we load any mounts
		if ( [playerController mounts] > 0 && [spellController mountsLoaded] == 0 ) {
			log(LOG_MOUNT, @"Attempting to load mounts...");
			[spellController reloadPlayerSpells];
		}

		return NO;
	}

	if ( ![spellController isUsableAction: [[mount ID] intValue]] ) {
		log(LOG_MOUNT, @"Action isn't usable right now (%d).", mount);
		return NO;
	}

	return YES;
}

-(BOOL)followMountNow{

	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] ) return NO;

	if ( !_followUnit ) return NO;

	if ( ![_followUnit isValid] ) return NO;

	log(LOG_DEV, @"followMountNow has been called.");

	// some error checking
	if ( _mountAttempt > 8 ) {
		float timeUntilRetry = 5.0f - (-1.0f * [_mountLastAttempt timeIntervalSinceNow]);
		
		if ( timeUntilRetry > 0.0f ) {
			log(LOG_MOUNT, @"Will not mount for another %0.2f seconds", timeUntilRetry );
			return NO;
		} else {
			_mountAttempt = 0;
		}
	}

	_mountAttempt++;
	
	int theMountType = 1;	// ground
	if ( [_followUnit isFlyingMounted] ) theMountType = 2;		// air
	
	
	Spell *mount = [spellController mountSpell:theMountType andFast:YES];

	// record our last attempt
	[_mountLastAttempt release]; _mountLastAttempt = nil;
	_mountLastAttempt = [[NSDate date] retain];
	
	if ( mount != nil ) {

		// stop moving if we need to!
//		if ( [movementController isMoving] ) {
		[movementController resetMovementState];
		usleep(10000);
//		}

		// Time to cast!
		int errID = [self performAction:[[mount ID] intValue]];
		if ( errID == ErrNone ){				
			log(LOG_MOUNT, @"Mounting started! No errors!");
			_mountAttempt = 0;
			usleep(1800000);
		} else {
			log(LOG_MOUNT, @"Mounting failed! Error: %d", errID);
		}

		log(LOG_MOUNT, @"Mounted!");
		return YES;
	} else {			
		log(LOG_PARTY, @"No mounts found! PG will try to load them, you can do it manually on your spells tab 'Load All'");
		
		// should we load any mounts
		if ( [playerController mounts] > 0 && [spellController mountsLoaded] == 0 ) {
			log(LOG_MOUNT, @"Attempting to load mounts...");
			[spellController reloadPlayerSpells];				
		}
	}
	
	return NO;
}

#define SilverwingFlagSpellID	23335
#define WarsongFlagSpellID		23333
#define NetherstormFlagSpellID	34976

// Find the designated follow unit
-(BOOL)findFollowUnit {
	
	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] ) return NO;
	
	if ( !theCombatProfile.followEnabled ) return NO;

	log(LOG_DEV, @"Checking for our primary follow unit.");

	Player *followTarget = nil;
	float distance = 0.0;
	float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"BlacklistVerticalOffset"] floatValue];
	Position *playerPosition = [[playerController player] position];

	// Look for the actual follow unit
	if ( theCombatProfile.followUnit && theCombatProfile.followUnitGUID > 0x0 ) {
		followTarget = [playersController playerWithGUID:theCombatProfile.followUnitGUID];
		if ( followTarget ) {
			if ( [followTarget isValid] ) {
				distance = [playerPosition distanceToPosition: [followTarget position]];
			
				if ( theCombatProfile.followDoNotAssignLeader && distance > theCombatProfile.followDoNotAssignLeaderRange ) {
					log(LOG_DEV, @"Leader is out of range so we're not assigning.");
				} else

				if ( [[followTarget position] verticalDistanceToPosition: playerPosition] > vertOffset ) {
					log(LOG_DEV, @"Leader is out of vertical range so we're not assigning.");
				} else

				if (distance < INFINITY) {
					if ( _followUnit ) {
						[_followUnit release];
						if ( [movementController isFollowing] ) [movementController resetMovementState];
					}

					_followUnit = [(Unit*)followTarget retain];
					log(LOG_FOLLOW, @"Leader found: %@", _followUnit);
					[self followRouteStartRecord];
					return YES;
				}
			}
		}
	}

	if ( !_followUnit && theCombatProfile.partyEnabled && theCombatProfile.tankUnit && _tankUnit ) {
		if ( [_tankUnit isValid] ) {
			distance = [playerPosition distanceToPosition: [_tankUnit position]];

			if ( theCombatProfile.followDoNotAssignLeader && distance > theCombatProfile.followDoNotAssignLeaderRange ) {
				log(LOG_DEV, @"Tank is out of range so we're not assigning.");
			} else

			if ( [[_tankUnit position] verticalDistanceToPosition: playerPosition] > vertOffset ) {
				log(LOG_DEV, @"Leader is out of vertical range so we're not assigning.");
			} else

			if (distance < INFINITY) {
				log(LOG_FOLLOW, @"Leader found (following tank): %@", _tankUnit);

				if ( _followUnit ) {
					[_followUnit release];
					if ( [movementController isFollowing] ) [movementController resetMovementState];
				}
				_followUnit = [_tankUnit retain];

				[self followRouteStartRecord];
				return YES;
			}
		}
	}

	if ( !_followUnit && theCombatProfile.partyEnabled && theCombatProfile.assistUnit && _assistUnit ) {
		if ( [_assistUnit isValid] ) {
			distance = [playerPosition distanceToPosition: [_assistUnit position]];
			
			if ( theCombatProfile.followDoNotAssignLeader && distance > theCombatProfile.followDoNotAssignLeaderRange ) {
				log(LOG_DEV, @"Assist is out of range so we're not assigning.");
			} else
				
			if ( [[_assistUnit position] verticalDistanceToPosition: playerPosition] > vertOffset ) {
				log(LOG_DEV, @"Leader is out of vertical range so we're not assigning.");
			} else

			if (distance < INFINITY) {
				log(LOG_FOLLOW, @"Leader found (following assist): %@", _assistUnit);
				if ( _followUnit ) {
					[_followUnit release];
					if ( [movementController isFollowing] ) [movementController resetMovementState];
				}
				_followUnit = [_assistUnit retain];
				
				[self followRouteStartRecord];
				return YES;
			}
		}
	}

	// Check for flag carriers
	if ( !_followUnit && self.pvpIsInBG ) {
		if ( theCombatProfile.followEnemyFlagCarriers || theCombatProfile.followFriendlyFlagCarriers ) {
			NSArray *players = [playersController allPlayers];

			for ( Player *player in players ) {
				
				if ( ![auraController unit: (Unit*)player hasAura: SilverwingFlagSpellID] && 
					![auraController unit: (Unit*)player hasAura: WarsongFlagSpellID] && 
					![auraController unit: (Unit*)player hasAura: NetherstormFlagSpellID] ) continue;

				distance = [playerPosition distanceToPosition: [(Unit*)player position]];
				if ( theCombatProfile.followDoNotAssignLeader && distance > theCombatProfile.followDoNotAssignLeaderRange ) continue;
				if ( distance > 100.0f ) continue;	// Just in case
				if ( [[(Unit*)player position] verticalDistanceToPosition: playerPosition] > vertOffset ) continue;
					
				if ( [playerController isFriendlyWithFaction: [player factionTemplate]] ) {
					if ( theCombatProfile.followFriendlyFlagCarriers ) {
						_followUnit = [(Unit*)player retain];
						log(LOG_FOLLOW, @"Leader found (following friendly flag carrier): %@", player);
						if ( [movementController isFollowing] ) [movementController resetMovementState];
						_followingFlagCarrier = YES;
						return YES;
					}
				} else {
					if ( theCombatProfile.followEnemyFlagCarriers ) {
						if ( _followUnit ) {
							[_followUnit release];
							if ( [movementController isFollowing] ) [movementController resetMovementState];
						}
						_followUnit = [(Unit*)player retain];

						log(LOG_FOLLOW, @"Leader found (following enemy flag carrier): %@", player);
						_followingFlagCarrier = YES;
						[self followRouteStartRecord];
						return YES;
					}
				}
			}
		}
	}

	if ( !_followUnit ) {
		log(LOG_DEV, @"No leader found to follow!");
		return NO;
	}

	return YES;
}

-(BOOL)verifyFollowUnit {

	if ( ![_followUnit isValid] || [_followUnit isDead] ) {
		[_followUnit release]; _followUnit = nil;
		[self followRouteClear];
		return NO;
	}

	Position *positionFollowUnit = [_followUnit position];
	float distanceToFollowUnit = [[playerController position] distanceToPosition: positionFollowUnit];
	
	if ( theCombatProfile.followStopFollowingOOR && distanceToFollowUnit > theCombatProfile.followStopFollowingRange ) {
		log(LOG_FOLLOW, @"Leader is out of range and stop following is enabled, disengaging follow.");
		[_followUnit release]; _followUnit = nil;
		[self followRouteClear];
		return NO;
	}

	// just in case!
	if ( distanceToFollowUnit > 400.0f ) {
		log(LOG_FOLLOW, @"Leader is out of range and stop following is enabled.");
		[_followUnit release]; _followUnit = nil;
		return NO;
	}

	return YES;
}

- (void)followMonitor: (NSTimer*)timer {
	if ( !self.isBotting || !theCombatProfile.followEnabled ) return;

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	
	if ( ( !_followUnit || ![_followUnit isValid] ) && [self findFollowUnit] )
		log(LOG_FOLLOW, @"Found the follow unit again!");
	
	float waypointSpacing = [playerController speedMax] / 2.0f;

	// Validate the current unit
	if ( !self.pvpIsInBG && _followRoute && [_followRoute waypointCount] > 0 && ( !_followUnit || ![_followUnit isValid] ) && !_followLastSeenPosition ) {
		
		// Let's set one more way point to push us into a zone just in case
		_followLastSeenPosition = YES;
		
		NSArray *waypoints = [_followRoute waypoints];
		
		if ( [waypoints count] < 2) {
			// We need at least 2 waypoints to actually do this
			log(LOG_FOLLOW, @"Not enough waypoints to create one for zone in count: %d", _followRoute.waypoints.count);
			return;
		}

		Waypoint *lastWaypoint = [waypoints objectAtIndex: ([waypoints count]-1)];
		Position *lastPosition = [lastWaypoint position];
		
		Waypoint *nextToLastWaypoint = [waypoints objectAtIndex: ([waypoints count]-1)];
		Position *nextToLastPosition = [nextToLastWaypoint position];
		
		float newX = 0.0;
		// If it's north of the next to last position
		if ( [lastPosition xPosition] > [nextToLastPosition xPosition]) newX = [lastPosition xPosition]+waypointSpacing;
		else newX = [lastPosition xPosition]-waypointSpacing;
		
		float newY = 0.0;
		// If it's west of the next to last position
		if ( [lastPosition yPosition] > [nextToLastPosition yPosition]) newY = [lastPosition yPosition]+waypointSpacing;
		else newY = [lastPosition yPosition]-waypointSpacing;
		
		float newZ = [lastPosition zPosition];
		
		Position *zoneInPosition = [[Position alloc] initWithX:newX Y:newY Z:newZ];
		Waypoint *zoneInWaypoint = [Waypoint waypointWithPosition: zoneInPosition];
		
		log(LOG_FOLLOW, @"Cannot see leader, adding zone in waypoint: %@", zoneInWaypoint);
		
		[_followRoute addWaypoint: zoneInWaypoint];
		
		return;
	}

	// If we can't see the unit we can't record it
	if ( !_followUnit || ![_followUnit isValid]) return;

	Position *positionPlayer = [playerController position];
	Position *positionFollowUnit = [_followUnit position];

	float distanceToFollowUnit = [[playerController position] distanceToPosition: positionFollowUnit];

	// If we're not out of range then let's reset the route
	if ( distanceToFollowUnit <=  theCombatProfile.followDistanceToMove ) {
		if ( !movementController.isFollowing ) [self followRouteClear];
		return;
	}

	if ( theCombatProfile.followStopFollowingOOR && distanceToFollowUnit > theCombatProfile.followStopFollowingRange ) {
		log(LOG_FOLLOW, @"Leader is out of range and stop following is enabled, disengaging follow.");
		[_followUnit release]; _followUnit = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
		return;
	}

	if ( [_followRoute waypointCount] ) {
		// If we already have waypoints on the route
		log(LOG_DEV, @"Looks like we have a follow route started already.");

		NSArray *waypoints = [_followRoute waypoints];

		log(LOG_DEV, @"Getting the last waypoint");
		Waypoint *lastWaypoint = [waypoints objectAtIndex: ([waypoints count]-1)];

		float distanceMoved = [[lastWaypoint position] distanceToPosition: positionFollowUnit];

		// If our follow unit hasn't moved far enough we return
		if (distanceMoved < waypointSpacing) return;

		Waypoint *newWaypoint = [Waypoint waypointWithPosition: positionFollowUnit];

		log(LOG_DEV, @"[Follow] Adding waypoint: %@ count: %d", newWaypoint, [_followRoute waypointCount]);

		// Add the waypoint to the route
		[_followRoute addWaypoint: newWaypoint];
	} else {
		// No Route so start it

		Waypoint *newWaypoint;
		if ( distanceToFollowUnit > theCombatProfile.yardsBehindTargetStart ) {
			Position *newPosition = [positionPlayer positionAtDistance: (distanceToFollowUnit-3.0f) withDestination:positionFollowUnit];
			newWaypoint = [Waypoint waypointWithPosition: newPosition];
		} else {
			newWaypoint = [Waypoint waypointWithPosition: positionFollowUnit];
		}
		[_followRoute addWaypoint: newWaypoint];
		
		log(LOG_DEV, @"[Follow] Starting route with waypoint: %@ count: %d", newWaypoint, [_followRoute waypointCount] );

	}
}

-(void)resetFollowTimer{
	if ( _followTimer ) {
		[_followTimer invalidate];
		_followTimer = nil;
	}
}

#pragma mark -
#pragma mark Party

// Sets the tankUnit.
-(BOOL)establishTankUnit {

	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] ) return NO;

	if ( !theCombatProfile.partyEnabled || !theCombatProfile.tankUnit || theCombatProfile.tankUnitGUID <= 0x0 ) {
		if ( _tankUnit ) [_tankUnit release]; _tankUnit = nil;
		return NO;
	}

	// If we've already found a tank and it's valid just return true
	if ( _tankUnit && [_tankUnit isValid] ) return NO;

	// Let's see if we can set the tankUnit
	Unit *tankPlayer = [playersController playerWithGUID: theCombatProfile.tankUnitGUID];
	if ( tankPlayer && [tankPlayer isValid] ) {
		_tankUnit = [tankPlayer retain];
		log(LOG_PARTY, @"Found the tank: %@", _tankUnit );
		return YES;
	} else {
		[_tankUnit release]; _tankUnit = nil;
		log(LOG_DEV, @"Tank not found! GUID: 0x%qX", theCombatProfile.tankUnitGUID);
	}

	return NO;
}

// Sets the assistUnit.
-(BOOL)establishAssistUnit {
	
	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] ) return NO;
	
	if ( !theCombatProfile.partyEnabled || !theCombatProfile.assistUnit || theCombatProfile.assistUnitGUID <= 0x0 ) {
		if ( _assistUnit ) [_assistUnit release]; _assistUnit = nil;
		return NO;
	}

	// If we've already found a assist and it's valid just return true
	if ( _assistUnit && [_assistUnit isValid] ) return NO;
	
	// Let's see if we can set the assistUnit
	Unit *assistPlayer = [playersController playerWithGUID: theCombatProfile.assistUnitGUID];
	if ( assistPlayer && [assistPlayer isValid] ) {
		_assistUnit = [assistPlayer retain];
		log(LOG_PARTY, @"Found the assist: %@", _assistUnit );
		return YES;
	} else {
		[_assistUnit release]; _assistUnit = nil;
		log(LOG_DEV, @"Assist not found! GUID: 0x%qX", theCombatProfile.assistUnitGUID);
	}
	
	return NO;
}

-(BOOL)isTank:(Unit*)unit {
	
	if ( !self.tankUnit ) return NO;

	if ( self.tankUnit == unit ) return YES;
		
	return NO;
}

-(BOOL)leaderWait {

	if ( !self.isBotting ) return NO;
	if ( [playerController isDead] ) return NO;
	
	if ( !theCombatProfile.partyEnabled || !theCombatProfile.partyLeaderWait ) return NO;
	
	UInt64 playerID;
	Player *player;
	
	BOOL needToWait = NO;
	
	int i;
	for (i=1;i<6;i++) {
		
		// If there are no more party members
		playerID = [playerController PartyMember: i];
		if ( playerID <= 0x0) break;
		
		player = [playersController playerWithGUID: playerID];
		
		if ( !player || ![player isValid] ) {
			if ( !_leaderBeenWaiting ) log(LOG_PARTY, @"[LeaderWait] Cannot see: %@", player);
			needToWait = YES;
			break;
		}
		
		if ( [player isInCombat] ) {
			if ( !_leaderBeenWaiting ) log(LOG_PARTY, @"[LeaderWait] still in combat: %@", player);
			needToWait = YES;
			break;
		}
		
		if ( [auraController unit: player hasBuffNamed: @"Food"] || [auraController unit: player hasBuffNamed: @"Drink"] ) {
			if ( !_leaderBeenWaiting ) log(LOG_PARTY, @"[LeaderWait] still eating or drinking: %@", player);
			needToWait = YES;
			break;
		}
		
		float playerDistance = [[playerController position] distanceToPosition: [player position]];
		
		if ( playerDistance >  theCombatProfile.partyLeaderWaitRange ) {
			if ( !_leaderBeenWaiting ) log(LOG_PARTY, @"[LeaderWait] not close enough yet: %@ (%0.2f yards)", player, playerDistance);
			needToWait = YES;
			break;
		}
		
	}
	
	return needToWait;
}

- (void)jumpIfAirMountOnGround {

	if ( !self.isBotting ) return;
	if ( [playerController isDead] ) return;

	// Is the player air mounted, and on the ground?  Me no likey - lets jump!
	UInt32 movementFlags = [playerController movementFlags];
	if ( (movementFlags & 0x1000000) == 0x1000000 && (movementFlags & 0x3000000) != 0x3000000 ){
		if ( _jumpAttempt == 0 && ![controller isWoWChatBoxOpen] ){
			log(LOG_MOVEMENT, @"Player on ground while air mounted, jumping!");
			[movementController raiseUpAfterAirMount];
		}
		if ( _jumpAttempt++ > 3 )	_jumpAttempt = 0;
	}
}
 
- (NSString*)randomEmote:(Unit*)emoteUnit {

	NSString *emote = _lastEmote;

	// Targeting nothing or ourselves
	if ( !emoteUnit || [playerController targetID] == [[playerController player] cachedGUID]) {
		emote = [self emoteGeneral];
		// Find something besides the last one
		while ( emote == _lastEmote) emote = [self emoteGeneral];
		_lastEmote=emote;
		return emote;
	}

	if ( [(Player*)emoteUnit gender] != [[playerController player] gender]) {
		// Targeting someone sexy
		emote = [self emoteSexy];
		while ( emote == _lastEmote) emote = [self emoteSexy];
		_lastEmote=emote;
		return emote;
	}

	// Targeting a friend
	emote = [self emoteFriend];
	while ( emote == _lastEmote) emote = [self emoteFriend];
	_lastEmote=emote;
	return emote;
	
}

- (NSString*)emoteGeneral {
	// What would be the smartest thing here is to make an array, randomize it then go through it, rinse and repeat (perfect randomization).
	int r = SSRandomIntBetween(0,10);
	if (r == 0) return @"/tired";
	if (r == 1) return @"/burp";
	if (r == 2) return @"/bored";
	if (r == 3) return @"/cat";
	if (r == 4) return @"/cry";
	if (r == 5) return @"/chicken";
	if (r == 6) return @"/confused";
	if (r == 7) return @"/sob";
	if (r == 8) return @"/drool";
	if (r == 9) return @"/eye";
	if (r == 10) return @"/fidget";
	return nil;
}

- (NSString*)emoteFriend {
	int r = SSRandomIntBetween(0,10);
	if (r == 0) return @"/yes";
	if (r == 1) return @"/rasp";
	if (r == 2) return @"/lol";
	if (r == 3) return @"/rofl";
	if (r == 4) return @"/grin";
	if (r == 5) return @"/impatient";
	if (r == 6) return @"/moon";
	if (r == 7) return @"/party";
	if (r == 8) return @"/bravo";
	if (r == 9) return @"/cackle";
	if (r == 10) return @"/blink";
	return nil;
}

- (NSString*)emoteSexy {
	int r = SSRandomIntBetween(0,10);
	if (r == 0) return @"/bashful";
	if (r == 1) return @"/blow";
	if (r == 2) return @"/blush";
	if (r == 3) return @"/cuddle";
	if (r == 4) return @"/grin";
	if (r == 5) return @"/flirt";
	if (r == 6) return @"/kiss";
	if (r == 7) return @"/party";
	if (r == 8) return @"/lick";
	if (r == 9) return @"/massage";
	if (r == 10) return @"/love";
	return nil;
}

#pragma mark -
#pragma mark Evaluation Tasks

-(BOOL)evaluateForGhost {

	// Spooky stories go here
	if ( ![playerController isGhost] && ![playerController isDead] ) return NO;

	if ( !self.isBotting ) return NO;

	if ( movementController.moveToObject ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Ghost");

	if ( !self.evaluationInProgress ) {
		log(LOG_GHOST, @"Player is dead.");
		self.evaluationInProgress = @"Ghost";
		[controller setCurrentStatus: @"Bot: Player is Dead"];
	}

	if ( self.pvpIsInBG ) {
		log(LOG_GHOST, @"Player is dead in a BG, stoping evaluation until we revive.");
		return YES;
	}

	if ( theCombatProfile.resurrectWithSpiritHealer ) {
		// Resurrect with the Spirit Healer
		
		if ( theCombatProfile.checkForCampers ) {
			log(LOG_GHOST, @"Checking for campers.");
			// Check for Campers
			BOOL nearbyCampers = [playersController playerWithinRangeOfUnit: theCombatProfile.checkForCampersRange Unit:[playerController player] includeFriendly:NO includeHostile:YES];
			if ( nearbyCampers ) {
				log(LOG_GHOST, @"Looks like I'm being camped, going to hold of on resurrecting.");
				[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 5.0f];
				return YES;
			}
			log(LOG_GHOST, @"No campers.");
		}

		// Find the Spirit Healer
		NSMutableArray *mobs = [NSMutableArray array];
		[mobs addObjectsFromArray: [mobController mobsWithinDistance: 30.0f MobIDs:nil position:[[playerController player]position] aliveOnly:YES]];
		
		if ( ![mobs count]) {
			log(LOG_GHOST, @"Cannot find the Spirit Healer, is it in range?");
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
			return YES;
		}
		
		Mob *spiritHealer;
		
		log(LOG_DEV, @"Looking for the Spirit Healer...");
		
		for ( spiritHealer in mobs ) {
			log(LOG_DEV, @"Checking %@...", spiritHealer.name);
			
			if ( [[spiritHealer name] isEqualToString: @"Spirit Healer"] ) {
				log(LOG_GHOST, @"Found %@...", spiritHealer);
				break;
			} else {
				spiritHealer = nil;
			}
		}
		
		if ( !spiritHealer ) {			
			log(LOG_GHOST, @"Cannot find the Spirit Healer in the mobs list, is it in range?");
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
			return YES;
		} else {
			// Found the Spirit Healer
			log(LOG_DEV, @"Found Spirit Healer!");
			Position *playerPosition = [playerController position];	
			Position *spiritHealerPosition = [spiritHealer position];
			log(LOG_DEV, @"Checking distance...");
			
			float distanceToSpiritHealer = [playerPosition distanceToPosition: spiritHealerPosition];
			
			if ( distanceToSpiritHealer > 3.0f ) {
				log(LOG_DEV, @"Moving to the Spirit Healer.");
				// Face the target
				[movementController turnTowardObject: spiritHealer];
				usleep([controller refreshDelay]*2);
				[movementController moveToObject: spiritHealer];
				//				[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.0f];
				//				[self performSelector: _cmd withObject: nil afterDelay: 0.5f];
				return YES;
			}
			
			log(LOG_GHOST, @"Resurrecting with the Spirit Healer.");
			// Now we do the actual interaction
			[self interactWithMouseoverGUID:[spiritHealer cachedGUID]];
			usleep(10000);
			[macroController useMacroOrSendCmd:@"ClickFirstButton"];
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.5f];
			return YES;
		}
	}

	if( ![playerController corpsePosition] ) {
		log(LOG_DEV, @"Still not near the corpse.");

		// Make sure the movement controller has the right route
		if ( self.theRouteSet && movementController.currentRouteSet != self.theRouteSet )
			[movementController setPatrolRouteSet:self.theRouteSet];

		[movementController resumeMovement];
		return NO;
	}

	Position *playerPosition = [playerController position];
	Position *corpsePosition = [playerController corpsePosition];
	float distanceToCorpse = [playerPosition distanceToPosition: corpsePosition];

	if ( [movementController isMoving] ) {
		log(LOG_DEV, @"Player is moving us.");
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	}

	// If we see the corpse and it's close enough, let's move to it
	if ( _ghostDance == 0 && distanceToCorpse > 6.0f && distanceToCorpse <= theCombatProfile.moveToCorpseRange) {
		if ( [movementController isActive] ) [movementController resetMovementState];
		_movingToCorpse = YES;
		[movementController moveToPosition: corpsePosition];
		log(LOG_GHOST, @"Moving to the corpse now.");
		return YES;
	} else

	// If we're not close to the corpse let's keep moving
	if( _ghostDance == 0 && distanceToCorpse > 6.0f ) {
		
		// Make sure the movement controller has the right route
		if ( self.theRouteSet && movementController.currentRouteSet != self.theRouteSet )
			[movementController setPatrolRouteSet:self.theRouteSet];

		log(LOG_DEV, @"Still not near the corpse.");
		[movementController resumeMovement];
		return NO;
	}

	// we found our corpse
	[controller setCurrentStatus: @"Bot: Waiting to Resurrect"];

	if ( theCombatProfile.checkForCampers ) {
		log(LOG_GHOST, @"Checking for campers.");
		// Check for Campers
		BOOL nearbyCampers = [playersController playerWithinRangeOfUnit: theCombatProfile.checkForCampersRange Unit:[playerController player] includeFriendly:NO includeHostile:YES];
		if ( nearbyCampers ) {
			log(LOG_GHOST, @"Looks like I'm being camped, going to hold of on resurrecting.");
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 5.0f];
			return YES;
		}
		log(LOG_GHOST, @"No campers.");
	}

	if (theCombatProfile.avoidMobsWhenResurrecting) {
		if (_ghostDance <= 3) {
			NSMutableArray *mobs = [NSMutableArray array];
			[mobs addObjectsFromArray: [mobController mobsWithinDistance: 20.0f MobIDs:nil position:[[playerController player]position] aliveOnly:YES]];
			// Do a little dance to make sure we're clear of mobs
			if ([mobs count]) {
				log(LOG_GHOST, @"Mobs near the corpse, finding a safe spot.");
				[mobs sortUsingFunction: DistanceFromPositionCompare context: playerPosition];
				Unit *mob = nil;
				for ( mob in mobs ) {
					// This is very basic, but it's a good place to start =]
					log(LOG_DEV, @"Face and Reverse...");
					
					// Face the target
					[movementController turnTowardObject: mob];
					usleep([controller refreshDelay]*2);
					[movementController moveBackwardStart];
					usleep(1600000);
					[movementController moveBackwardStop];
					_ghostDance++;
					[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
					return YES;
				}
			}
		}

		// Ghost was dancin a lil too much
		if ( _ghostDance > 3 && distanceToCorpse > 26.0 ) {
			log(LOG_GHOST, @"Ghost dance didnt help, moving back to the corpse.");
			[movementController moveToPosition: corpsePosition];
			return YES;
		}
	}

	log(LOG_DEV, @"Clicking the Resurrect button....");

	[macroController useMacroOrSendCmd:@"Resurrect"];	 // get corpse

	// Try once every second until you're back in
	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
	return YES;
}

- (BOOL)evaluateForPVPWG {
	log(LOG_EVALUATE, @"Evaluating for PvPWG.");

	// Check our WG status and start the timer if needed
	if ( theCombatProfile.pvpStayInWintergrasp && [playerController zone] == 4197 && !_wgTimer ) {
		log(LOG_PVP,  @"We're in Wintergrasp, starting the timer.");
		_wgTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0f target: self selector: @selector(wgTimer:) userInfo: nil repeats: YES];
	}

	if ( _wgTimer ) {
		if ( !theCombatProfile.pvpStayInWintergrasp || ![playerController zone] == 4197 ) {
			log(LOG_PVP,  @"Stoping the Wintergrasp timer.");
			[_wgTimer invalidate]; _wgTimer = nil;
		}
	}

	return NO;
}

- (BOOL)evaluateForPVPQueue {
	log(LOG_EVALUATE, @"Evaluating for PvP Queue since we are not in a BG.");

	// Out of BG Resets
	if ( self.pvpIsInBG ) [self pvpSetEnvironmentForZone];

	// If we're in combat don't check any further
	if ( [playerController isInCombat] ) return NO;

	// If we've been waiting to take our Q
	if ( _needToTakeQueue ) {
		if ( [movementController isActive] ) [movementController stopMovement];
		[self joinBGCheck];
		return YES;
	}

	// Check for Queueing
	if ( _waitForPvPQueue ) {
		if ( ![[controller currentStatus] isEqualToString: @"PvP: Waiting in queue for Battleground."] ) 
			[controller setCurrentStatus: @"PvP: Waiting in queue for Battleground."];
		return NO;
	}

	if ( [playerController battlegroundStatus] == BGQueued ) {
		log(LOG_PVP,  @"Waiting In queue for Battleground.");
		_waitForPvPQueue = YES;
		[controller setCurrentStatus: @"PvP: Waiting in queue for Battleground."];
		return NO;
	}

	// Beyond this point we only do checks if we're set to
	if ( !theCombatProfile.pvpQueueForRandomBattlegrounds && !theCombatProfile.pvpLeaveIfInactive ) return NO;

	// Check to see if we have the Deserter buff
	if ( [auraController unit: [playerController player] hasAura: DeserterSpellID] ) {
		if ( [controller currentStatus] != @"PvP: Waiting for deserter to fade." ) [controller setCurrentStatus: @"PvP: Waiting for deserter to fade."];
		log(LOG_DEV, @"Waiting for deserter to fade.");

		if( [controller sendGrowlNotifications] && [GrowlApplicationBridge isGrowlInstalled] && [GrowlApplicationBridge isGrowlRunning]) {
			// [GrowlApplicationBridge setGrowlDelegate: @""];
			[GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat: @"Battleground Entered"]
										description: [NSString stringWithFormat: @"Starting bot in 5 seconds."]
								   notificationName: @"BattlegroundEnter"
										   iconData: (([controller reactMaskForFaction: [[playerController player] factionTemplate]] & 0x2) ? [[NSImage imageNamed: @"BannerAlliance"] TIFFRepresentation] : [[NSImage imageNamed: @"BannerHorde"] TIFFRepresentation])
										   priority: 0
										   isSticky: NO
									   clickContext: nil];
		}

		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
		return YES;
	}

	if ( !theCombatProfile.pvpQueueForRandomBattlegrounds ) return NO;

	if ( [self pvpQueueBattleground] ) {

		[controller setCurrentStatus: @"PvP: Waiting in queue for Battleground."];
		log(LOG_PVP,  @"Queued for Battle Ground!");
		_waitForPvPQueue = YES;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	} else {
		[controller setCurrentStatus: @"PvP: Battleground queue failed, waiting for retry."];
		log(LOG_PVP,  @"Queueing failed, will try again in second.");
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
		return YES;
	}

	return NO;
}

- (BOOL)evaluateForPVPBattleGround {

	log(LOG_EVALUATE, @"Evaluating for PvP Battleground");

	// Battleground has ended, we've been waiting to leave
	if ( _waitingToLeaveBattleground ) {
		// Actually leave
		log(LOG_PVP, @"Leaving battleground.");
		[controller setCurrentStatus: @"Leaving Battleground."];
		[macroController useMacroOrSendCmd:@"LeaveBattlefield"];
		_waitingToLeaveBattleground = NO;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 5.0f];
		return YES;
	}

	_waitForPvPQueue = NO;
	if ( !_pvpIsInBG ) {
		if ( [self pvpSetEnvironmentForZone] ) {
			log(LOG_DEV, @"PvP environment is set!");
		}
	}

	if ( !_pvpTimer )
		_pvpTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(pvpMonitor:) userInfo: nil repeats: YES];

	Player *player = [playerController player];

	if ( self.pvpPlayWarning || theCombatProfile.pvpLeaveIfInactive ) {
		// Play warning if we're marked idle.
		if( [auraController unit: player hasAura: IdleSpellID] || [auraController unit: player hasAura: InactiveSpellID]) {
			log(LOG_PVP, @"Idle/Inactive debuff detected!");
			if ( self.pvpPlayWarning ) [[NSSound soundNamed: @"alarm"] play];
			log( LOG_PVP, @"Inactive debuff detected!");

			if ( theCombatProfile.pvpLeaveIfInactive ) {
				// leave the battleground
				log( LOG_PVP, @"Leaving battleground due to Inactive debuff.");
				[macroController useMacroOrSendCmd:@"LeaveBattlefield"];
			}

			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 1.0f];
			return YES;
		}
	}

	// See if we are waiting for preparation
	if ( [auraController unit: player hasAura: PreparationSpellID] ) {
		if ( !_waitForPvPPreparation ) {
			if ( ![[controller currentStatus] isEqualToString: @"PvP: Waiting for preparation buff to fade."] ) 
				[controller setCurrentStatus: @"PvP: Waiting for preparation buff to fade."];
			_waitForPvPPreparation = YES;
		}
		return NO;
	} else

	// We do not have the buff so...
	if ( _waitForPvPPreparation ) {

		// If we're performing a delay action ( most likely for preparation ) then let's reset
		if ( movementController.performingActions ) [movementController resetMovementState];
		_waitForPvPPreparation = NO;

		// Only checking for the delay!
		if ( [playerController zone] == ZoneStrandOfTheAncients && [playerController isOnBoatInStrand] ) {
			_attackingInStrand = YES;
			_strandDelay = YES;
		} else {
			_strandDelay = NO;
			_attackingInStrand = NO;
		}
	}

	if ( _strandDelay ) {

		// We're still waiting
		if ( _strandDelayTimer++ < 100 ) {
			if ( [controller currentStatus] != @"PvP: Waiting for boat to arrive." ) 
				[controller setCurrentStatus: @"PvP: Waiting for boat to arrive..."];
			return NO;
		}

		// We've arrived!
		_strandDelayTimer = 0;
		_strandDelay = NO;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	}

	if ( !self.isPvPing ) return NO;

	// We're being called while moving to position or following
	if ( [movementController isActive] ) return NO;

	if ( [playerController zone] == ZoneStrandOfTheAncients && [playerController isOnBoatInStrand] ) {

		// walk off boat
		[controller setCurrentStatus: @"PvP: Walking off the boat..."];
		BOOL onLeftBoat = [playerController isOnLeftBoatInStrand];
		Position *pos = nil;
		// Does not work!?? bot goes the wrong way on horde
		if ( onLeftBoat ) {
			log(LOG_PVP, @"Moving off of left boat!");
			pos = [Position positionWithX:6.23f Y:20.94f Z:4.97f];
		} else {
			log(LOG_PVP, @"Moving off of right boat!");
			pos = [Position positionWithX:5.88f Y:-25.1f Z:5.3f];
		}

		[movementController moveToPosition:pos];
		return YES;
	}

	return NO;
}

- (BOOL)evaluateForParty {
	
	if ( [playerController isDead] ) return NO;

	log(LOG_FUNCTION, @"evaluateForParty");

	// Return no if this isn't turned on
	if ( !theCombatProfile.partyEnabled ) return NO;

	// Skip this if we are already in evaluation
	if ( self.evaluationInProgress && self.evaluationInProgress != @"Party") return NO;

	log(LOG_EVALUATE, @"Evaluating for Party");

	if ( [self establishTankUnit] ) {
//		[movementController resetMovementState];

		// Loop again to evaluate after setting tank unit
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	}

	if ( [self establishAssistUnit] ) {
//		[movementController resetMovementState];

		// Loop again to evaluate after setting assist unit
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	}

	if ( [self leaderWait] ) {

		// Looks like we need to wait!
		self.evaluationInProgress = @"Party";

		if ( !_leaderBeenWaiting ) [movementController resetMovementState];

		_leaderBeenWaiting = YES;
		
		// Loop again to wait
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 3.0f];
		return YES;
	} else 
	if ( _leaderBeenWaiting ) {
		if ( [movementController isActive] ) [movementController resetMovementState];

		_leaderBeenWaiting = NO;
		self.evaluationInProgress = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	}

	if ( self.evaluationInProgress ) {
		if ( [movementController isActive] ) [movementController resetMovementState];

		self.evaluationInProgress = nil;
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)evaluateForFollow {

	log(LOG_FUNCTION, @"evaluateForFollow");

//	if ( self.followSuspended && self.followUnit ) self.followUnit = nil;

	if ( !theCombatProfile.followEnabled || self.followSuspended ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Follow");
	// If we're following a flag carrier lets make sure they still have the buff
	if ( _followingFlagCarrier ) {
		if ( ![auraController unit: _followUnit hasAura: SilverwingFlagSpellID] && 
			![auraController unit: _followUnit hasAura: WarsongFlagSpellID] && 
			![auraController unit: _followUnit hasAura: NetherstormFlagSpellID] ) {
			log(LOG_FOLLOW, @"Flag carrier no longer has buff, stopping follow.");
			_followingFlagCarrier = NO;
			if ( [movementController isFollowing] ) [movementController resetMovementState];
			[_followUnit release]; _followUnit = nil;
			[self followRouteClear];
			if ( self.evaluationInProgress == @"Follow" ) self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			return YES;
		}
		
		if ( !_followUnit || ![_followUnit isValid]) {
			log(LOG_FOLLOW, @"Flag carrier no longer valid, stopping follow.");
			_followingFlagCarrier = NO;
			if ( [movementController isFollowing] ) [movementController resetMovementState];
			[_followUnit release]; _followUnit = nil;
			[self followRouteClear];
			if ( self.evaluationInProgress == @"Follow" ) self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			return YES;
		}
		float distanceToLeader = [[playerController position] distanceToPosition: [_followUnit position]];
		if ( distanceToLeader > 80.0f ) {
			log(LOG_FOLLOW, @"Flag carrier out of range, stopping follow.");
			_followingFlagCarrier = NO;
			if ( [movementController isFollowing] ) [movementController resetMovementState];
			[_followUnit release]; _followUnit = nil;
			[self followRouteClear];
			if ( self.evaluationInProgress == @"Follow" ) self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
			return YES;
		}
	}

	[self followRouteStartRecord];

	// isValid causes a crash when the unit is no longer in the same zone!
	// perhaps instead of using Unit for follow I should try using GUID hmm.

	// Find someone to follow if we've lost our target.
	if ( !_followUnit || ![_followUnit isValid] ) {
		log(LOG_DEV, @"No follow unit, calling for findFollowUnit");
		if ( ![self findFollowUnit] ) return NO;
	}

	// If we're doing something, lets record the route of our follow target
	if ( self.evaluationInProgress && self.evaluationInProgress != @"Follow") return NO;

	log(LOG_DEV, @"Checking to see if we're not following the primary follow unit.");
	// If we're following the tank lets see if our primary follow unit is in range
	if ( theCombatProfile.followUnit && theCombatProfile.followUnitGUID > 0x0 && [_followUnit cachedGUID] != theCombatProfile.followUnitGUID ) {
		log(LOG_DEV, @"Following the tank unit, calling for findFollowUnit");
		if ( ![self findFollowUnit] ) return NO;
	}

	// If we're already following
	if ( movementController.isFollowing ) return NO;

	// If we need to mount lets return
	if ( [self followMountCheck] ) {
		if ( [movementController isMoving] || [movementController isActive] ) [movementController resetMovementState];

		log(LOG_DEV, @"Need to mount...");
		self.evaluationInProgress = @"Follow";

		if ( [self followMountNow] ) {
			log(LOG_DEV, @"Mounting ok, calling evaluation");
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return NO;
		} else {
			log(LOG_DEV, @"Mountingfailed!?");
			return NO;
		}
	}

	float distanceToLeader = [[playerController position] distanceToPosition: [_followUnit position]];

	if ( distanceToLeader <= theCombatProfile.followDistanceToMove ) {
		log(LOG_DEV, @"Leader is not out of range.");
		// If we're in range don't worry about it, make sure the route had been cleared
		[self followRouteClear];
		return NO;
	}

	if ( !_followTimer ) {
		_followTimer = [NSTimer scheduledTimerWithTimeInterval: 0.25f target: self selector: @selector(followMonitor:) userInfo: nil repeats: YES];
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
	}

	// If we've recorded no route yet
	if ( ![_followRoute waypointCount] ) {
		log(LOG_DEV, @"No follow route yet, skipping follow.");
		return NO;
	}

	// If we cannot verify our unit
	if ( ![self verifyFollowUnit] ) {
		log(LOG_DEV, @"Cannot verify the unit, skipping follow.");
		return NO;
	}

	// If we're mounted let's wait until they're 2 waypoints away
	if ( [[playerController player] isMounted] && distanceToLeader < 20.0f && [_followRoute waypointCount] == 0 ) {
		log(LOG_DEV, @"Waiting until our leader is at least 2 way points away since we're mounted.");
		return NO;
	}
	
	log(LOG_FOLLOW, @"Leader is %0.2f away, following.", distanceToLeader);

	[controller setCurrentStatus: @"Bot: Following"];
	self.evaluationInProgress = @"Follow";

	[movementController startFollow];
	return YES;
}

- (BOOL)evaluateForCombatContinuation {

	if ( [playerController isDead] || [playerController percentHealth] == 0 ) return NO;

	if ( _waitForPvPQueue  && !self.useRoute) {
		log(LOG_EVALUATE, @"[CombatContinuation] skipping since we're in queue with no route set.");
		return NO;
	}

	if ( _waitForPvPPreparation ) {
		log(LOG_EVALUATE, @"[CombatContinuation] skipping since we're in prepatation.");
		return NO;
	}

	log(LOG_FUNCTION, @"evaluateForCombatContinuation");

	if (self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted]) {
		PGLog(@"wut?");
		return NO;
	}

	// Skip this if we're doing something already
	if ( self.evaluationInProgress == @"Follow" && [[playerController player] isMounted] ) {
		PGLog(@"I DONT BELIEVE IT");
		return NO;
	}

	if ( !self.pvpIsInBG && !theCombatProfile.partyEnabled && ![playerController isInCombat] ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Combat Continuation");

	Unit *bestUnit;

	if ( self.isPvPing || self.pvpIsInBG ) bestUnit = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:NO];
		else bestUnit = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:YES];

	if ( !bestUnit || bestUnit == nil ) return NO;
	log(LOG_DEV, @"[CombatContinuation] Found %@ to act on!", bestUnit);

	// Reset the party emotes idle
	if ( theCombatProfile.partyEmotes ) _partyEmoteIdleTimer = 0;

	if ( [movementController isActive] ) [movementController resetMovementState];

	[self actOnUnit:bestUnit];
	return YES;
}

- (BOOL)evaluateForCombatStart {
	log(LOG_FUNCTION, @"evaluateForCombatStart");

	if ( [playerController isDead] || [playerController percentHealth] == 0 ) return NO;

	if ( _waitForPvPPreparation ) {
		log(LOG_EVALUATE, @"[CombatStart] skipping since we're in queue(%d) or in preparation(%d).", _waitForPvPQueue, _waitForPvPPreparation);
		return NO;
	}

	if ( _waitForPvPQueue && !self.useRoute ) {
		log(LOG_EVALUATE, @"[CombatStart] skipping since we're in queue with no normal route set.");
		return NO;
	}

	// Skip this if we are already in evaluation
	if ( self.evaluationInProgress ) {
		if ( self.evaluationInProgress == @"Follow" && !_followingFlagCarrier ) {
			return NO;		
		} else 
			if ( self.evaluationInProgress != @"Follow" ) {
			return NO;
		}
	}

	// If combat isn't enabled
	if ( !theCombatProfile.combatEnabled && !theCombatProfile.healingEnabled ) return NO;

	// If we're supposed to ignore combat while flying
	if ( self.theCombatProfile.ignoreFlying && [[playerController player] isFlyingMounted] ) return NO;
	
	// If we're set to only attack when attacked or set not to initiate combat in party.
	if (  ( theCombatProfile.partyEnabled && theCombatProfile.partyDoNotInitiate ) || theCombatProfile.onlyRespond ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Combat Start");

	Position *playerPosition = [playerController position];

	// Look for a new target
	if ( theCombatProfile.combatEnabled ) {
		Unit *unitToActOn  = [combatController findUnitWithFriendlyToEngage:_includeFriendly onlyHostilesInCombat:NO];

		if ( unitToActOn && [unitToActOn isValid] ) {
			float unitToActOnDist  = unitToActOn ? [[unitToActOn position] distanceToPosition: playerPosition] : INFINITY;
			if ( unitToActOnDist < INFINITY ) {

				log(LOG_DEV, @"[Combat Start] Valid unit to act on: %@", unitToActOn);

				if ( [movementController isActive] ) [movementController resetMovementState];

				// hostile only
				if ( ![playerController isFriendlyWithFaction: [unitToActOn factionTemplate]] ) {
					// should we do pre-combat?
					if ( ![playerController isInCombat] && ![combatController inCombat] && !_didPreCombatProcedure ) {
						// Reset the party emotes idle
						if ( theCombatProfile.partyEmotes ) _partyEmoteIdleTimer = 0;

						_didPreCombatProcedure = YES;
						self.preCombatUnit = unitToActOn;
						log(LOG_COMBAT, @"%@ Pre-Combat procedure underway.", [combatController unitHealthBar:[playerController player]]);
						[self performProcedureWithState: [NSDictionary dictionaryWithObjectsAndKeys: 
													  PreCombatProcedure,		    @"Procedure",
													  [NSNumber numberWithInt: 0],	    @"CompletedRules",
													  unitToActOn,			   @"Target",  nil]];
						return YES;
					}
					if ( unitToActOn != self.preCombatUnit ) log(LOG_DEV, @"[Combat Start] Attacking unit other than pre-combat unit.");
					self.preCombatUnit = nil;
					log(LOG_DEV, @"%@ Found %@ trying to attack.", [combatController unitHealthBar: unitToActOn], unitToActOn);
				}

				[self actOnUnit: unitToActOn];
				return YES;
			}
		}
	}

	// Check friendlies if healing is enabled
	if ( theCombatProfile.healingEnabled ) {
		NSArray *validUnits = [NSArray arrayWithArray:[combatController validUnitsWithFriendly:_includeFriendly onlyHostilesInCombat:NO]];
		if ( [validUnits count] ) {
			for ( Unit *unit in validUnits ) {
				if ( ![playerController isFriendlyWithFaction: [unit factionTemplate]] ) continue;
				if ([ playerPosition distanceToPosition:[unit position]] > theCombatProfile.healingRange ) continue;
				if ( ![self combatProcedureValidForUnit:unit] ) continue;
				log(LOG_HEAL, @"%@ helping %@", [combatController unitHealthBar: unit], unit);
				// Reset the party emotes idle
				if ( theCombatProfile.partyEmotes ) _partyEmoteIdleTimer = 0;
				if ( [movementController isActive] ) [movementController resetMovementState];
				[self actOnUnit: unit];
				return YES;
			}
		}
	}

	return NO;
}

-(BOOL) evaluateForRegen {

	if ( [playerController isDead] ) return NO;

	// If we're mounted then let's not do anything that would cause us to dismount
	if ( [[playerController player] isMounted] ) return NO;

	if (  [playerController isInCombat] ) {
		log(LOG_EVALUATE, @"Skipping Regen since we're still in combat.");
		if ( self.evaluationInProgress ) self.evaluationInProgress = nil;
		if ( self.pvpIsInBG ) return NO;

		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return YES;
	}

//	if ( self.evaluationInProgress && self.evaluationInProgress != @"Regen") return NO;
		
	log(LOG_EVALUATE, @"Evaluating for Regen");

	// Check to continue regen if the bot was started during regen
	BOOL eatClear = NO, drinkClear = NO;
	Unit *player = [playerController player];

	// check health
	if ( [playerController health] == [playerController maxHealth] ) eatClear = YES;
	// no buff for eating anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Food"] ) eatClear = YES;

	// check mana
	if ( [playerController mana] == [playerController maxMana] ) drinkClear = YES;
	// no buff for drinking anyways
	else if ( ![auraController unit: player hasBuffNamed: @"Drink"] ) drinkClear = YES;

	// we're not done eating/drinking
	if ( !eatClear || !drinkClear ) {
		log(LOG_EVALUATE, @"Looks like we weren't done drinking or eating.");
		self.evaluationInProgress = @"Regen";
		[self performSelector:	@selector(performProcedureWithState:) 
				   withObject:	[NSDictionary dictionaryWithObjectsAndKeys: 
								 RegenProcedure,				@"Procedure",
								[NSNumber numberWithInt: 0],	@"CompletedRules", nil]
				   afterDelay: 0.25];
		 return YES;
	}

	BOOL performRegen = NO;

	// See if we need to perform regen
	for(Rule* rule in [[self.theBehavior procedureForKey: RegenProcedure] rules]) {
		if ( [rule resultType] == ActionType_None ) continue;
		if ([ rule actionID] < 0 ) continue;

		if( [self evaluateRule: rule withTarget: nil asTest: NO] ) {
			log(LOG_DEV, @"Found a regen match with target none.");
			performRegen = YES;
			break;
		}

		if ( [rule target] == TargetSelf && [self evaluateRule: rule withTarget: player asTest: NO] ) {
			log(LOG_DEV, @"Found a regen match with target self.");
			performRegen = YES;
			break;
		}
	}

	if (!performRegen) {

		// If there is no regen to perform.
		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		}
		return NO;
	}
	
	if ( [playerController isInCombat] ) {
		log(LOG_EVALUATE, @"Waiting on regen since we're still in combat.");
		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		} else {
			return NO;
		}
	}

	self.evaluationInProgress = @"Regen";

	// Reset the party emotes idle
	if ( theCombatProfile.partyEmotes ) _partyEmoteIdleTimer = 0;

	// check if all used abilities are instant
	BOOL needToPause = NO;
	for(Rule* rule in [[self.theBehavior procedureForKey: RegenProcedure] rules]) {
		if( ([rule resultType] == ActionType_Spell)) {
			Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: [rule actionID]]];
			if ([spell isInstant]) continue;
		}
		if([rule resultType] == ActionType_None) continue;
		needToPause = YES; 
		break;
	}

	// only pause if we are performing something non instant
	if ( needToPause && ( [movementController isMoving] || [movementController isActive] ) ) [movementController resetMovementState];

	[self performSelector: @selector(performProcedureWithState:) 
			   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
							RegenProcedure,		  @"Procedure",
							[NSNumber numberWithInt: 0],	  @"CompletedRules", nil] 
			   afterDelay: 0.25];
	return YES;
}

- (BOOL)evaluateForLoot {

	if ( !theCombatProfile.ShouldLoot ) return NO;

	if ( [playerController isDead] ) {
		log(LOG_EVALUATE, @"Skipping Loot Evaluation since playerController.isDead");		
		return NO;
	}

	// Skip this if we are already in evaluation
	if ( self.evaluationInProgress && self.evaluationInProgress != @"Loot") return NO;

	// Skip this if we're supposed to be in combat
	if ( combatController.unitsAttackingMe.count ) {
		log(LOG_EVALUATE, @"Skipping Loot Evaluation since combatController.inCombat");
		return NO;
	}

	// If we're mounted and in the air lets just skip loot scans
	if ( ![playerController isOnGround] && [[playerController player] isMounted]) {
		log(LOG_EVALUATE, @"Skipping Loot Evaluation since we're in the air on a mount.");
		if ( [_mobsToLoot count] ) [_mobsToLoot removeAllObjects];
		return NO;
	}

	// If we're supposed to be following then follow!
	if ( theCombatProfile.partyEnabled && theCombatProfile.followUnit && [[playerController player] isMounted] ) {
		log(LOG_EVALUATE, @"Skipping Loot Evaluation since we're following.");
		if ( [_mobsToLoot count] ) [_mobsToLoot removeAllObjects];
		return NO;
	}

	// If we're moving to the mob let's wait till we get there to do anything
    if ( [movementController moveToObject] ) {
		log(LOG_EVALUATE, @"Skipping Loot Evaluation since we're moving to an object.");
		return NO;
	}

	log(LOG_EVALUATE, @"Evaluating for Loot");

    // get potential units and their distances
    Mob *mobToLoot	= [self mobToLoot];

    if ( !mobToLoot ) {

		// Enforce the loot scan idle
		if (_lootScanIdleTimer >= 300) {

			if ( [_mobsToLoot count] ) [_mobsToLoot removeAllObjects];
			if ( self.evaluationInProgress ) self.evaluationInProgress = nil;
			return NO;
		}

		[self lootScan];

		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		} else {
			return NO;
		}
	}

	if ( ![mobToLoot isValid] ) {

		if ( [_mobsToLoot count] ) [_mobsToLoot removeAllObjects];

		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		} else {
			return NO;
		}
	}

	Unit *unitToCheck	= [self mobToLoot];
	// If it's a node then we'll leave it to the mining evaluation
	if ( [unitToCheck isKindOfClass: [Node class]] ) return NO;

	Position *playerPosition = [playerController position];
	float mobToLootDist	    = mobToLoot ? [[mobToLoot position] distanceToPosition: playerPosition] : INFINITY;

	Unit *unitToActOn  = [combatController findUnitWithFriendly:_includeFriendly onlyHostilesInCombat:YES];
	float unitToActOnDist  = unitToActOn ? [[unitToActOn position] distanceToPosition: playerPosition] : INFINITY;

    // if theres a unit that needs our attention that's closer than the lute.
    if ( mobToLootDist > unitToActOnDist && [playerController isHostileWithFaction: [unitToActOn factionTemplate]]) {
		log(LOG_LOOT, @"Mob is too close to loot: %0.2f > %0.2f", mobToLootDist, unitToActOnDist);
		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		} else {
			return NO;
		}
	}

	self.evaluationInProgress = @"Loot";

	// Close enough to loot it
	if ( mobToLootDist <= 5.0 ) {
		_movingTowardMobCount = 0;
		// Looting failed :/ I doubt this will ever actually happen, probably more an issue with nodes, but just in case!
		int attempts = [blacklistController attemptsForObject:mobToLoot];

		if ( self.lastAttemptedUnitToLoot == mobToLoot && attempts >= 3 ){
			log(LOG_LOOT, @"Unable to loot %@ after %d attempts, removing from loot list", self.lastAttemptedUnitToLoot, attempts);
			[_mobsToLoot removeObject: self.unitToLoot];
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		}

		[controller setCurrentStatus: @"Bot: Looting"];		
		self.evaluationInProgress = @"Loot";
//		[self lootUnit:mobToLoot];
		[self performSelector: @selector(lootUnit:) withObject: mobToLoot afterDelay: 0.25f];
		return YES;
	}

	// Move to it	
	if ( self.evaluationInProgress != @"Loot") {
		log(LOG_DEV, @"Found mob to loot: %@ at dist %.2f", mobToLoot, mobToLootDist);
	} else {
		_movingTowardMobCount++;
	}
	
	self.evaluationInProgress = @"Loot";
/*			
	// have we exceeded the amount of attempts to move to the unit?
	// attempts... no longer seconds
	if ( _movingTowardMobCount > 4 ){
		_movingTowardMobCount = 0;
		log(LOG_LOOT, @"Unable to reach %@, removing from loot list", mobToLoot);
		[movementController resetMoveToObject];
		self.evaluationInProgress = nil;
		[blacklistController blacklistObject:mobToLoot];
		[_mobsToLoot removeObject:mobToLoot];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
		return YES;
	}
*/

	if ( [movementController isActive] ) [movementController resetMovementState];
	[controller setCurrentStatus: @"Bot: Moving to Loot"];

	if ( ![movementController moveToObject: mobToLoot] ) {
		// In the off chance that we're unable to move to it
		log(LOG_LOOT, @"Unable to move to %@ !!?? Restarting evaluation", mobToLoot);
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
	}

	return YES;
}

- (BOOL)evaluateForMiningAndHerbalism {

	if (!theCombatProfile.DoMining && !theCombatProfile.DoHerbalism && !theCombatProfile.DoNetherwingEggs ) return NO;

	if ( [playerController isDead] ) return NO;

	// If we're already mounted in party mode then
	if ( theCombatProfile.partyEnabled && [self followUnit] && [[playerController player] isMounted]) return NO;

	// Skip this if we are already in evaluation
	if ( self.evaluationInProgress && self.evaluationInProgress != @"MiningAndHerbalism" ) return NO;

	// If we're moving to the node let's wait till we get there to do anything else
    if ( [movementController moveToObject] ) return NO;

	log(LOG_EVALUATE, @"Evaluating for Mining and Herbalism");

	Position *playerPosition = [playerController position];

	// check for mining and herbalism
	NSMutableArray *nodes = [NSMutableArray array];
	if( theCombatProfile.DoMining)			[nodes addObjectsFromArray: [nodeController nodesWithinDistance: theCombatProfile.GatheringDistance ofType: MiningNode maxLevel: theCombatProfile.MiningLevel]];
	if( theCombatProfile.DoHerbalism)		[nodes addObjectsFromArray: [nodeController nodesWithinDistance: theCombatProfile.GatheringDistance ofType: HerbalismNode maxLevel: theCombatProfile.HerbalismLevel]];
	if( theCombatProfile.DoNetherwingEggs)	[nodes addObjectsFromArray: [nodeController nodesWithinDistance: theCombatProfile.GatheringDistance EntryID: 185915 position:[playerController position]]];

	[nodes sortUsingFunction: DistanceFromPositionCompare context: playerPosition];

	// If we've no node then skip this
	if ( ![nodes count] ) {
		[blacklistController clearAttempts];
		self.wasLootWindowOpen = NO;

		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			if ( [movementController moveToObject] ) [movementController resetMovementState];
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		} else {
			return NO;
		}
	}

	// find a valid node to loot
	Node *thisNode = nil;
	Node *nodeToLoot = nil;
	float nodeDist = INFINITY;

	int blacklistTriggerNodeMadeMeFall = [[[NSUserDefaults standardUserDefaults] objectForKey: @"BlacklistTriggerNodeMadeMeFall"] intValue];

	for(thisNode in nodes) {

		if ( ![thisNode validToLoot] ) {
			log(LOG_NODE, @"%@ is not valid to loot, ignoring...", thisNode);
			continue;
		}

		NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[thisNode cachedGUID]];
		NSNumber *count = [_lootDismountCount objectForKey:guid];

		if ( count ) {
			
			// took .5 seconds or longer to fall!
			if ( [count intValue] > 4 && [count intValue] >= blacklistTriggerNodeMadeMeFall ) {
				log(LOG_NODE, @"%@ made me fall after %d attempts, ignoring...", thisNode, blacklistTriggerNodeMadeMeFall);
				[blacklistController blacklistObject:thisNode withReason:Reason_NodeMadeMeFall];
				continue;
			}
		}

		if ( [theCombatProfile unitShouldBeIgnored: (Unit*)thisNode] ) {
			log(LOG_DEV, @"%@ is on the ignore list, ignoring.", thisNode);
			continue;
		}

		if ( [blacklistController isBlacklisted:thisNode] ) {
			log(LOG_DEV, @"%@ is blacklisted, ignoring.", thisNode);
			continue;
		}

		if ( thisNode && [thisNode isValid] ) {

			nodeDist = [playerPosition distanceToPosition: [thisNode position]];

			// If we're not supposed to loot this node due to proximity rules
			BOOL nearbyScaryUnits = [self scaryUnitsNearNode:thisNode doMob: theCombatProfile.GatherNodesMobNear doFriendy: theCombatProfile.GatherNodesFriendlyPlayerNear doHostile: theCombatProfile.GatherNodesHostilePlayerNear];

			if ( nearbyScaryUnits ) {
				log(LOG_NODE, @"Skipping node due to proximity count");
				continue;
			}

			if ( nodeDist != INFINITY ) {
				nodeToLoot = thisNode;
				break;
			}
		}
		
	}

	// No valid nodes found
	if ( !nodeToLoot ) {
		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			if ( [movementController moveToObject] ) [movementController resetMovementState];
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		} else {
			return NO;
		}
	}

	if ( !self.evaluationInProgress ) {
		log(LOG_NODE, @"Found node to loot: %@ at dist %.2f", nodeToLoot, nodeDist);
		self.evaluationInProgress = @"MiningAndHerbalism";
	}

	// Close enough to loot it
	float closeEnough = 5.0;
	float horizontalDistanceToNode = [[playerController position] distanceToPosition2D: [nodeToLoot position]];
	if ( ![playerController isOnGround] && [[playerController player] isMounted] && horizontalDistanceToNode < 3.0f && [[playerController position] xPosition] >= [[nodeToLoot position] xPosition] ) closeEnough = 10.0;

	if ( nodeDist <= closeEnough ) {

		int attempts = [blacklistController attemptsForObject:nodeToLoot];

		int blacklistTriggerNodeFailedToLoot = [[[NSUserDefaults standardUserDefaults] objectForKey: @"BlacklistTriggerNodeFailedToLoot"] intValue];

		if ( self.lastAttemptedUnitToLoot == nodeToLoot && attempts >= blacklistTriggerNodeFailedToLoot ) {

			log(LOG_NODE, @"Unable to loot %@ after %d attempts, blacklisting.", self.lastAttemptedUnitToLoot, blacklistTriggerNodeFailedToLoot);
			[blacklistController blacklistObject:nodeToLoot];

			if ( self.evaluationInProgress ) {
				self.evaluationInProgress = nil;
				[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
				return YES;
			} else {
				return NO;
			}
		}

		[controller setCurrentStatus: @"Bot: Working node"];
		[self lootUnit:nodeToLoot];
		return YES;
	}

	// if it's potentially unreachable or at a distance lets make sure we're mounted
	// We're putting this here so we can run this check prior to the patrol evaluation
	// This allows us to disregard the mounting if it's not in our behavior (low levels or what ever)
	if ( nodeDist > 9.0f && ![[playerController player] isMounted ] ) {
		// see if we would be performing anything in the patrol procedure
		BOOL performPatrolProc = NO;
		Rule *ruleToCheck;
		for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {
			if( ([rule resultType] != ActionType_None) && ([rule actionID] > 0) && [self evaluateRule: rule withTarget: nil asTest: NO] ) {
				ruleToCheck = rule;
				performPatrolProc = YES;
				break;
			}
		}

		if (performPatrolProc) {
			// lets just unset evaluation and return so patrol triggers next
			self.evaluationInProgress = @"Patrol";
			return NO;
		}
	}

	self.evaluationInProgress = @"MiningAndHerbalism";
	[controller setCurrentStatus: @"Bot: Moving to node"];

	// Set this so we can blacklist it if we die at the node
	self.lastAttemptedUnitToLoot = nodeToLoot;
	
	// Safe to move to the node!
	if ( ![movementController moveToObject: nodeToLoot] ) 
		// If for some reason we're un able to move to the node lets evaluate
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];

	return YES;
}

- (BOOL)evaluateForFishing {

	// Skip this if we are already in evaluation
	if ( self.evaluationInProgress && self.evaluationInProgress != @"Fishing" ) return NO;

	if ( movementController.moveToObject ) return NO;

	if ( !theCombatProfile.DoFishing ) return NO;

	if ( [playerController isDead] ) return NO;

	// If we're supposed to be following then follow!
	if ( theCombatProfile.partyEnabled && [self followUnit] && [[playerController player] isMounted]) return NO;

	log(LOG_EVALUATE, @"Evaluating for Fishing.");

	Position *playerPosition = [playerController position];
	
	// fishing only in schools! (probably have a route we're following)
	if ( theCombatProfile.FishingOnlySchools ) {
		NSMutableArray *nodes = [NSMutableArray array];
		[nodes addObjectsFromArray:[nodeController nodesWithinDistance: theCombatProfile.FishingGatherDistance ofType: FishingSchool maxLevel: 1]];
		[nodes sortUsingFunction: DistanceFromPositionCompare context: playerPosition];

		// are we close enough to start fishing?
		if ( [nodes count] ){			
			// lets find a node
			Node *nodeToFish = nil;
			float nodeDist = INFINITY;
			for (nodeToFish in nodes) {
				if ( [blacklistController isBlacklisted:nodeToFish] ){
					log(LOG_FISHING, @"Node %@ blacklisted, ignoring", nodeToFish);
					continue;
				}
				if ( [nodeToFish isValid] ) {
					nodeDist = [playerPosition distanceToPosition: [nodeToFish position]];
					break;
				}
			}

			BOOL nearbyScaryUnits = [self scaryUnitsNearNode:nodeToFish doMob:theCombatProfile.GatherNodesMobNear doFriendy:theCombatProfile.GatherNodesFriendlyPlayerNear doHostile:theCombatProfile.GatherNodesHostilePlayerNear];

			// we have a valid node!
			if ( nodeDist != INFINITY && !nearbyScaryUnits ) {
				
				self.evaluationInProgress = @"Fishing";
				if ( [movementController isActive] ) [movementController resetMovementState];

				log(LOG_FISHING, @"Found closest school %@ at dist %.2f", nodeToFish, nodeDist);
				
				if (nodeDist <= NODE_DISTANCE_UNTIL_FISH) {
					[movementController turnTowardObject:nodeToFish];
					usleep([controller refreshDelay]*2);
					log(LOG_FISHING, @"We are near %@, time to fish!", nodeToFish);
					if ( [[playerController player] isMounted] ) {
						log(LOG_FISHING, @"Dismounting...");
						[movementController dismount]; 
					}
					
					if ( ![fishController isFishing] ){
						[fishController fish: theCombatProfile.FishingApplyLure
								  withRecast: theCombatProfile.FishingRecast
									 withUse: theCombatProfile.FishingUseContainers
									withLure: theCombatProfile.FishingLureID
								  withSchool: nodeToFish];
					}

					return YES;
				} else {
					log(LOG_FISHING, @"Node distance beyond setting %.2f", NODE_DISTANCE_UNTIL_FISH);
				}
			}
		}
		
		self.evaluationInProgress = nil;
		
		log(LOG_DEV, @"Didn't find a node, so we're doing nothing...");
		
	} else {
		// fish where we are
		if ( !self.evaluationInProgress ) log(LOG_FISHING, @"Just fishing from here.");
		self.evaluationInProgress = @"Fishing";
		[fishController fish: theCombatProfile.FishingApplyLure
				  withRecast:NO
					 withUse: theCombatProfile.FishingUseContainers
					withLure: theCombatProfile.FishingLureID
				  withSchool:nil];		
		return YES;
	}
	
	// if we get here, we shouldn't be fishing, stop if we are
	if ( [fishController isFishing] ) [fishController stopFishing];

	if ( self.evaluationInProgress ) {
		self.evaluationInProgress = nil;
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)evaluateForPatrol {

	if ( [playerController isDead] ) return NO;

	if ( movementController.moveToObject ) return NO;

	// If we have looting to do we skip this
	if ( theCombatProfile.ShouldLoot && [_mobsToLoot count] ) {
		self.evaluationInProgress = nil;
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return YES;
	}

	// If we're already evaluating let's skip this.
	if ( self.evaluationInProgress && self.evaluationInProgress != @"Patrol") return NO;

	// If we're already mounted then let's not do anything that would cause us to dismount
	if ( [[playerController player] isMounted] ) {
		if ( [playerController isInBG:[playerController zone]] ) {
			if ( [movementController isMoving] ) return NO;
		} else {
			return NO;
		}
	}

	// Skip this if we're supposed to be in combat
	if ( [playerController isInCombat] ) return NO;

	// If we might have mobs to loot lets recycle evaluation
	if ( theCombatProfile.ShouldLoot && _lootScanIdleTimer < 3) {
		self.evaluationInProgress = nil;
		[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
		return YES;
	}

	log(LOG_EVALUATE, @"Evaluating for Patrol");

	// see if we would be performing anything in the patrol procedure
	BOOL performPatrolProc = NO;
	Rule *ruleToCheck;
	Unit *target;
	Player *player = [playerController player];
	target = player;

	for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {
		
		if( [rule resultType] == ActionType_None || [rule actionID] < 0 ) continue;
		
		if ( [rule target] == TargetNone ) {
			
			if( [self evaluateRule: rule withTarget: nil asTest: NO] ) {
				log(LOG_RULE, @"[Patrol] Match for %@ with (Target None).", rule);
				ruleToCheck = rule;
				performPatrolProc = YES;
				break;
			}

		} else {

			if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
				log(LOG_RULE, @"[Patrol] Match for %@ with (Target Self).", rule);
				ruleToCheck = rule;
				performPatrolProc = YES;
				break;
			}
		}
	}

	// Return if we're only evaluating against ourself
	if (!performPatrolProc && !_includeFriendlyPatrol && !_includeCorpsesPatrol ) {
		self.evaluationInProgress = nil;
		return NO;
	}

	// If we're waiting in PvP Q with no normal route selected lets only buff party members
	if ( !performPatrolProc && _waitForPvPQueue && !self.useRoute ) {

		if ( _includeFriendlyPatrol && theCombatProfile.partyEnabled ) {

			UInt64 playerID;
			Player *player;
			int i;
			for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules] ) {

				if ( [rule target] != TargetFriend && [rule target] != TargetFriendlies ) continue;

				log(LOG_RULE, @"[Patrol] Evaluating rule %@", rule);
				
				//Let go through the party targets
				for (i=1;i<6;i++) {

					// If there are no more party members
					playerID = [playerController PartyMember: i];
					if ( playerID <= 0x0) break;
					player = [playersController playerWithGUID: playerID];
					
					if ( !player || ![player isValid] ) continue;

					target = player;

					if (![playerController isFriendlyWithFaction: [target factionTemplate]] ) continue;
					if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
						// do something
						log(LOG_RULE, @"[Patrol] Match for %@ with %@", rule, target);
						ruleToCheck = rule;
						performPatrolProc = YES;
						break;
					}
				}

				if ( performPatrolProc ) break;
			}
		}

		if ( !performPatrolProc ) {
			self.evaluationInProgress = nil;
			return NO;
		}
	}

	// Look to see if there are friendlies to be checked in our patrol routine, buffing others?
	if ( !performPatrolProc && _includeFriendlyPatrol ) {

		log(LOG_DEV, @"[Patrol] Looking for friendlies");

		NSArray *friendlyUnits = [combatController friendlyUnits];
		for(Rule* rule in [[self.theBehavior procedureForKey: PatrollingProcedure] rules]) {

			if ( [rule target] != TargetFriend && [rule target] != TargetFriendlies ) continue;

			log(LOG_RULE, @"[Patrol] Evaluating rule %@", rule);

			//Let go through the friendly targets
			for ( target in friendlyUnits ) {
				if ( ![playerController isFriendlyWithFaction: [target factionTemplate]] ) continue;
				if ( [self evaluateRule: rule withTarget: target asTest: NO] ) {
					// do something
					log(LOG_RULE, @"[Patrol] Match for %@ with %@", rule, target);
					ruleToCheck = rule;
					performPatrolProc = YES;
					break;
				}
			}

			if ( performPatrolProc ) break;
		}
	}

	// Look for corpses - resurrection
	if ( !performPatrolProc && _includeCorpsesPatrol) {
		log(LOG_DEV, @"[Patrol] Looking for corpses");
		
		NSMutableArray *allPotentialUnits = [NSMutableArray array];
		[allPotentialUnits addObjectsFromArray: [combatController friendlyCorpses]];

		if ( [allPotentialUnits count] ){
			log(LOG_DEV, @"[CorpseScan] in evaluation...");
			
			float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"BlacklistVerticalOffset"] floatValue];
			for ( target in allPotentialUnits ){
				log(LOG_DEV, @"[CorpseScan] looking for corpses: %@", target);

				if ( ![target isPlayer] || ![target isDead] ) continue;
				if ( [[target position] verticalDistanceToPosition: [playerController position]] > vertOffset ) continue;
				if ( [[playerController position] distanceToPosition:[target position]] > theCombatProfile.healingRange ) continue;

				if ( [blacklistController isBlacklisted:target] ) {
					log(LOG_DEV, @":[CorpseScan] Ignoring blacklisted unit: %@", target);
					continue;
				}

				// player: make sure they're not a ghost
				NSArray *auras = [auraController aurasForUnit: target idsOnly: YES];
				if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ) {
					continue;
				}

				log(LOG_DEV, @"Found a corpse in evaluation!");

				performPatrolProc = YES;
				break;
			}
		}
	}

	if (!performPatrolProc) {

		if ( self.evaluationInProgress ) {
			self.evaluationInProgress = nil;
			[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
			return YES;
		}
		return NO;
	}

	// Perform the procedure.
	log(LOG_EVALUATE, @"[Patrol] Entering Patrolling Phase.");
	self.evaluationInProgress = @"Patrol";

	// check if all used abilities are instant
	BOOL needToPause = NO;

	if( ([ruleToCheck resultType] == ActionType_Spell)) {
		Spell *spell = [spellController spellForID: [NSNumber numberWithUnsignedInt: [ruleToCheck actionID]]];
		if (![spell isInstant]) needToPause = YES;
	} else if ([ruleToCheck resultType] != ActionType_None) needToPause = YES;

	// only pause if we are performing something non instant
	if ( needToPause && ( [movementController isMoving] || [movementController isActive] ) ) [movementController resetMovementState];

	[self performSelector: @selector(performProcedureWithState:) 
			   withObject: [NSDictionary dictionaryWithObjectsAndKeys: 
							PatrollingProcedure,			@"Procedure",
							[NSNumber numberWithInt: 0],	@"CompletedRules",
							target,							@"Target", nil]
				afterDelay: 0.1f];

	return YES;
}

- (BOOL)evaluateForPartyEmotes {
	
	if ( !theCombatProfile.partyEmotes ) return NO;

	if ( [playerController isDead] ) return NO;

	if ( [movementController isMoving] ) return NO;

	if ( [playerController isInCombat] ) return NO;

	// Skip this if we are already in evaluation
	if ( self.evaluationInProgress ) return NO;

	log(LOG_EVALUATE, @"Evaluating for PartyEmotes");

	// Enforce the emote idle threshhold
	int secondsPassed = _partyEmoteIdleTimer/10;
	if (secondsPassed < theCombatProfile.partyEmotesIdleTime) return NO;

	if (_partyEmoteTimeSince > 0) {
		// Not just yet
		_partyEmoteTimeSince--;
		return NO;
	} else {
		// We're good to go, let's set our countdown
		int randomToAdd = SSRandomIntBetween(0,(theCombatProfile.partyEmotesInterval/4));
		_partyEmoteTimeSince = ((theCombatProfile.partyEmotesInterval*10)+(randomToAdd*10));
		log(LOG_DEV, @"Setting emote timer to %d seconds", (_partyEmoteTimeSince/10));
	}
	
	
	/*
	 * Doing Emote
	 */
	
	// Find a random party member to target
	int i;
	for (i=1;i<6;i++) {
		if ( [playerController PartyMember: i] <= 0x0) {
			i--;
			break;
		}
	}

	Unit *emoteUnit = nil;

	// We have party members
	if (i > 0) {
		int randomNumer = SSRandomIntBetween(1, i);
		Player *randomPartyMember = [playersController playerWithGUID: [playerController PartyMember: randomNumer]];
		if ( [randomPartyMember isValid]) emoteUnit = (Unit*)randomPartyMember;
	}
	
	// Target our follow unit
	if ( !emoteUnit && _followUnit && [_followUnit isValid] ) emoteUnit = _followUnit;

	// Target the Unit
	[playerController targetGuid:[emoteUnit cachedGUID]];

	if ( ![movementController isMoving] && ![movementController isActive] ) {
		[movementController turnTowardObject: emoteUnit];
		usleep([controller refreshDelay]*2);

		// Actually move a tad
		[movementController establishPlayerPosition];
	}
//	usleep(300000);

	NSString *emote = [self randomEmote:emoteUnit];

	if ( [playerController targetID] ) {
		log(LOG_PARTY, @"Emote: %@ on %@", emote, [playersController playerNameWithGUID: [playerController targetID]]);
	} else {
		log(LOG_PARTY, @"Emote: %@", emote);
	}

	[chatController sendKeySequence: [NSString stringWithFormat: @"%c%@%c", '\n', emote, '\n']];

	[self performSelector: @selector(evaluateSituation) withObject:nil afterDelay:0.25f];
	return YES;
}

- (BOOL)evaluateSituation {
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

    if ( !self.isBotting ) {
		[self stopBotActions];
		return NO;
	}

	if ( [self evaluationInProgress] ) {
		log(LOG_EVALUATE, @"Evaluating Situation with %@ in progress", [self evaluationInProgress]);
	} else {
		log(LOG_EVALUATE, @"Evaluating Situation");
	}
	_evaluationIsActive = YES;

	UInt32 offset = [offsetController offset:@"WorldState"];
	UInt32 worldState = 0;
	if ( [[controller wowMemoryAccess] loadDataForObject: self atAddress: offset Buffer: (Byte *)&worldState BufLength: sizeof(worldState)] ) {
		if ( worldState == 10 ) {

			log(LOG_GENERAL, @"Game is loading, waiting...");
			if ( self.procedureInProgress )
				[self cancelCurrentProcedure];
			if ( self.evaluationInProgress ) 
				self.evaluationInProgress = nil;
			if ( [movementController isActive] ) 
				[movementController resetMovementState];
			
			[self performSelector: _cmd withObject: nil afterDelay: 1.0f];
			return NO;
		}
	}

    if ( ![playerController playerIsValid:self] ) {
		log(LOG_GENERAL, @"Player is invalid, waiting...");
		if ( self.procedureInProgress )
			[self cancelCurrentProcedure];
		if ( self.evaluationInProgress ) 
			self.evaluationInProgress = nil;
		if ( [movementController isActive] ) 
			[movementController resetMovementState];
		[self performSelector: _cmd withObject: nil afterDelay: 1.0];
		return NO;
	}

	// Skip this if there is a procedure going (sometimes a notification can recall evaluation when we don't want it to)
	if ( self.procedureInProgress ) {
		log(LOG_EVALUATE, @"%@ is in progress so we're canceling evaluation.", self.procedureInProgress);
		[self cancelCurrentEvaluation];
		return NO;
	}

	// If we've been asked to evaluate and we're channeled then let's not interupt (could be manual user)
	if ( [playerController isCasting] ) {
		log(LOG_DEV, @"Player is casting, waiting.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		return NO;
	}

	// Order of operations is established here

	if ( [playerController isDead] || [playerController isGhost] ) return [self evaluateForGhost];

	if ( [self evaluateForPVPWG] ) return YES;

	if ( [playerController isInBG:[playerController zone]] ) {
		if ( [self evaluateForPVPBattleGround] ) {
			_evaluationIsActive = NO;
			return YES;
		}
	} else {
		if ( [self evaluateForPVPQueue] ) {
			_evaluationIsActive = NO;
			return YES;
		}
	}

	[self followRouteStartRecord];

	if ( [self evaluateForLoot] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	if ( [self evaluateForCombatContinuation] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	if ( [self evaluateForRegen] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	// Increment the party emote timer
	if ( theCombatProfile.partyEnabled && theCombatProfile.partyEmotes && ![playerController isInCombat] ) if (_partyEmoteIdleTimer <= (theCombatProfile.partyEmotesIdleTime*10)) _partyEmoteIdleTimer++;

	if ( [self evaluateForMiningAndHerbalism] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	if ( [self evaluateForFollow] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	// Increment the loot scan idle timer if it's not already past it's cut off
	if ( theCombatProfile.ShouldLoot ) if (_lootScanIdleTimer <= 300) _lootScanIdleTimer++;

	if ( [self evaluateForPartyEmotes] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	if ( [self evaluateForFishing] ) {
		_evaluationIsActive = NO;
		return YES;
	}

   	if ( [self evaluateForPatrol] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	if ( [self evaluateForParty] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	if ( _needToTakeQueue ) {
		log(LOG_EVALUATE, @"Waiting to get out of combat so we can take our PvP Queue.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	if ( [self evaluateForCombatStart] ) {
		_evaluationIsActive = NO;
		return YES;
	}

	// If we're waiting for PvP Preparation and we're not supposed to move
	if ( _waitForPvPPreparation && theCombatProfile.pvpDontMoveWithPreparation  ) {
		log(LOG_EVALUATE, @"Waiting for PvP Preparation, looping.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	// If we're waiting for PvP Preparation in Strand
	if ( _waitForPvPPreparation && _attackingInStrand ) {
		log(LOG_EVALUATE, @"Waiting for PvP Preparation in strand, looping.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	// On the boat in strand waiting for it to arrive
	if ( _strandDelay ) {
		log(LOG_EVALUATE, @"Waiting for boat to arrive in strand, looping.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	// If we're just performing a check while we're in route we can return here
	if ( movementController.performingActions ) {
		log(LOG_EVALUATE, @"Evaluation was called from the movemetController while performing a delay action, looping evaluation.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	// If we're just performing a check while we're in route we can return here
	if ( movementController.isFollowing && [movementController isActive] ) {
		log(LOG_EVALUATE, @"Evaluation was called while following, nothing to do.");
		_evaluationIsActive = NO;
		return NO;
	}

	if ( movementController.moveToObject ) {
		log(LOG_EVALUATE, @"Moving to an object so we're not processing movement.");
		_evaluationIsActive = NO;
		return NO;
	}

	// If we're just performing a check while we're in route we can return here
	if ( [movementController isPatrolling] ) {
		log(LOG_EVALUATE, @"Evaluation was called while patrolling, nothing to do.");
		_evaluationIsActive = NO;
		return NO;
	}

	if ( movementController.isActive ) {
		log(LOG_EVALUATE, @"Movement controller is active so we're not processing movement.");
		_evaluationIsActive = NO;
		return NO;
	}

	if ( [movementController isMoving] ) {
		log(LOG_EVALUATE, @"Player is moving so we're not processing movement.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	if ( self.followUnit && !self.followSuspended && [self verifyFollowUnit] ) {
		log(LOG_EVALUATE, @"In follow mode so we're not processing movement.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	// If we're evaluating lets cycle again
	if ( self.evaluationInProgress ) {
		log(LOG_EVALUATE, @"Evaluation in progress so we're looping without movement.");
		if ( theCombatProfile.partyEmotes ) _partyEmoteIdleTimer =0;
		[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
		_evaluationIsActive = NO;
		return NO;
	}

	// If we have looting to do we loop
	if ( [_mobsToLoot count] ) {
		log(LOG_EVALUATE, @"We have looting to do so we're looping evaluation.");
		[self performSelector: _cmd withObject: nil afterDelay: 0.3f];
		return NO;
	}

	// If we have combat to do we loop
//	if ( !self.pvpIsInBG && [combatController.unitsAttackingMe count] && ![playerController isAirMounted] ) {
		// This is intended to help us not continue a route when our behavior has broken or we've ran out of mana.
//		log(LOG_EVALUATE, @"We have combat to do so we're looping evaluation.");
//		[combatController doCombatSearch];
//		[self performSelector: _cmd withObject: nil afterDelay: 0.3f];
//		return NO;
//	}

	// If we get here it should be safe to reset this list
	if ( combatController.unitsDied && combatController.unitsDied.count ) [combatController resetUnitsDied];

	/*
	 * Evaluation Checks Complete, lets see if we're supposed to do a route.
	 * At this point we are not moving.
	 */

	// In a BG with a Route
	if ( self.pvpIsInBG && self.useRoutePvP ) {

		// See if we need to set the route for the BG
		if ( !self.theRouteSetPvP || !movementController.currentRouteSet || movementController.currentRouteSet != self.theRouteSetPvP ) {

			if ( [self pvpSetEnvironmentForZone] ) {
				if (self.theRouteSetPvP) {
					log(LOG_DEV, @"Setting our PvP route set in the movementController.");
					// set the route set
					[movementController setPatrolRouteSet:self.theRouteSetPvP];
					[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
					_evaluationIsActive = NO;
					return YES;
				} else {
					[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
					_evaluationIsActive = NO;
					return NO;
				}
			}
		}

		// Update the status if we need to
		if ( ![[controller currentStatus] isEqualToString: @"Bot: Patrolling"] ) {
			[controller setCurrentStatus: @"Bot: Patrolling"];
			log(LOG_GENERAL, @"Going on Patrol.");
		}

		// If there is a starting route selected we traverse the waypoints strictly.
		if ( [_theRouteCollection startingRoute] ) {
			log(LOG_GENERAL, @"Resuming Movement (PvP).");
			[movementController resumeMovement];
		} else {
			log(LOG_GENERAL, @"Resuming Movement to the closest waypoint (PvP).");
			[movementController resumeMovementToClosestWaypoint];
		}
		_evaluationIsActive = NO;
		return NO;
	}

	// In a BG with a Route
	if ( !self.pvpIsInBG && self.useRoute ) {

		if ( self.theBehavior != [[behaviorPopup selectedItem] representedObject] ) self.theBehavior = [[behaviorPopup selectedItem] representedObject];
		if ( self.theCombatProfile != [[combatProfilePopup selectedItem] representedObject] ) self.theCombatProfile = [[combatProfilePopup selectedItem] representedObject];

		if ( !self.theRouteCollection || self.theRouteCollection != [[routePopup selectedItem] representedObject] ) {
			log(LOG_GENERAL, @"Resetting our Route before moving.");
			self.theRouteCollection = [[routePopup selectedItem] representedObject];
			self.theRouteSet = [_theRouteCollection startingRoute];

			if( !self.theRouteSet ) {
				// Try the 1st routeSet
				if ( self.theRouteCollection.routes.count ) {
					log(LOG_GENERAL, @"You don't have a starting route selected, setting it to the first route.");
					self.theRouteSet = [[_theRouteCollection routes ] objectAtIndex:0];
				}
			}
		}

		// Make sure the movement controller has the right route
		if ( !movementController.currentRouteSet || movementController.currentRouteSet != self.theRouteSet ) {
			log(LOG_GENERAL, @"Updating the movementControllers Route.");
			[movementController setPatrolRouteSet:self.theRouteSet];
		}

		// Update the status if we need to
		if ( ![[controller currentStatus] isEqualToString: @"Bot: Patrolling"] ) {
			[controller setCurrentStatus: @"Bot: Patrolling"];
			log(LOG_GENERAL, @"Going on Patrol.");
		}

		// If there is a starting route selected we traverse the waypoints strictly.
		if ( [_theRouteCollection startingRoute] ) {
			log(LOG_GENERAL, @"Resuming Movement.");
			[movementController resumeMovement];
		} else {
			log(LOG_GENERAL, @"Resuming Movement to the closest waypoint.");
			[movementController resumeMovementToClosestWaypoint];
		}

		_evaluationIsActive = NO;
		return NO;
	}

	// Update the status if we need to
	if ( !_waitForPvPQueue && ![[controller currentStatus] isEqualToString: @"Bot: Enabled"] )
		[controller setCurrentStatus: @"Bot: Enabled"];

	// If we're sittin idle with no route we'll loop evaluation
	[self performSelector: _cmd withObject: nil afterDelay: 0.25f];
	_evaluationIsActive = NO;
	return NO;
}

#pragma mark IBActions

- (IBAction)editRoute: (id)sender {
	
	/*
	 // This doesn't fail, but it doesn't work entirely as it only pulls up the route and doesn't do the rest of the stuff the interface needs to do.
	 
	 RouteCollection *selectedRouteCollection;
	 RouteSet *selectedRouteSet;
	 
	 selectedRouteCollection = [[routePopup selectedItem] representedObject];
	 if ( selectedRouteCollection ) selectedRouteSet = [selectedRouteCollection startingRoute];
	 
	 if ( selectedRouteSet && selectedRouteSet != nil ) [waypointController setCurrentRouteSet: selectedRouteSet];
	 */
	[controller selectRouteTab];
}

- (IBAction)editRoutePvP: (id)sender {
	//	- (void)setCurrentBehavior: (PvPBehavior*)behavior;
	
	// The object type is not a route, but this is what groups the PvP routes (hopefully we can move PvP options to a tab in the Combat Profile)
	PvPBehavior *selectedPvPBehavior;
	selectedPvPBehavior = [[routePvPPopup selectedItem] representedObject];
	
	if ( selectedPvPBehavior && selectedPvPBehavior != nil ) [pvpController setCurrentBehavior: selectedPvPBehavior];
	
	[controller selectPvPRouteTab];
}

- (IBAction)editBehavior: (id)sender {
	
	// Let's be intuitive and pull up the currently selected behavior if there is one
	Behavior *selectedBehavior;
	selectedBehavior = [[behaviorPopup selectedItem] representedObject];
	
	if ( selectedBehavior && selectedBehavior != nil ) [procedureController setCurrentBehavior: selectedBehavior];

	[controller selectBehaviorTab];
}

- (IBAction)editBehaviorPvP: (id)sender {

	// Let's be intuitive and pull up the currently selected behavior if there is one
	Behavior *selectedBehavior;
	selectedBehavior = [[behaviorPvPPopup selectedItem] representedObject];
	if ( selectedBehavior && selectedBehavior != nil ) [procedureController setCurrentBehavior: selectedBehavior];
	
	[controller selectBehaviorTab];
}

- (IBAction)editProfile: (id)sender {
	// Let's be intuitive and pull up the currently selected behavior if there is one
	Profile *selectedProfile;
	selectedProfile = [[combatProfilePopup selectedItem] representedObject];

	// setProfile should use the same naming convention as setCurrentBehavior or the old naming convention needs deprecated.
	// If we can keep this consistent in all of the GUI controllers it'll make it easier to add features like this :)
	if ( selectedProfile && selectedProfile != nil ) [profileController setProfile: selectedProfile];

	[controller selectCombatProfileTab];
}

- (IBAction)editProfilePvP: (id)sender {
	// Let's be intuitive and pull up the currently selected behavior if there is one
	Profile *selectedProfile;
	selectedProfile = [[combatProfilePvPPopup selectedItem] representedObject];
	
	// setProfile should use the same naming convention as setCurrentBehavior or the old naming convention needs deprecated.
	// If we can keep this consistent in all of the GUI controllers it'll make it easier to add features like this :)
	if ( selectedProfile && selectedProfile != nil ) [profileController setProfile: selectedProfile];
	
	[controller selectCombatProfileTab];
}

- (IBAction)updateStatus: (id)sender {

/*
 * To do, just noticed that this sets options when changed... need to update this for all of the new combat profile options?
 */

	CombatProfile *profile;
	NSString *status;
	NSString *behaviorName;
	NSString *routeName;

	// Is this the right way to get the values for these here?
	_useRoute = [[[NSUserDefaults standardUserDefaults] objectForKey: @"UseRoute"] boolValue];
	_useRoutePvP = [[[NSUserDefaults standardUserDefaults] objectForKey: @"UseRoutePvP"] boolValue];

	if ( self.pvpIsInBG ) {

		profile = [[combatProfilePvPPopup selectedItem] representedObject];
		behaviorName = [[[behaviorPvPPopup selectedItem] representedObject] name];

		if ( _useRoutePvP ) routeName = [[[routePvPPopup selectedItem] representedObject] name];
			else routeName = @"Easy Mode";

	} else {

		profile = [[combatProfilePopup selectedItem] representedObject];
		behaviorName = [[[behaviorPopup selectedItem] representedObject] name];

		if ( _useRoute ) routeName = [[[routePopup selectedItem] representedObject] name];
			else routeName = @"Easy Mode";
	}

	status = [NSString stringWithFormat: @"%@ (%@). ", behaviorName, routeName];
	
	
    NSString *bleh = nil;
    if (!profile || !profile.combatEnabled) {
		bleh = @"Combat disabled.";
    } else {
		if(profile.onlyRespond) {
			bleh = @"Only attacking back.";
		}
		else if ( profile.assistUnit ) {

			bleh = [NSString stringWithFormat:@"Only assisting %@", @""];
		}
		else{
			NSString *levels = profile.attackAnyLevel ? @"any levels" : [NSString stringWithFormat: @"levels %d-%d", 
																		 profile.attackLevelMin,
																		 profile.attackLevelMax];
			bleh = [NSString stringWithFormat: @"Attacking %@ within %.1fy.", 
					levels,
					profile.engageRange];
		}
    }

    status = [status stringByAppendingString: bleh];

    if ( theCombatProfile.DoMining )
		status = [status stringByAppendingFormat: @" Mining (%d).", theCombatProfile.MiningLevel];
    if( theCombatProfile.DoHerbalism )
		status = [status stringByAppendingFormat: @" Herbalism (%d).", theCombatProfile.HerbalismLevel];
    if( theCombatProfile.DoSkinning )
		status = [status stringByAppendingFormat: @" Skinning (%d).", theCombatProfile.SkinningLevel];
    
    [statusText setStringValue: status];
	
	if ( self.pvpIsInBG && !_useRoutePvP && [movementController isActive] ) {
		[movementController resetMovementState];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
	}
	
	if ( !self.pvpIsInBG && !_useRoute && [movementController isActive] ) {
		[movementController resetMovementState];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
	}
	
}

- (IBAction)startBot: (id)sender {

	_useRoute = [[[NSUserDefaults standardUserDefaults] objectForKey: @"UseRoute"] boolValue];
	_useRoutePvP = [[[NSUserDefaults standardUserDefaults] objectForKey: @"UseRoutePvP"] boolValue];

    // grab route info
    if ( self.useRoute ) {
		self.theRouteCollection = [[routePopup selectedItem] representedObject];
		self.theRouteSet = [_theRouteCollection startingRoute];
    } else {
		self.theRouteSet = nil;
		self.theRouteCollection = nil;
    }

    self.theBehavior = [[behaviorPopup selectedItem] representedObject];
    self.theCombatProfile = [[combatProfilePopup selectedItem] representedObject];

	// we using a PvP Behavior?
	if ( self.useRoutePvP ) self.pvpBehavior = [[routePvPPopup selectedItem] representedObject];
		else self.pvpBehavior = nil;

	if ( ([self isHotKeyInvalid] & HotKeyPrimary) == HotKeyPrimary ){
		log(LOG_STARTUP, @"Primary hotkey is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Invalid Hotkey", @"You must choose a valid primary hotkey, or the bot will be unable to use any spells or abilities.", @"Okay", NULL, NULL);
		return;
    }
	
	if ( theCombatProfile.ShouldLoot && ([self isHotKeyInvalid] & HotKeyInteractMouseover) == HotKeyInteractMouseover ){
		log(LOG_STARTUP, @"Interact with MouseOver hotkey is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Invalid Looting Hotkey", @"You must choose a valid Interact with MouseOver hotkey, or the bot will be unable to loot bodies.", @"Okay", NULL, NULL);
		return;
	}
    
    // check that we have valid conditions
    if( ![controller isWoWOpen]) {
		log(LOG_STARTUP, @"WoW is not open. Bailing.");
		NSBeep();
		NSRunAlertPanel(@"WoW is not open", @"WoW is not open...", @"Okay", NULL, NULL);
		return;
    }
    
    if( ![playerController playerIsValid:self]) {
		log(LOG_STARTUP, @"The player is not valid. Bailing.");
		NSBeep();
		NSRunAlertPanel(@"Player not valid or cannot be detected", @"You must be logged into the game before you can start the bot.", @"Okay", NULL, NULL);
		return;
    }

	if( self.useRoute && self.theRouteCollection && !self.theRouteSet ){

		// Try the 1st routeSet
		if ( self.theRouteCollection.routes.count ) {
			log(LOG_STARTUP, @"You don't have a starting route selected, setting the starting route to the first route.");
			self.theRouteSet = [[_theRouteCollection routes ] objectAtIndex:0];
		}

		if ( !self.theRouteSet ){
			NSBeep();
			log(LOG_ERROR, @"Could not find a route!");
			NSRunAlertPanel(@"Starting route is not selected", @"You must select a starting route for your route set! Go to the route tab and select one,", @"Okay", NULL, NULL);
			return;
		}
	}

    if( self.useRoute && !self.theRouteSet ) {
		NSBeep();
		log(LOG_STARTUP, @"The current route is not valid.");
		NSRunAlertPanel(@"Route is not valid", @"You must select a valid route before starting the bot.	 If you removed or renamed a route, please select an alternative. And make sure you have a starting route selected on the route tab!", @"Okay", NULL, NULL);
		return;
    }
    
    if( !self.theBehavior ) {
		log(LOG_STARTUP, @"The current behavior is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Behavior is not valid", @"You must select a valid behavior before starting the bot.  If you removed or renamed a behavior, please select an alternative.", @"Okay", NULL, NULL);
		return;
    }
	
    if( !self.theCombatProfile ) {
		log(LOG_STARTUP, @"The current combat profile is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Combat Profile is not valid", @"You must select a valid combat profile before starting the bot.  If you removed or renamed a profile, please select an alternative.", @"Okay", NULL, NULL);
		return;
    }
	
	if ( !self.theRouteCollection && self.useRoute ) {
		log(LOG_STARTUP, @"The current route set is not valid.");
		NSBeep();
		NSRunAlertPanel(@"Route Set is not valid", @"You must select a valid route set before starting the bot.	 If you removed or renamed a profile, please select an alternative.", @"Okay", NULL, NULL);
		return;
    }
	
	// we need at least one macro!
	if ( [[macroController macros] count] == 0 ){
		log(LOG_STARTUP, @"You need at least one macro for Pocket Gnome to function.");
		NSBeep();
		NSRunAlertPanel(@"You need a macro!", @"You need at least one macro for Pocket Gnome to function correctly. It can be blank, simply create one in your game menu.", @"Okay", NULL, NULL);
		return;
	}

	// find our key bindings
	NSString *bindingsError = [bindingsController keyBindingsValid];
	if ( bindingsError != nil ) {
		log(LOG_STARTUP, @"All keys aren't bound!");
		NSBeep();
		NSRunAlertPanel(@"You need to bind the correct keys in your Game Menu", bindingsError, @"Okay", NULL, NULL);
		return;
	}

	// behavior check - friendly
	if ( self.theCombatProfile.healingEnabled ){
		BOOL validFound = NO;
		Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
		int i;
		for ( i = 0; i < [procedure ruleCount]; i++ ) {
			Rule *rule = [procedure ruleAtIndex: i];
			
			if ( [rule target] == TargetFriend || [rule target] == TargetFriendlies ){
				validFound = YES;
				break;
			}
		}

		if ( !validFound ){
			log(LOG_STARTUP, @"You have healing selected, but no rules heal friendlies!");
			NSBeep();
			NSRunAlertPanel(@"Behavior is not set up correctly", @"Your combat profile states you should be healing. But no targets are selected as friendly in your behavior! So how can I heal anyone?", @"Okay", NULL, NULL);
			return;
		}
	}
	
	// behavior check - hostile
	if ( self.theCombatProfile.combatEnabled ){
		BOOL validFound = NO;		
		Procedure *procedure = [self.theBehavior procedureForKey: CombatProcedure];
		int i;
		for ( i = 0; i < [procedure ruleCount]; i++ ) {
			Rule *rule = [procedure ruleAtIndex: i];			
			if ( [rule target] == TargetEnemy || [rule target] == TargetAdd || [rule target] == TargetPat ){
				validFound = YES;
				break;
			}
		}		
		if ( !validFound ){
			log(LOG_STARTUP, @"You have combat selected, but no rules attack enemies!");
			NSBeep();
			NSRunAlertPanel(@"Behavior is not set up correctly", @"Your combat profile states you should be attacking. But no targets are selected as enemies in your behavior! So how can I kill anyone?", @"Okay", NULL, NULL);
			return;
		}
	}
	
	// make sure the route will work!
	if ( self.theRouteSet ){
		[_routesChecked removeAllObjects];
		NSString *error = [self isRouteSetSound:self.theRouteSet];
		if ( error && [error length] > 0 ) {
			log(LOG_STARTUP, @"Your route is not configured correctly!");
			NSBeep();
			NSRunAlertPanel(@"Route is not configured correctly", error, @"Okay", NULL, NULL);
			return;
		}
	}
	
	// make sure our spells are on our action bars!
	NSString *spellError = [spellController spellsReadyForBotting];
	if ( spellError && [spellError length] ){
		log(LOG_STARTUP, @"Your spells/macros/items need to be on your action bars!");
		NSBeep();
		NSRunAlertPanel(@"Your spells/macros/items need to be on your action bars!", spellError, @"Okay", NULL, NULL);
		return;
	}
/*
	// pvp checks
	UInt32 zone = [playerController zone];
	if ( [playerController isInBG:zone] ){
		
		// verify we're able to actually do something (otherwise we make the assumption the user selected the correct route!)
		if ( self.pvpBehavior ){
			
			// do we have a BG for this?
			Battleground *bg = [self.pvpBehavior battlegroundForZone:zone];
			
			if ( !bg ){
				NSString *errorMsg = [NSString stringWithFormat:@"No battleground found for '%@', check your PvP Behavior!", [bg name]];
				log(LOG_STARTUP, errorMsg);
				NSBeep();
				NSRunAlertPanel(@"Unknown error in PvP Behavior", errorMsg, @"Okay", NULL, NULL);
				return;	
			}
			else if ( ![bg routeCollection] ){
				NSString *errorMsg = [NSString stringWithFormat:@"You must select a valid Route Set in your PvP Behavior for '%@'.", [bg name]];
				log(LOG_STARTUP, @"No valid route found for BG %d.", zone);
				NSBeep();
				NSRunAlertPanel(@"No route set found for this battleground", errorMsg, @"Okay", NULL, NULL);
				return;
			}
		}
	}
	if ( self.pvpBehavior && ![self.pvpBehavior canDoRandom] ){
		log(LOG_STARTUP, @"Currently PG will only do random BGs, you must enabled all battlegrounds + select a route for each");
		NSBeep();
		NSRunAlertPanel(@"Enable all battlegrounds", @"Currently PG will only do random BGs, you must enabled all battlegrounds + select a route for each", @"Okay", NULL, NULL);
		return;
		
	}
 */

	// not a valid pvp behavior
	/*if ( self.pvpBehavior && ![self.pvpBehavior isValid] ){
		
		if ( [self.pvpBehavior random] ){
			log(LOG_STARTUP, @"You must have all battlegrounds enabled in your PvP behavior to do random!", zone);
			NSBeep();
			NSRunAlertPanel(@"Enable all battlegrounds", @"You must have all battlegrounds enabled in your PvP behavior to do random!", @"Okay", NULL, NULL);
			return;
		}
		else{
			log(LOG_STARTUP, @"You need at least 1 battleground enabled in your PvP behavior to do PvP!", zone);
			NSBeep();
			NSRunAlertPanel(@"Enable 1 battleground", @"You need at least 1 battleground enabled in your PvP behavior to do PvP!", @"Okay", NULL, NULL);
			return;
		}
	}*/

	// TO DO: verify starting routes for ALL PvP routes

	// not really sure how this could be possible hmmm
    if( self.isBotting ) [self stopBot: nil];

    if ( !self.theCombatProfile || !self.theBehavior ) return;
	
	log(LOG_STARTUP, @"Starting bot.");
	[spellController reloadPlayerSpells];
	_lootScanIdleTimer	= 0;
	
	self.mobToSkin = nil;
	self.unitToLoot = nil;
	_movingTowardMobCount = 0;

	_castingUnit = nil;

	// Follow resets
	_followUnit	= nil;
	
	// Party resets
	_assistUnit	= nil;
	_tankUnit = nil;

	// friendly shit
	_includeFriendly = [self includeFriendlyInCombat];
	_includeFriendlyPatrol = [self includeFriendlyInPatrol];
	_includeCorpsesPatrol = [self includeCorpsesInPatrol];

	_didPreCombatProcedure = NO;
	_reviveAttempt = 0;
	_ghostDance = 0;		

	_waitForPvPQueue = NO;
	_waitForPvPPreparation = NO;
	_isPvpMonitoring = NO;

	// reset statistics
	[statisticsController resetQuestMobCount];
	
	// start our log out timer - only check every 5 seconds!
	_logOutTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0f target: self selector: @selector(logOutTimer:) userInfo: nil repeats: YES];

	int canSkinUpToLevel = 0;
	if ( theCombatProfile.SkinningLevel <= 100) {
		canSkinUpToLevel = (theCombatProfile.SkinningLevel/10)+10;
	} else {
		canSkinUpToLevel = (theCombatProfile.SkinningLevel/5);
	}
	if ( theCombatProfile.DoSkinning ) log(LOG_STARTUP, @"Skinning enabled with skill %d, allowing mobs up to level %d.",theCombatProfile.SkinningLevel, canSkinUpToLevel);
	if ( theCombatProfile.DoNinjaSkin ) log(LOG_STARTUP, @"Ninja Skin enabled.");

	log(LOG_DEV, @"StartBot");
	[controller setCurrentStatus: @"Bot: Enabled"];
	self.isBotting = YES;	[startStopButton setTitle: @"Stop Bot"];

	// Bot started, lets reset our whisper history!
	[chatLogController clearWhisperHistory];

	self.startDate = [[NSDate date] retain];

	// If we're in a BG this will set the right variables and routes.
	if ( [self pvpSetEnvironmentForZone] ) {
		log(LOG_STARTUP, @"We're in a Battleground.");
	}
	
	if ( [playerController isDead] ) {

		[controller setCurrentStatus: @"Bot: Player is Dead"];

		if ( ![playerController isGhost] ) {
			log(LOG_GHOST, @"Do we need to release?");
			[self corpseRelease:[NSNumber numberWithInt:0]];
		}

	} else if ( theCombatProfile.ShouldLoot ) [self lootScan];

	// we have a PvP behavior!
	if ( self.useRoutePvP && self.pvpBehavior ) {
		log(LOG_STARTUP, @"PvP Routes Enabled.");
		self.isPvPing = YES;

		// TO DO - map these to bindings
		self.pvpPlayWarning = NO;// [pvpPlayWarningCheckbox state];

	}

	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
}

- (void)updateRunningTimer{

	int duration = (int) [[NSDate date] timeIntervalSinceDate: self.startDate];

	NSMutableString *runningFor = [NSMutableString stringWithFormat:@"Running for: "];

	if ( duration > 0 ) {

		// Prob a better way for this heh
		int seconds = duration % 60;
		duration /= 60;
		int minutes = duration % 60;
		duration /= 60;
		int hours = duration % 24;
		duration /= 24;
		int days = duration;

		if (days > 0) [runningFor appendString:[NSString stringWithFormat:@"%d day%@", days, (days > 1) ? @"s " : @" "]];
		if (hours > 0) [runningFor appendString:[NSString stringWithFormat:@"%d hour%@", hours, (hours > 1) ? @"s " : @" "]];
		if (minutes > 0) [runningFor appendString:[NSString stringWithFormat:@"%d minute%@", minutes, (minutes > 1) ? @"s " : @" "]];
		if (seconds > 0) [runningFor appendString:[NSString stringWithFormat:@"%d second%@", seconds, (seconds > 1) ? @"s " : @""]];

		[runningTimer setStringValue: runningFor];
	}
}

- (IBAction)stopBot: (id)sender {
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
	log(LOG_FUNCTION, @"stopBot");

	// we are we stopping the bot if we aren't even botting? (partly doing this as I don't want the status to change if we logged out due to something)
//	if ( !self.isBotting ) return;
	if ( self.isBotting ) [controller setCurrentStatus: @"Bot: Stopped"];
	self.isBotting = NO;

	// Kill it and set isBotting right away!
	[self cancelCurrentEvaluation];
	[self stopBotActions];

	// Then a user clicked!
	if ( sender != nil ) self.startDate = nil;
	log(LOG_GENERAL, @"Bot Stopped: %@", sender);

	_afkTimerCounter=0;

	_mountAttempt = 0;


	_sleepTimer = 0;
	[movementController resetRoutes];

//	_pvpBehavior = nil;
	_procedureInProgress = nil;
	_evaluationInProgress = nil;
	_lastProcedureExecuted = nil;
	_didPreCombatProcedure = NO;
	_lastSpellCastGameTime = 0;
	self.startDate = nil;
	_unitToLoot = nil;
	_mobToSkin = nil;
	_mobJustSkinned = nil;
	_wasLootWindowOpen = NO;
	_shouldFollow = YES;
	_lastUnitAttemptedToHealed = nil;
	self.lootStartTime = nil;
	self.skinStartTime = nil;
	_lootMacroAttempt = 0;
	_zoneBeforeHearth = -1;


	_jumpAttempt = 0;
	_includeFriendly = NO;
	_includeFriendlyPatrol = NO;
	_includeCorpsesPatrol = NO;
//	_lastSpellCast = 0;
	_mountAttempt = 0;
	_movingTowardMobCount = 0;
	_movingTowardNodeCount = 0;
	_mountLastAttempt = nil;

	[_castingUnit release];
	_castingUnit = nil;

	// Follow resets
	[_followUnit release];
	_followUnit	= nil;
	_followingFlagCarrier = NO;

	[self followRouteClear];

	// Party resets
	[_tankUnit release];
	_tankUnit = nil;
	[_assistUnit release];
	_assistUnit	= nil;
	_followSuspended = NO;
	_followLastSeenPosition = NO;
	_leaderBeenWaiting = NO;

	_lastCombatProcedureTarget = 0x0;
	_lootScanIdleTimer = 0;

	_partyEmoteIdleTimer = 0;
	_partyEmoteTimeSince = 0;
	_lastEmote = nil;
	_lastEmoteShuffled = 0;

	// wipe pvp options
	_isPvPing = NO;
	_pvpIsInBG = NO;
	_pvpPlayWarning = NO;
	_attackingInStrand = NO;
	_strandDelay = NO;
	_strandDelayTimer = 0;
	_waitingToLeaveBattleground = NO;
	_waitForPvPQueue  = NO;
	_waitForPvPPreparation = NO;
	_isPvpMonitoring = NO;
	_movingToCorpse = NO;

	// stop our log out timer
	[_logOutTimer invalidate];_logOutTimer=nil;

    log(LOG_GENERAL, @"Bot Stopped.");
    [startStopButton setTitle: @"Start Bot"];
}

// the idea of this function is that we want to stop the bot from doing anything, but we don't want to actually stop botting ;)
- (void)stopBotActions {

	// We don't reset evaluateSituation just in case we're being called from there.
	[self cancelCurrentProcedure];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(performProcedureWithState:) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(finishCurrentProcedure:) object: nil];

	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorRegen:) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(performAction:) object: nil];

	// Only stop the movement if it's not the player doing the moving.
	if ( [movementController isActive] ) [movementController resetMovementState];

	[self resetPvpTimer];
    [combatController resetAllCombat];
	// Lets hang on to our blacklist, we can restart if we need to clear it.  Handy if a node made you die while mining among other things
//	[blacklistController clearAll];
	[blacklistController clearAttempts];

	if ( theCombatProfile.ShouldLoot ) [_mobsToLoot removeAllObjects];
    self.preCombatUnit = nil;

	// stop fishing
	if ( [fishController isFishing] ) [fishController stopFishing];

}

- (void)reEnableStart {
    [startStopButton setEnabled: YES];
}

- (IBAction)startStopBot: (id)sender {
    if ( self.isBotting ){
		[self stopBot: sender];
    } else {
		[self startBot: sender];
    }
}

NSMutableDictionary *_diffDict = nil;
- (IBAction)testHotkey: (id)sender {
	
	
	log(LOG_GENERAL, @"testing");
	
	return;
	
    //int value = 28734;
    //[[controller wowMemoryAccess] saveDataForAddress: ([offsetController offset:@"HOTBAR_BASE_STATIC"] + BAR6_OFFSET) Buffer: (Byte *)&value BufLength: sizeof(value)];
    //log(LOG_GENERAL, @"Set Mana Tap.");
    
    //[chatController pressHotkey: hotkey.code withModifier: hotkey.flags];
    
    
    if(!_diffDict) _diffDict = [[NSMutableDictionary dictionary] retain];
    
    BOOL firstRun = ([_diffDict count] == 0);
    UInt32 i, value;
    
    if(firstRun) {
		log(LOG_GENERAL, @"First run.");
		for(i=0x900000; i< 0xFFFFFF; i+=4) {
			if([[controller wowMemoryAccess] loadDataForObject: self atAddress: i Buffer: (Byte *)&value BufLength: sizeof(value)]) {
				if(value < 2)
					[_diffDict setObject: [NSNumber numberWithUnsignedInt: value] forKey: [NSNumber numberWithUnsignedInt: i]];
			}
		}
    } else {
		NSMutableArray *removeKeys = [NSMutableArray array];
		for(NSNumber *key in [_diffDict allKeys]) {
			if([[controller wowMemoryAccess] loadDataForObject: self atAddress: [key unsignedIntValue] Buffer: (Byte *)&value BufLength: sizeof(value)]) {
				if( value == [[_diffDict objectForKey: key] unsignedIntValue]) {
					[removeKeys addObject: key];
				} else {
					[_diffDict setObject: [NSNumber numberWithUnsignedInt: value] forKey: key];
				}
			}
		}
		[_diffDict removeObjectsForKeys: removeKeys];
    }
    
    log(LOG_GENERAL, @"%d values.", [_diffDict count]);
    if([_diffDict count] < 20) {
		log(LOG_GENERAL, @"%@", _diffDict);
    }
    
    return;
}


- (IBAction)hotkeyHelp: (id)sender {
	[NSApp beginSheet: hotkeyHelpPanel
	   modalForWindow: [self.view window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

- (IBAction)closeHotkeyHelp: (id)sender {
    [NSApp endSheet: hotkeyHelpPanel returnCode: 1];
    [hotkeyHelpPanel orderOut: nil];
}

- (IBAction)lootHotkeyHelp: (id)sender {
	[NSApp beginSheet: lootHotkeyHelpPanel
	   modalForWindow: [self.view window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

- (IBAction)closeLootHotkeyHelp: (id)sender {
    [NSApp endSheet: lootHotkeyHelpPanel returnCode: 1];
    [lootHotkeyHelpPanel orderOut: nil];
}

/*
- (IBAction)gatheringLootingOptions: (id)sender{
	[NSApp beginSheet: gatheringLootingPanel
	   modalForWindow: [self.view window]
		modalDelegate: self
	   didEndSelector: @selector(gatheringLootingDidEnd: returnCode: contextInfo:)
		  contextInfo: nil];
}

- (IBAction)gatheringLootingSelectAction: (id)sender {
    [NSApp endSheet: gatheringLootingPanel returnCode: [sender tag]];
}

- (void)gatheringLootingDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [gatheringLootingPanel orderOut: nil];
}
*/

#pragma mark Notifications

- (void)joinBGCheck{
	if ( !self.isBotting ) return;

	_needToTakeQueue = NO;

	int status = [playerController battlegroundStatus];

	if ( status == BGWaiting ) {
		// queue then check again!
		[controller setCurrentStatus: @"Joining Battleground."];
		[macroController useMacroOrSendCmd:@"AcceptBattlefield"];
		log(LOG_PVP, @"Joining BG!");
		[self performSelector: _cmd withObject: nil afterDelay:1.0f];
		return;
	}

	_waitForPvPQueue = NO;
	[self performSelector: @selector(joinBGCheckStartWithoutPreparation) withObject: nil afterDelay: 8.0f];
}

- (void)joinBGCheckStartWithoutPreparation {
	// Normally the auraGain would start the evaluation procedure, this is here in the event that we spawn into a BG that's already in progress.
	if ( _waitForPvPPreparation ) return;
	[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
}

- (void)pvpMonitor: (NSTimer*)timer {

	if ( [self pvpIsBattlegroundEnding] ) {
		log(LOG_PVP, @"Battleground is over, Resetting!");

		// PvP Resets
		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[combatController resetAllCombat];
		[movementController resetRoutes];

		self.pvpPlayWarning = NO;
		
		_waitForPvPQueue = NO;
		_waitingToLeaveBattleground = NO;
		_isPvpMonitoring = NO;

		if ( _followUnit ) {
			[_followUnit release]; _followUnit = nil;
			[self followRouteClear];
		}
		[self stopBotActions];
//		self.theRouteCollection = nil;
//		self.theRouteSet = nil;
//		self.theRouteCollectionPvP = nil;
//		self.theRouteSetPvP = nil;
		
		if ( !self.isPvPing ) {
			log(LOG_PVP, @"Stopping the bot since we're running in easy mode.");
			[self stopBot: nil];
			[controller setCurrentStatus: @"Battleground over, bot stopped."];
			return;
		}
	
		_waitingToLeaveBattleground = YES;
		float delay = 0.1f;
		
		if ( theCombatProfile.pvpWaitToLeave && theCombatProfile.pvpWaitToLeaveTime >= 0.0f ) delay = theCombatProfile.pvpWaitToLeaveTime;
		int delaySeconds = round(delay);
		[controller setCurrentStatus: [NSString stringWithFormat:@"Battleground over, waiting %d seconds to leave.", delaySeconds]];
		[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: delay];
		[self resetPvpTimer];
		return;
	}

	if ( ![playerController isInBG:[playerController zone]] ) {
		log(LOG_PVP, @"No longer in a BG, ending monitor.");
		[self resetPvpTimer];
		return;
	}

	if ( !_isPvpMonitoring ) {
		log(LOG_PVP, @"Starting monitor.");
		_isPvpMonitoring = YES;
	}

}
-(void)resetPvpTimer{
	if ( _pvpTimer ) {
		[_pvpTimer invalidate];
		_pvpTimer = nil;
	}
	_isPvpMonitoring = NO;
}

- (void)eventBattlegroundStatusChange: (NSNotification*)notification {
	if ( !self.isBotting ) return;

	int status = [[notification object] intValue];
	log(LOG_DEV, @"Battle ground status change notification in botController.");

	// Lets join the BG!
	if ( !self.pvpIsInBG && status == BGWaiting ) {

		if ( [playerController isInCombat] || [playerController isDead] ) {
			log(LOG_PVP, @"Battleground Queue popped while in combat, will take it as soon as combat is done.");			
			_needToTakeQueue = YES;
			return;
		}

		// PvP Resets
		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[combatController resetAllCombat];
		[movementController resetMovementState];
		self.pvpPlayWarning = NO;
		_waitingToLeaveBattleground = NO;
		if ( _followUnit ) {
			[_followUnit release]; _followUnit = nil;
			[self followRouteClear];
		}

		float queueAfter = SSRandomFloatBetween(8.0f, 18.0f);
		log(LOG_PVP, @"Joining the BG after %0.2f seconds", queueAfter);
		[controller setCurrentStatus: @"Queue popped, accepting in a moment..."];
		[self performSelector:@selector(joinBGCheck) withObject: nil afterDelay:queueAfter];
		return;
	}

}

- (void)eventZoneChanged: (NSNotification*)notification{
	if ( !self.isBotting ) return;

	NSNumber *lastZone = [notification object];

	if ( [playerController isInBG:[lastZone intValue]] ) {
		[movementController resetMovementState];
		log(LOG_PVP, @"Left BG, stopping movement!");
	}

	[self verifyFollowUnit];

	log(LOG_GENERAL, @"Zone change fired... to %@", lastZone);
}

// Want to respond to some commands? o.O
- (void)whisperReceived: (NSNotification*)notification{
	if ( !self.isBotting ) return;

	ChatLogEntry *entry = [notification object];

	//TO DO: Check to make sure you only respond to people around you that you are healing!
	if ( theCombatProfile.followEnabled ) {

		// Check to ensure this command is from someone allowed to command us
		if ( ![self whisperCommandAllowed: entry] ) return;

		if ( !_followUnit && [self findFollowUnit] )
			log(LOG_FOLLOW, @"Found the follow unit again!");

		Unit *whisperUnit = [self whisperCommandUnit: entry];

		if ( !whisperUnit ) {
			log(LOG_PARTY, @"Whisper unit not found: %@ said %@", [entry playerName], [entry text]);
			return;
		}

		log(LOG_PARTY, @"Follow mode whisper: %@ said %@", [entry playerName], [entry text]);

		NSString *whisperLook = @"*look*";
		NSString *whisperCome = @"*come*";
		NSString *whisperStay = @"*stay*";
		NSString *whisperMove = @"*move*";
		NSString *whisperFollow = @"*follow*";
		NSString *whisperStop = @"*stop*";

		NSPredicate *predicateLook = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", whisperLook];
		NSPredicate *predicateCome = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", whisperCome];
		NSPredicate *predicateStay = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", whisperStay];
		NSPredicate *predicateMove = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", whisperMove];
		NSPredicate *predicateFollow = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", whisperFollow];
		NSPredicate *predicateStop = [NSPredicate predicateWithFormat:@"SELF like[cd] %@", whisperStop];

		// Break your combat and move your ass to the follow unit!
		// This should also work when the leader is out of attaching range, a force attach so to speak
		if ( _followUnit && [_followUnit isValid] && ![playerController isDead] && [predicateMove evaluateWithObject: [entry text]] ) {

			log(LOG_FOLLOW, @"Command recieved, breaking combat and moving now!");

			if ( [playerController isCasting] ) [movementController establishPlayerPosition];	// Break any channeling or actions
			[self cancelCurrentProcedure];
			[self cancelCurrentEvaluation];
			if ( [combatController inCombat] ) [combatController cancelAllCombat];
			if ( [movementController isActive] ) [movementController resetMovementState];


			[macroController useMacroOrSendCmd:@"ReplyOMW"];

			// If the distance is too close to trigger the follow routine we move directly to our object
			float distanceToWhisperUnit = [[playerController position] distanceToPosition: [whisperUnit position]];
			if ( distanceToWhisperUnit <= 30.f ) {
				[self followRouteClear];
				[movementController moveToObject:whisperUnit];
				return;
			}

			// If the distance is too close to trigger the follow routine we move directly to our object
			float distanceToFollowUnit = [[playerController position] distanceToPosition: [_followUnit position]];
			if ( self.followSuspended || distanceToFollowUnit <= theCombatProfile.followDistanceToMove ) {
				[self followRouteClear];
				[movementController moveToObject:_followUnit];
				return;
			}

			[self followRouteStartRecord];
			self.evaluationInProgress = @"Follow";
			[self evaluateSituation];
			return;
		} else 

		// Face up and look at your follow unit
		if ( ![playerController isDead] && [whisperUnit isValid] && [predicateLook evaluateWithObject: [entry text]]  ) {

			log(LOG_FOLLOW, @"Command recieved, facing leader: %@.", whisperUnit);
			[playerController targetGuid:[whisperUnit cachedGUID]];
			[movementController turnTowardObject: whisperUnit];
			usleep([controller refreshDelay]*2);
			[movementController establishPlayerPosition];
			return;
		} else 

		// Deactive follow mode
		if ( ![playerController isDead] && !self.followSuspended && [predicateStay evaluateWithObject: [entry text]] ) {

			log(LOG_FOLLOW, @"Command recieved, stop following.");
			self.followSuspended = YES;

			if (self.evaluationInProgress == @"Follow" ) {
				[self cancelCurrentEvaluation];
				if ( [movementController isActive] ) [movementController resetMovementState];
				[macroController useMacroOrSendCmd:@"ReplyKK"];
				[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
				return;
			}

			[macroController useMacroOrSendCmd:@"ReplyKK"];
			return;
		} else 

		// Reactive follow mode
		if ( ![playerController isDead] && self.followSuspended && [predicateCome evaluateWithObject: [entry text]] ) {

			if ( [playerController isCasting] ) [movementController establishPlayerPosition];
			[self cancelCurrentProcedure];
			[self cancelCurrentEvaluation];
			if ( [combatController inCombat] ) [combatController cancelAllCombat];
			if ( [movementController isActive] ) [movementController resetMovementState];

			log(LOG_PARTY, @"Command recieved, following again.");
			self.followSuspended = NO;
			[self followRouteStartRecord];
			self.evaluationInProgress = @"Follow";
			[macroController useMacroOrSendCmd:@"ReplyOMW"];
			[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.1f];
			return;

		}

		if ( [predicateFollow evaluateWithObject: [entry text]] || [predicateStop evaluateWithObject: [entry text]] ) {

			if ( ![whisperUnit isValid] ) return;

			// Range Check
			float distance = [[[playerController player] position] distanceToPosition: [whisperUnit position]];

			if ( distance >= 30.0f ) {
				log(LOG_FOLLOW, @"Leader is out of /follow range so we're ignoring request.");
				return;
			}

			// Use /follow
			if ( [predicateFollow evaluateWithObject: [entry text]] ) {
				if ( [playerController isCasting] ) [movementController establishPlayerPosition];
				[self cancelCurrentProcedure];
				[self cancelCurrentEvaluation];
				[combatController cancelAllCombat];
				if ( [movementController isActive] ) [movementController resetMovementState];
				[self followRouteClear];

				log(LOG_FOLLOW, @"Command recieved, using /follow");
				[playerController targetGuid:[whisperUnit cachedGUID]];
				[macroController useMacroOrSendCmd:@"Follow"];
				[macroController useMacroOrSendCmd:@"ReplyOMW"];
				return;
			} else

			// Stop using /follow
			if ( [predicateStop evaluateWithObject: [entry text]] ) {

//				[self cancelCurrentProcedure];
//				[self cancelCurrentEvaluation];
//				[combatController cancelAllCombat];
//				[movementController resetMovementState];
//				[self followRouteClear];

				log(LOG_FOLLOW, @"Command recieved, stop using /follow");
//				[playerController targetGuid: [playerController GUID]];
				[movementController establishPlayerPosition];
				[macroController useMacroOrSendCmd:@"ReplyKK"];
				[self performSelector: @selector(evaluateSituation) withObject: nil afterDelay: 0.25f];
				return;
			}
		}
	}
}

-(Unit*)whisperCommandUnit:(ChatLogEntry*)entry {
	// Reverse the name to a Unit
	 NSMutableArray *players = [NSMutableArray array];
	[players addObjectsFromArray: [playersController allPlayers]];
	
	if ( ![players count] ) return nil;
	for ( Unit *unit in players ) {
		// Skip if the target is ourself
		if ( [unit cachedGUID] == [[playerController player] cachedGUID] ) continue;
		if ( ![playerController isFriendlyWithFaction: [unit factionTemplate]] ) continue;
		if ( [[playersController playerNameWithGUID: [unit cachedGUID]] isEqualToString: [entry playerName]] ) return unit;
	}
	return nil;
}

-(BOOL)whisperCommandAllowed:(ChatLogEntry*)entry {

	if ( theCombatProfile.followUnit && theCombatProfile.followUnitGUID > 0x0 ) {
		if ( [[playersController playerNameWithGUID: theCombatProfile.followUnitGUID] isEqualToString: [entry playerName]] ) return YES;
		
	}

	if ( !theCombatProfile.partyEnabled ) {
		log(LOG_CHAT, @"%@ is sending me: %@, but they're not allowed to!", [entry playerName], [entry text] );
		return NO;
	}

	if ( theCombatProfile.tankUnit && theCombatProfile.tankUnitGUID > 0x0 ) 
		if ( [[playersController playerNameWithGUID: theCombatProfile.tankUnitGUID] isEqualToString: [entry playerName]] ) return YES;

	if ( theCombatProfile.assistUnit && theCombatProfile.assistUnit > 0x0 ) 
		if ( [[playersController playerNameWithGUID: theCombatProfile.assistUnit] isEqualToString: [entry playerName] ] ) return YES;

	log(LOG_PARTY, @"%@ is sending me: %@, but they're not allowed to!", [entry playerName], [entry text] );
	return NO;
}

#pragma mark ShortcutRecorder Delegate

- (void)toggleGlobalHotKey:(SRRecorderControl*)sender
{
	if (StartStopBotGlobalHotkey != nil) {
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: StartStopBotGlobalHotkey];
		[StartStopBotGlobalHotkey release];
		StartStopBotGlobalHotkey = nil;
	}
    
    KeyCombo keyCombo = [sender keyCombo];
    
    if((keyCombo.code >= 0) && (keyCombo.flags >= 0)) {
		StartStopBotGlobalHotkey = [[PTHotKey alloc] initWithIdentifier: @"StartStopBot"
															   keyCombo: [PTKeyCombo keyComboWithKeyCode: keyCombo.code
																							   modifiers: [sender cocoaToCarbonFlags: keyCombo.flags]]];
		
		[StartStopBotGlobalHotkey setTarget: startStopButton];
		[StartStopBotGlobalHotkey setAction: @selector(performClick:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey: StartStopBotGlobalHotkey];
    }
}

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {
	
    if(recorder == startstopRecorder) {
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"StartstopCode"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"StartstopFlags"];
		[self toggleGlobalHotKey: startstopRecorder];
    }
	
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark PvP

- (void)auraGain: (NSNotification*)notification {
	if ( !self.isBotting ) return;

	UInt32 spellID = [[(Spell*)[[notification userInfo] objectForKey: @"Spell"] ID] unsignedIntValue];

	if ( spellID == PreparationSpellID || spellID == WaitingToRezSpellID ) {
		if ( [movementController isActive] ) [movementController resetMovementState];
		[self cancelCurrentProcedure];
		[self cancelCurrentEvaluation];
		[combatController resetAllCombat];
		[self followRouteClear];
		[self pvpSetEnvironmentForZone];
	}

    if ( self.pvpIsInBG ) {

		// if we are waiting to rez, pause the bot (incase it is not)
		if( spellID == WaitingToRezSpellID ) {
			log(LOG_PVP, @"Waiting to rez.");
		} else

		// Just got preparation?  Lets check to see if we're in strand + should be attacking/defending
		if ( spellID == PreparationSpellID && ![self pvpIsBattlegroundEnding] ) {

			if ( _followUnit ) {
				[_followUnit release];
				_followUnit = nil;
			}

			_waitForPvPPreparation = YES;

			log(LOG_PVP, @"We have preparation, checking BG info!");

			// Do it in a bit, as we need to wait for our controller to update the object list!
			[self performSelector:@selector(pvpGetBGInfo) withObject:nil afterDelay:2.0f];
		}
    } else 
	if ( spellID == PreparationSpellID || spellID == WaitingToRezSpellID ) {
		[self evaluateSituation];
	}
}

- (void)auraFade: (NSNotification*)notification {

	if ( !self.isBotting ) return;
/*
 Evaluation can handle this now
	// Player is PvPing!
    if ( self.isPvPing || self.pvpIsInBG ) {

		UInt32 spellID = [[(Spell*)[[notification userInfo] objectForKey: @"Spell"] ID] unsignedIntValue];

		if( spellID == PreparationSpellID ) {
			// Only checking for the delay!
			if ( [playerController isOnBoatInStrand] && [playerController zone] == ZoneStrandOfTheAncients ) {
				_attackingInStrand = YES;
				if ( self.isPvPing ) _strandDelay = YES;
			}
		}
    }
*/
}

- (void)logOutWithMessage:(NSString*)message {
	
	log(LOG_GENERAL, @"[Bot] %@", message);
	[self logOut];
	
	// sleep a bit before we update our status
	usleep(500000);
	[self updateStatus: [NSString stringWithFormat:@"Bot: %@", message]];
}

- (BOOL)pvpIsBattlegroundEnding {

	UInt32 offset = [offsetController offset:@"Lua_GetBattlefieldWinner"], status = 0;
	[[controller wowMemoryAccess] loadDataForObject: self atAddress: offset Buffer: (Byte*)&status BufLength: sizeof(status)];
	log(LOG_DEV, @"pvpIsBattlegroundEnding: %d", status);
	if ( status != 0 ) return YES;

	return NO;
}

// this will set up the pvp environment based on the zone we're in (basically set the RouteSet)
- (BOOL)pvpSetEnvironmentForZone{
	log(LOG_FUNCTION,  @"pvpSetEnvironmentForZone:");

	UInt32 zone = [playerController zone];
	if ( ![playerController isInBG:zone] ) {

		log(LOG_PVP,  @"Resetting the PvP Environment since we're not in a BG.");

		if ( _pvpTimer ) [self resetPvpTimer];

		// Resets for Regular Mode
		_pvpIsInBG = NO;
		if ( self.theBehavior != [[behaviorPopup selectedItem] representedObject] ) self.theBehavior = [[behaviorPopup selectedItem] representedObject];
		if ( self.theCombatProfile != [[combatProfilePopup selectedItem] representedObject] ) self.theCombatProfile = [[combatProfilePopup selectedItem] representedObject];

		_attackingInStrand = NO;
		_strandDelay= NO;
		_waitForPvPPreparation = NO;
		_strandDelayTimer = 0;
		_needToTakeQueue = NO;

		return NO;
	}

	_pvpIsInBG = YES;
	_waitForPvPQueue = NO;

    if ( self.theBehavior != [[behaviorPvPPopup selectedItem] representedObject] ) self.theBehavior = [[behaviorPvPPopup selectedItem] representedObject];
	if ( self.theCombatProfile != [[combatProfilePvPPopup selectedItem] representedObject] ) self.theCombatProfile = [[combatProfilePvPPopup selectedItem] representedObject];

	Battleground *battleground = [self.pvpBehavior battlegroundForZone:zone];
	if ( !battleground ) {
		log(LOG_PVP,  @"Running in Easy Mode for this Battleground.");
		return NO;
	}

	// Set the Route Collection
	RouteCollection *routeCollection = [battleground routeCollection];
	if ( !routeCollection ) {
		log(LOG_PVP,  @"Cannot set environment, there is no route collection!");
		return NO;
	}

	if ( !_theRouteCollectionPvP || routeCollection != _theRouteCollectionPvP ) {
		log(LOG_DEV,  @"Setting the route collection to %@", routeCollection);
		_theRouteCollectionPvP = routeCollection;
	} else {
		log(LOG_DEV,  @"Setting the route collection already set to %@", routeCollection);
	}

	if ( !_theRouteCollectionPvP || ![_theRouteCollectionPvP routes] ) {
		log(LOG_PVP,  @"Cannot set environment, there is no route collection!");
		return NO;
	}

	float closestDistance = 0.0f;
	Waypoint *thisWaypoint = nil;
	Route *route = nil;
	RouteSet *routeSetFound;
	Position *playerPosition = [playerController position];
	float distanceToWaypoint;

	log(LOG_DEV,  @"pvpSetEnvironmentForZone: looking through routeSets");
	for (RouteSet *routeSet in [_theRouteCollectionPvP routes] ) {

		// Set the route to test against
		route = [routeSet routeForKey:PrimaryRoute];

		if ( !route || route == nil ) continue;

		if ( closestDistance == 0.0f ) {
			thisWaypoint = [route waypointClosestToPosition:playerPosition];
			closestDistance = [playerPosition distanceToPosition: [thisWaypoint position]];
			routeSetFound = [routeSet retain];
			continue;
		}

		// We have one to compare
		thisWaypoint = [route waypointClosestToPosition:playerPosition];
		distanceToWaypoint = [playerPosition distanceToPosition: [thisWaypoint position]];
		if (distanceToWaypoint < closestDistance) {
			closestDistance = distanceToWaypoint;
			if ( routeSetFound ) [routeSetFound release];
			routeSetFound = [routeSet retain];
		}
	}

	if ( _theRouteSetPvP && routeSetFound == _theRouteSetPvP ) {
		log(LOG_DEV,  @"Route set already set to %@", routeSetFound);
		[routeSetFound release];
		routeSetFound = nil;
		return YES;
	}

	if ( routeSetFound ) {
		log(LOG_DEV,  @"pvpSetEnvironmentForZone: setting to the closest route.");
		_theRouteSetPvP = routeSetFound;
		[routeSetFound release];
		routeSetFound = nil;
	} else 
	if ( [_theRouteCollectionPvP startingRoute] ) {
		log(LOG_DEV,  @"pvpSetEnvironmentForZone: setting to the starting route.");
		_theRouteSetPvP = [_theRouteCollectionPvP startingRoute];
	} else {
		log(LOG_DEV,  @"pvpSetEnvironmentForZone: setting to the first route.");
		_theRouteSetPvP = [[_theRouteCollectionPvP routes] objectAtIndex:0];
	}

	log(LOG_PVP,  @"Setting PvP route set to %@", self.theRouteSetPvP);
	return YES;
}

- (BOOL)pvpQueueBattleground {

	// error checking (removed valid player and !isPvPing)
	UInt32 zone = [playerController zone];

	if ( [playerController isInBG:zone] ){
		log(LOG_DEV,  @"Not queueing for BG, already in a BG!");
		return NO;
	}

	NSString *macroEnd = [macroController macroTextForKey:@"QueueForBattleground"];

	// doing a random? ezmode!
	if ( theCombatProfile.pvpQueueForRandomBattlegrounds ) {
		log(LOG_PVP, @"Queueing up for randoms.");

		// execute the macro
		NSString *fullMacro = [NSString stringWithFormat:@"/run a,b={%d},{}; %@", 32, macroEnd];
		[macroController useMacroOrSendCmd:fullMacro];
	} else {
		log(LOG_PVP, @"Queueing up.");
		// we have some checked!
		
		NSString *fullMacro = [NSString stringWithFormat:@"/run a,b={%@},{}; %@", [self.pvpBehavior formattedForJoinMacro], macroEnd];
		[macroController useMacroOrSendCmd:fullMacro];
	}

	// actually queue
	[macroController useMacroOrSendCmd:@"JoinBattlefield"];

	if ( [playerController battlegroundStatus] != BGQueued ) {
		log(LOG_ERROR,  @"[PvP] We just queued for the BG, but we're not queued? hmmm");
		[controller setCurrentStatus: @"PvP: Waiting in queue for Battleground."];
		return NO;
	}

	return YES;
}

- (void)pvpGetBGInfo{

	// Lets gets some info?
	if ( [playerController zone] == ZoneStrandOfTheAncients ) {

		NSArray *antipersonnelCannons = [mobController mobsWithEntryID:StrandAntipersonnelCannon];

		if ( [antipersonnelCannons count] > 0 ) {
			BOOL foundFriendly = NO, foundHostile = NO;
			for ( Mob *mob in antipersonnelCannons ) {

				int faction = [mob factionTemplate];
				BOOL isHostile = [playerController isHostileWithFaction: faction];
				log(LOG_DEV, @"Faction %d (%d) of Mob %@", faction, isHostile, mob);

				if ( isHostile ){
					foundHostile = YES;
				}
				else if ( !isHostile ){
					foundFriendly = YES;
				}
			}

			if ( foundHostile && foundFriendly ) {
				log(LOG_PVP, @"New round for Strand! Found hostile and friendly! Were we attacking last round? %d", _attackingInStrand);
				_attackingInStrand = _attackingInStrand ? NO : YES;
			}
			else if ( foundHostile ) {
				_attackingInStrand = YES;
				log(LOG_PVP, @"We're attacking in strand!");
			}
			else if ( foundFriendly ) {
				_attackingInStrand = NO;
				log(LOG_PVP, @"We're defending in strand!");
			}
		}
		// If we don't see anything, then we're attacking!
		else{
			_attackingInStrand = YES;
			log(LOG_PVP, @"We're attacking in strand!");
		}

		// Check to see if we're on the boat!
		if ( _attackingInStrand && [playerController isOnBoatInStrand]){
			_strandDelay = YES;
			log(LOG_PVP, @"We're on a boat so lets delay our movement until it settles!");
		}
	} else {
		_attackingInStrand = NO;
	}

	// Restart evaluation
	[self evaluateSituation];
}

- (IBAction)pvpTestWarning: (id)sender {
    [[NSSound soundNamed: @"alarm"] play];
}

#pragma Reversed Functions

- (int)lua_GetWorldState: (int)index{
	
	UInt32 offset = [offsetController offset:@"Lua_GetWorldStateUIInfo"];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	int32_t valid = 0x0;
	[memory loadDataForObject: self atAddress: offset + 0x8 Buffer: (Byte *)&valid BufLength: sizeof(valid)];
	
	if ( valid != -1 ){
		UInt32 v2 = 0x0, structAddress = 0x0;
		[memory loadDataForObject: self atAddress: offset Buffer: (Byte *)&v2 BufLength: sizeof(v2)];
		v2 += 12 * (index & valid);
		[memory loadDataForObject: self atAddress: v2 + (2*4) Buffer: (Byte *)&structAddress BufLength: sizeof(structAddress)];
		
		if ( ! (structAddress & 1) ){
			
			int32_t readIndex = 0x0;
			UInt32 offset = 0x0;	// potentially named wrong
			
			while ( structAddress ){
				
				// grab the next index from the world state struct
				[memory loadDataForObject: self atAddress: structAddress Buffer: (Byte *)&readIndex BufLength: sizeof(readIndex)];
				
				// found the correct index?
				if ( readIndex == index ){
					int32_t nextWintergraspTime = 0x0;
					[memory loadDataForObject: self atAddress: structAddress + (24) Buffer: (Byte *)&nextWintergraspTime BufLength: sizeof(nextWintergraspTime)];
					return nextWintergraspTime;
				}
				
				// try the next struct address
				[memory loadDataForObject: self atAddress: v2 Buffer: (Byte *)&offset BufLength: sizeof(offset)];			
				[memory loadDataForObject: self atAddress: offset+structAddress+4 Buffer: (Byte *)&structAddress BufLength: sizeof(structAddress)];
				
				// index not found
				if ( structAddress & 1 ){
					log(LOG_ERROR, @"[GetWorldState] Index %d not found", index);
					return 0;
				}
			}			
		}
	}
	
	return 0;	
}

- (double)lua_GetWintergraspWaitTime{
	
	if ( [self lua_GetWorldState:3801] > 0 )
	{
		int state = [self lua_GetWorldState:4354];
		MemoryAccess *memory = [controller wowMemoryAccess];
		
		int32_t v4 = 0x0;
		[memory loadDataForObject: self atAddress: [offsetController offset:@"Lua_GetWorldStateUIInfo"] + 0x10 Buffer: (Byte *)&v4 BufLength: sizeof(v4)];
		
		int seconds = state - (v4 + time(0));
		if ( seconds <= 0 )
			seconds = 0;
		
		return (double) seconds;
		
	}
	
	log(LOG_GENERAL, @"[Wintergrasp] Unable to find time - is wintergrasp running?");

	return -1.0f;
}

#pragma mark Timers

- (void)logOutTimer: (NSTimer*)timer {

	BOOL logOutNow = NO;
	NSString *logMessage = nil;
	
	// check for full inventory
	if ( [logOutOnFullInventoryCheckbox state] && [itemController arePlayerBagsFull] ){
		logOutNow = YES;
		logMessage = @"Inventory full, closing game";
	}
	
	// check for timer
	if ( [logOutOnTimerExpireCheckbox state] && self.startDate ){
		float hours = [logOutAfterRunningTextField floatValue];
		NSDate *stopDate = [[NSDate alloc] initWithTimeInterval:hours * 60 * 60 sinceDate:self.startDate];
		
		// check to see which date is earlier
		if ( [stopDate earlierDate: [NSDate date] ] == stopDate ){
			logOutNow = YES;
			logMessage = [NSString stringWithFormat:@"Timer expired after %0.2f hours! Logging out!", hours];
		}
	}
	
	// check durability
	if ( [logOutOnBrokenItemsCheckbox state] ){
		float averageDurability = [itemController averageWearableDurability];
		float durabilityPercentage = [logOutAfterRunningTextField floatValue];
		
		if ( averageDurability > 0 && averageDurability < durabilityPercentage ){
			logOutNow = YES;
			logMessage = [NSString stringWithFormat:@"Item durability has reached %02.f, logging out!", averageDurability];
		}
	}
	
	// check honor
	if ( theCombatProfile.pvpStopHonor ){
		UInt32 currentHonor = [playerController honor];
		if ( currentHonor && currentHonor >= theCombatProfile.pvpStopHonorTotal ){
			logOutNow = YES;
			logMessage = [NSString stringWithFormat:@"Honor has reached %u, logging out!", currentHonor];
		}
	}

	// time to stop botting + log!
	if ( logOutNow ){

		[self logOutWithMessage:logMessage];
	}
}

// called every 30 seconds
- (void)afkTimer: (NSTimer*)timer {
	log(LOG_FUNCTION, @"afkTimer");

	if ( ![playerController playerIsValid] ) return;

	if ( ![antiAFKButton state] ) return;

	// If the player is doing something let's not interfere
	if ( ( [movementController isMoving] && ![movementController isActive] ) || // Player is moving vs movementController moving
		[playerController isCasting] || self.procedureInProgress || self.evaluationInProgress ) {
		return;
	}

	log(LOG_DEV, @"[AFK] Attempt: %d", _afkTimerCounter);

	_afkTimerCounter++;

	// then we are at 4 minutes
	if ( _afkTimerCounter > 8 ) {
		log(LOG_GENERAL, @"Triggering anti idle.");
		[movementController antiAFK];
		_afkTimerCounter = 0;
	}
}

- (void)wgTimer: (NSTimer*)timer {

	// WG zone ID: 4197
	if ( ![playerController isDead] && [playerController zone] == 4197 && [playerController playerIsValid] ) {

		NSDate *currentTime = [NSDate date];

		// then we are w/in the first hour after we've done a WG!  Let's leave party!
		if ( _dateWGEnded && [currentTime timeIntervalSinceDate: _dateWGEnded] < 3600 ){
			// check to see if they are in a party - and leave!
			UInt32 offset = [offsetController offset:@"PARTY_LEADER_PTR"];
			UInt64 guid = 0;
			if ( [[controller wowMemoryAccess] loadDataForObject: self atAddress: offset Buffer: (Byte *)&guid BufLength: sizeof(guid)] && guid ){
				[macroController useMacroOrSendCmd:@"LeaveParty"];
				log(LOG_PVP, @"Player is in party leaving!");
			}

			log(LOG_PVP, @"Leaving party anyways - there a leader? 0x%qX", guid);
			[macroController useMacroOrSendCmd:@"LeaveParty"];
		}

		// only autojoin if it's 2 hours+ after a WG end
		if ( _dateWGEnded && [currentTime timeIntervalSinceDate: _dateWGEnded] <= 7200 ) {
			log(LOG_PVP, @"Not autojoing WG since it's been %0.2f seconds", [currentTime timeIntervalSinceDate: _dateWGEnded]);
			return;
		}

		// should we auto accept quests too? o.O

		// click the button!
		[macroController useMacroOrSendCmd:@"ClickFirstButton"];
		log(LOG_PVP, @"Autojoining WG!  Seconds since last WG: %0.2f", [currentTime timeIntervalSinceDate: _dateWGEnded]);

		// check how many marks they have (if it went up, we need to leave the group)!
		Item *item = [itemController itemForID:[NSNumber numberWithInt:43589]];
		if ( item && [item isValid] ) {
			
			// it's never been set - /cry - lets set it!
			if ( _lastNumWGMarks == 0 ){
				_lastNumWGMarks = [item count];
				log(LOG_PVP, @"Setting wintegrasp mark counter to %d", _lastNumWGMarks);
			}
			
			// the player has more!
			if ( _lastNumWGMarks != [item count] ){
				_lastNumWGMarks = [item count];

				log(LOG_PVP, @"Wintergrasp over you now have %d marks! Leaving group!", _lastNumWGMarks);
				[macroController useMacroOrSendCmd:@"LeaveParty"];

				// update our time
				log(LOG_PVP, @"It's been %0.2f:: opens seconds since we were last given marks!", [currentTime timeIntervalSinceDate: _dateWGEnded]);
				[_dateWGEnded release]; _dateWGEnded = nil;
				_dateWGEnded = [[NSDate date] retain];
			}
		}
	}
}

- (int)errorValue: (NSString*) errorMessage{
	if (  [errorMessage isEqualToString: INV_FULL] ){
		return ErrInventoryFull;
	}
	else if ( [errorMessage isEqualToString:TARGET_LOS] ){
		return ErrTargetNotInLOS;
	}
	else if ( [errorMessage isEqualToString:SPELL_NOT_READY] ){
		return ErrSpellNotReady;
	}
	else if ( [errorMessage isEqualToString:TARGET_FRNT] ){
		return ErrTargetNotInFrnt;
	}
	else if ( [errorMessage isEqualToString:CANT_MOVE] ){
		return ErrCantMove;
	}
	else if ( [errorMessage isEqualToString:WRNG_WAY] ){
		return ErrWrng_Way;
	}
	else if ( [errorMessage isEqualToString:ATTACK_STUNNED] ){
		return ErrAttack_Stunned;
	}
	else if ( [errorMessage isEqualToString:NOT_YET] ){
		return ErrSpell_Cooldown;
	}
	else if ( [errorMessage isEqualToString:SPELL_NOT_READY2] ){
		return ErrSpellNot_Ready;
	}
	else if ( [errorMessage isEqualToString:NOT_RDY2] ){
		return ErrSpellNot_Ready;
	}
	else if ( [errorMessage isEqualToString:TARGET_RNGE] ){
		return ErrTargetOutRange;
	}
// This one is really more for Melee that isn't close enough for melee attack so we don't need to handle it like we do out of range
	else if ( [errorMessage isEqualToString:TARGET_RNGE2] ){
		return ErrYouAreTooFarAway;
	}
	else if ( [errorMessage isEqualToString:INVALID_TARGET] || [errorMessage isEqualToString:CANT_ATTACK_TARGET] ) {
		return ErrInvalidTarget;
	}
	else if ( [errorMessage isEqualToString:CANT_ATTACK_MOUNTED] ){
		return ErrCantAttackMounted;
	}
	else if ( [errorMessage isEqualToString:YOU_ARE_MOUNTED] ){
		return ErrYouAreMounted;
	}
	else if ( [errorMessage isEqualToString:TARGET_DEAD] ){
		return ErrTargetDead;
	}
	else if ( [errorMessage isEqualToString:MORE_POWERFUL_SPELL_ACTIVE] ){
		return ErrMorePowerfullSpellActive;
	}
	else if ( [errorMessage isEqualToString:HAVE_NO_TARGET] ){
		return ErrHaveNoTarget;
	}
	else if ( [errorMessage isEqualToString:CANT_DO_THAT_WHILE_STUNNED] ){
		return ErrCantDoThatWhileStunned;
	}
	else if ( [errorMessage isEqualToString:CANT_DO_THAT_WHILE_SILENCED] ){
		return ErrCantDoThatWhileSilenced;
	}
	else if ( [errorMessage isEqualToString:CANT_DO_THAT_WHILE_INCAPACITATED] ){
		return ErrCantDoThatWhileIncapacitated;
	}
	
	return ErrNotFound;
}


- (void)interactWithMob:(UInt32)entryID {
	Mob *mobToInteract = [mobController closestMobForInteraction:entryID];
	
	if ([mobToInteract isValid]) {
		[self interactWithMouseoverGUID:[mobToInteract cachedGUID]];
	}
}

- (void)interactWithNode:(UInt32)entryID {
	Node *nodeToInteract = [nodeController closestNodeForInteraction:entryID];
	
	if([nodeToInteract isValid]) {
		[self interactWithMouseoverGUID:[nodeToInteract cachedGUID]];
	}
	else{
		log(LOG_GENERAL, @"[Bot] Node %d not found, unable to interact", entryID);
	}
}

// This will set the GUID of the mouseover + trigger interact with mouseover!
- (BOOL)interactWithMouseoverGUID: (UInt64) guid{
	if ( [[controller wowMemoryAccess] saveDataForAddress: ([offsetController offset:@"TARGET_TABLE_STATIC"] + TARGET_MOUSEOVER) Buffer: (Byte *)&guid BufLength: sizeof(guid)] ){
		
		// wow needs time to process the change
		usleep([controller refreshDelay]);
		
		return [bindingsController executeBindingForKey:BindingInteractMouseover];
	}
	
	return NO;
}

// Simply will log us out!
- (void)logOut{
	
	if ( [logOutUseHearthstoneCheckbox state] && (_zoneBeforeHearth == -1) ){
		
		// Can only use if it's not on CD!
		if ( ![spellController isSpellOnCooldown:HearthStoneSpellID] ){
			
			_zoneBeforeHearth = [playerController zone];
			// Use our hearth
			UInt32 actionID = (USE_ITEM_MASK + HearthstoneItemID);
			[self performAction:actionID];
			
			// Kill bot + log out
			[self performSelector:@selector(logOut) withObject: nil afterDelay:25.0f];
			
			return;
		}
	}
	
	// The zones *should* be different
	if ( [logOutUseHearthstoneCheckbox state] ){
		if ( _zoneBeforeHearth != [playerController zone] ){
			log(LOG_GENERAL, @"[Bot] Hearth successful from zone %d to %d", _zoneBeforeHearth, [playerController zone]);
		}
		else{
			log(LOG_GENERAL, @"[Bot] Sorry hearth failed for some reason (on CD?), still closing WoW!");
		}
	}
	
	// Reset our variable in case the player fires up wow again later
	_zoneBeforeHearth = -1;
	
	// Stop the bot
	[self stopBot: nil];
	usleep(1000000);
	
	// Kill the process
	[controller killWOW];
}

// check if units are nearby
- (BOOL)scaryUnitsNearNode: (WoWObject*)node doMob:(BOOL)doMobCheck doFriendy:(BOOL)doFriendlyCheck doHostile:(BOOL)doHostileCheck{
	if ( doMobCheck ){
		log(LOG_DEV, @"Scanning nearby mobs within %0.2f of %@", theCombatProfile.GatherNodesMobNearRange, [node position]);
		NSArray *mobs = [mobController mobsWithinDistance: theCombatProfile.GatherNodesMobNearRange MobIDs:nil position:[node position] aliveOnly:YES];
		if ( [mobs count] ){
			log(LOG_NODE, @"There %@ %d scary mob(s) near the node, ignoring %@", ([mobs count] == 1) ? @"is" : @"are", [mobs count], node);
			return YES;
		}
	}
	if ( doFriendlyCheck ){
		if ( [playersController playerWithinRangeOfUnit: theCombatProfile.GatherNodesFriendlyPlayerNearRange Unit:(Unit*)node includeFriendly:YES includeHostile:NO] ){
			log(LOG_NODE, @"Friendly player(s) near node, ignoring %@", node);
			return YES;
		}
	}
	if ( doHostileCheck ) {
		if ( [playersController playerWithinRangeOfUnit: theCombatProfile.GatherNodesHostilePlayerNearRange Unit:(Unit*)node includeFriendly:NO includeHostile:YES] ){
			log(LOG_NODE, @"Hostile player(s) near node, ignoring %@", node);
			return YES;
		}
	}
	
	return NO;
}

- (UInt8)isHotKeyInvalid{
	
	// We know it's not set if flags are 0 or code is -1 then it's not set!
	UInt8 flags = 0;
	
	// Check start/stop hotkey
	KeyCombo combo = [startstopRecorder keyCombo];
	if ( combo.code == -1 ){
		flags |= HotKeyStartStop;
	}
	
	return flags;	
}

- (char*)randomString: (int)maxLength{
	// generate a random string to write
	int i, len = SSRandomIntBetween(3,maxLength);
	char *string = (char*)malloc(len);
	char randomChar = 0;
    for (i = 0; i < len; i++) {
		while (YES) {
			randomChar = SSRandomIntBetween(0,128);
			if (((randomChar >= '0') && (randomChar <= '9')) || ((randomChar >= 'a') && (randomChar <= 'z'))) {
				string[i] = randomChar;
				break; // we found an alphanumeric character, move on
			}
		}
    }
	string[i] = '\0';
	
	return string;
}

#pragma mark Waypoint Action stuff

// set the new combat profile + select it in the dropdown!
- (void)changeCombatProfile:(CombatProfile*)profile{
	
	log(LOG_GENERAL, @"[Bot] Switching to combat profile %@", profile);
	self.theCombatProfile = profile;
	
	for ( NSMenuItem *item in [combatProfilePopup itemArray] ){
		if ( [[(CombatProfile*)[item representedObject] name] isEqualToString:[profile name]] ){
			[combatProfilePopup selectItem:item];
			break;
		}
	}
}

- (NSString*)isRouteSound: (Route*)route withName:(NSString*)name{
	log(LOG_DEV, @"isRouteSound called for %@", route);
	NSMutableString *errorMessage = [NSMutableString string];
	// loop through!
	int wpNum = 1;
	for ( Waypoint *wp in [route waypoints] ) {
		if ( wp.actions && [wp.actions count] ) {
			for ( Action *action in wp.actions ) {

				if ( [action type] == ActionType_SwitchRoute ) {

					RouteSet *switchRoute = nil;
					NSString *UUID = [action value];
					for ( RouteSet *otherRoute in [waypointController routes] ){
						if ( [UUID isEqualToString:[otherRoute UUID]] ){
							switchRoute = otherRoute;
							break;
						}
					}

					// check this route for issues
					if ( switchRoute != nil ){
						[errorMessage appendString:[self isRouteSetSound:switchRoute]];
					}
					else{
						[errorMessage appendString:[NSString stringWithFormat:@"Error on route '%@'\r\n\tSwitch route not found on waypoint action %d\r\n", name, wpNum]];
					}
				}
				
				else if ( [action type] == ActionType_CombatProfile ){
					BOOL profileFound = NO;
					NSString *UUID = [action value];
					for ( CombatProfile *otherProfile in [profileController combatProfiles] ){
						if ( [UUID isEqualToString:[otherProfile UUID]] ){
							profileFound = YES;
							break;
						}
					}
					if ( !profileFound ){
						[errorMessage appendString:[NSString stringWithFormat:@"Error on route '%@'\r\n\tCombat profile not found on waypoint action %d\r\n", name, wpNum]];
					}
				}
			}			
		}

		wpNum++;
	}
	
	return errorMessage;
}

// this will loop through to make sure we actually have the correct routes + profiles!
- (NSString*)isRouteSetSound: (RouteSet*)route{
	
	// so we don't get stuck in an infinite loop
	if ( [_routesChecked containsObject:[route UUID]] ){
		return [NSString string];
	}
	[_routesChecked addObject:[route UUID]];
	
	NSMutableString *errorMessage = [NSMutableString string];
	
	// verify primary route
	Route *primaryRoute  = [route routeForKey: PrimaryRoute];
	[errorMessage appendString:[self isRouteSound:primaryRoute withName:[route name]]];
	
	// verify corpse route
	Route *corpseRunRoute = [route routeForKey: CorpseRunRoute];
	[errorMessage appendString:[self isRouteSound:corpseRunRoute withName:[route name]]];
	
	if ( !errorMessage || [errorMessage length] == 0 ){
		return [NSString string];
	}
	
	return errorMessage;
}

#pragma mark Testing Shit

// what is the purpose of this function?  Well let me tell you!
// Grab some values from the offset controller, and verify they seem correct
// Nothing is exact, just based on my past experiences
// should move to OffsetController once this is built up enough
- (IBAction)confirmOffsets: (id)sender{
	
	
	UInt32 offset = 0x0, offset2 = 0x0, offset3 = 0x0, offset4 = 0x0, offset5 = 0x0, offset6 = 0x0;
	
	// baseAddress + PlayerField_Pointer = player fields!
	// 0x131C in 4.0.1
	offset = [offsetController offset:@"PlayerField_Pointer"];
	if ( offset < 0x1000 || offset > 0x2000 ){
		PGLog(@"[OffsetTest] PlayerField_Pointer invalid? 0x%X", offset);
	}
	
	// we just want to make sure they are close to each other (all should be w/in 0x28)
	// As of 4.0.1
	// BaseField_Spell_ToCast: 0xB00
	// BaseField_Spell_Casting: 0xB0C
	// BaseField_Spell_TimeEnd: 0xB1C
	// BaseField_Spell_Channeling: 0xB20
	// BaseField_Spell_ChannelTimeEnd: 0xB24
	// BaseField_Spell_ChannelTimeStart: 0xB28
	offset = [offsetController offset:@"BaseField_Spell_ToCast"];
	offset2 = [offsetController offset:@"BaseField_Spell_Casting"];
	offset3 = [offsetController offset:@"BaseField_Spell_TimeEnd"];
	offset4 = [offsetController offset:@"BaseField_Spell_Channeling"];
	offset5 = [offsetController offset:@"BaseField_Spell_ChannelTimeEnd"];
	offset6 = [offsetController offset:@"BaseField_Spell_ChannelTimeStart"];
	
	// this obviously doesn't indicate a problem
	PGLog(@"BaseField_Spell_ToCast: 0x%X", offset);
	
	// BaseField_Spell_ChannelTimeStart
	UInt32 result = offset6 - offset;
	if ( result > 0x40 || result < 0x0 ){
		PGLog(@"BaseField_Spell_ChannelTimeStart: 0x%X", offset6);
	}
	
	// BaseField_Spell_ChannelTimeEnd
	result = offset5 - offset;
	if ( result > 0x40 || result < 0x0 ){
		PGLog(@"BaseField_Spell_ChannelTimeEnd: 0x%X", offset5);
	}
	
	// BaseField_Spell_Channeling
	result = offset4 - offset;
	if ( result > 0x40 || result < 0x0 ){
		PGLog(@"BaseField_Spell_Channeling: 0x%X", offset4);
	}
	
	// BaseField_Spell_TimeEnd
	result = offset3 - offset;
	if ( result > 0x40 || result < 0x0 ){
		PGLog(@"BaseField_Spell_TimeEnd: 0x%X", offset3);
	}
	
	// BaseField_Spell_Casting
	result = offset2 - offset;
	if ( result > 0x40 || result < 0x0 ){
		PGLog(@"BaseField_Spell_Casting: 0x%X", offset2);
	}
	
	
}

- (IBAction)test: (id)sender{
	
	NSLog(@"Runes? %d %d %d", [playerController runesAvailable:0], [playerController runesAvailable:1], [playerController runesAvailable:2]);
							   
	NSLog(@"offset: 0x%X", [offsetController offset:@"Lua_GetRuneCount"]);
	
	NSLog(@"Time: %d", [playerController currentTime]);
	
	NSLog(@"Eclipse power: %d", [[playerController player] currentPowerOfType: UnitPower_Eclipse]);
	
	return;
	
	
	/*
	
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	UInt32 UIBase = 0x0, FirstFrame = 0x0, NextFrame = 0x0;;
	[memory loadDataForObject: self atAddress: 0xE9EA00 Buffer: (Byte*)&UIBase BufLength: sizeof(UIBase)];
	[memory loadDataForObject: self atAddress: 0xE9EA00 + 0xCE4 Buffer: (Byte*)&FirstFrame BufLength: sizeof(FirstFrame)];
	[memory loadDataForObject: self atAddress: 0xE9EA00 + 0xCDC Buffer: (Byte*)&NextFrame BufLength: sizeof(NextFrame)];
	
	UInt32 Frame = FirstFrame;
	
	if ( Frame & 1 || !Frame ){
		Frame = 0;
	}
	
	for ( i = 0; !(Frame & 1); 
	
	
	v1 = *(_DWORD *)(dword_E9EA00 + 0xCE4);
	if ( v1 & 1 || !v1 )
		v1 = 0;
	for ( i = 0; !(v1 & 1); v1 = *(_DWORD *)(*(_DWORD *)(dword_E9EA00 + 0xCDC) + v1 + 4) )
	{
		if ( !v1 )
			break;
		++i;
	}

	*/
	
	
	
	
	
	
	
	
	
	SpellDbc spell;
	NSLog(@"O rly? %@", databaseManager);
	[databaseManager getObjectForRow:34898 withTable:Spell_ withStruct:&spell withStructSize:(size_t)sizeof(spell)];
	
	NSLog(@"What did we find? 0x%X", spell.Id);
	
	
	/*
	 UInt32 address = 0xC2141C;
	 
	 float val = 0.0f;
	 [memory loadDataForObject: self atAddress: address Buffer: (Byte*)&val BufLength: sizeof(val)];
	 
	 NSLog(@"Value: %f", val);
	 
	 
	 val = 0.0f;
	 int result = [memory saveDataForAddress: address Buffer: (Byte*)&val BufLength: sizeof(val)];
	 NSLog(@"fail? %d", result);	
	 NSLog(@"changing to %0.2f!", val);
	 
	 [memory loadDataForObject: self atAddress: address Buffer: (Byte*)&val BufLength: sizeof(val)];
	 NSLog(@"Value: %f", val);
	 
	 return;
	 
	 [profileController profilesByClass];*/
	
}

- (IBAction)test2: (id)sender{
	/*
	 Position *pos = [[Position alloc] initWithX: -4968.875 Y:-1208.304 Z:501.715];
	 Position *playerPosition = [playerController position];
	 
	 log(LOG_GENERAL, @"Distance: %0.2f", [pos distanceToPosition:playerPosition]);
	 
	 Position *newPos = [pos positionAtDistance:10.0f withDestination:playerPosition];
	 
	 log(LOG_GENERAL, @"New pos: %@", newPos);
	 
	 [movementController setClickToMove:newPos andType:ctmWalkTo andGUID:0x0];
	 */
}

- (int)CompareFactionHash: (int)hash1 withHash2:(int)hash2{	
	if ( hash1 == 0 || hash2 == 0 )
		return -1;
	
	UInt32 hashCheck1 = 0, hashCheck2 = 0;
	UInt32 check1 = 0, check2 = 0;
	int hashCompare = 0, hashIndex = 0, i = 0;
	//Byte *bHash1[0x40];
	//Byte *bHash2[0x40];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	//[memory loadDataForObject: self atAddress: hash1 Buffer: (Byte*)&bHash1 BufLength: sizeof(bHash1)];
	//[memory loadDataForObject: self atAddress: hash2 Buffer: (Byte*)&bHash2 BufLength: sizeof(bHash2)];
	
	// get the hash checks
	[memory loadDataForObject: self atAddress: hash1 + 0x4 Buffer: (Byte*)&hashCheck1 BufLength: sizeof(hashCheck1)];
	[memory loadDataForObject: self atAddress: hash2 + 0x4 Buffer: (Byte*)&hashCheck2 BufLength: sizeof(hashCheck2)];
	
	//bitwise compare of [bHash1+0x14] and [bHash2+0x0C]
	[memory loadDataForObject: self atAddress: hash1 + 0x14 Buffer: (Byte*)&check1 BufLength: sizeof(check1)];
	[memory loadDataForObject: self atAddress: hash2 + 0xC Buffer: (Byte*)&check2 BufLength: sizeof(check2)];
	if ( ( check1 & check2 ) != 0 )
		return 1;	// hostile
	
	hashIndex = 0x18;
	[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
	if ( hashCompare != 0 ){
		for ( i = 0; i < 4; i++ ){
			if ( hashCompare == hashCheck2 )
				return 1; // hostile
			
			hashIndex += 4;
			[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
			
			if ( hashCompare == 0 )
				break;
		}
	}
	
	//bitwise compare of [bHash1+0x10] and [bHash2+0x0C]
	[memory loadDataForObject: self atAddress: hash1 + 0x10 Buffer: (Byte*)&check1 BufLength: sizeof(check1)];
	[memory loadDataForObject: self atAddress: hash2 + 0xC Buffer: (Byte*)&check2 BufLength: sizeof(check2)];
	if ( ( check1 & check2 ) != 0 ){
		log(LOG_GENERAL, @"friendly");
		return 4;	// friendly
	}
	
	hashIndex = 0x28;
	[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
	if ( hashCompare != 0 ){
		for ( i = 0; i < 4; i++ ){
			if ( hashCompare == hashCheck2 ){
				log(LOG_GENERAL, @"friendly2");
				return 4;	// friendly
			}
			
			hashIndex += 4;
			[memory loadDataForObject: self atAddress: hash1 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
			
			if ( hashCompare == 0 )
				break;
		}
	}
	
	//bitwise compare of [bHash2+0x10] and [bHash1+0x0C]
	[memory loadDataForObject: self atAddress: hash2 + 0x10 Buffer: (Byte*)&check1 BufLength: sizeof(check1)];
	[memory loadDataForObject: self atAddress: hash1 + 0xC Buffer: (Byte*)&check2 BufLength: sizeof(check2)];
	if ( ( check1 & check2 ) != 0 ){
		log(LOG_GENERAL, @"friendly3");
		return 4;	// friendly
	}
	
	hashIndex = 0x28;
	[memory loadDataForObject: self atAddress: hash2 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
	if ( hashCompare != 0 ){
		for ( i = 0; i < 4; i++ ){
			if ( hashCompare == hashCheck1 ){
				log(LOG_GENERAL, @"friendly4");
				return 4;	// friendly
			}
			
			hashIndex += 4;
			[memory loadDataForObject: self atAddress: hash2 + hashIndex Buffer: (Byte*)&hashCompare BufLength: sizeof(hashCompare)];
			
			if ( hashCompare == 0 )
				break;
		}
	}
	
	return 3;	//neutral
}

- (void)startClick{
	
	
	if ( [playerController isDead] ){
		log(LOG_GENERAL, @"Player died, stopping");
		return;
	}
	
	[macroController useMacro:@"AuctioneerClick"];
	
	[self performSelector:@selector(startClick) withObject:nil afterDelay:1.0f];	
}

- (IBAction)maltby: (id)sender{
	
	[self startClick];
}

#define ACCOUNT_NAME_SEP	@"SET accountName \""
#define ACCOUNT_LIST_SEP	@"SET accountList \""
/*
 
 SET accountName "myemail@hotmail.com"
 SET accountList "!ACCOUNT1|ACCOUNT2|"
 */
- (IBAction)login: (id)sender{
	//LOGIN_STATE		this will be "login", "charselect", or "charcreate"
	//	note: it will stay in it's last state even if we are logged in + running around!
	
	//LOGIN_SELECTED_CHAR - we want to write the position to memory, the chosen won't change on screen, but it will log into that char!
	//	values: 0-max
	
	//LOGIN_TOTAL_CHARACTERS - obviously the total number of characters on the selection screen
	
	NSString *account = @"MyBNETAccount12312";
	NSString *password = @"My1337Password";
	NSString *accountList = @"!Accoun23t1|Accoun1t2|";
	
	
	
	// ***** GET THE PATH TO OUR CONFIG FILE
	NSString *configFilePath = [controller wowPath];
	// will be the case if wow is closed (lets go with the default option?)
	if ( [configFilePath length] == 0 ){
		[configFilePath release]; configFilePath = nil;
		configFilePath = @"/Applications/World of Warcraft/WTF/Config.wtf";
	}
	// we have a dir
	else{
		configFilePath = [configFilePath stringByDeletingLastPathComponent];
		configFilePath = [configFilePath stringByAppendingPathComponent: @"WTF/Config.wtf"];	
	}
	
	
	// ***** GET OUR CONFIG FILE DATA + BACK IT UP!
	NSString *configData = [[NSString alloc] initWithContentsOfFile:configFilePath];
	NSMutableString *newConfigFile = [NSMutableString string];
	NSMutableString *configFileBackup = [NSString stringWithFormat:@"%@.bak", configFilePath];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ( ![fileManager fileExistsAtPath:configFilePath] || [configData length] == 0 ){
		log(LOG_GENERAL, @"[Bot] Unable to find config file at path '%@'. Aborting.", configFilePath);
		return;
	}
	// should we create a backup file?
	if ( ![fileManager fileExistsAtPath:configFileBackup] ){
		if ( ![configData writeToFile:configFileBackup atomically:YES encoding:NSUnicodeStringEncoding error:nil] ){
			log(LOG_GENERAL, @"[Bot] Unable to backup existing config file to '%@'. Aborting", configFileBackup);
			return;
		}
	}
	
	// if we get here we have a config file! And have backed it up!
	
	
	// Three conditions for information in this file:
	//	1. Account list and Account name are set
	//	2. Account list is set (when remember checkbox was once checked, but is no longer)
	//	3. Neither exist in config file
	if ( configData != nil ){
		
		NSScanner *scanner = [NSScanner scannerWithString: configData];
		
		BOOL accountNameFound = NO;
		BOOL accountListFound = NO;
		NSString *beforeAccountName = nil;
		NSString *beforeAccountList = nil;
		
        // get the account name?
		int scanSave = [scanner scanLocation];
		log(LOG_GENERAL, @"Location: %d", [scanner scanLocation]);
        if([scanner scanUpToString: ACCOUNT_NAME_SEP intoString: &beforeAccountName] && [scanner scanString: ACCOUNT_NAME_SEP intoString: nil]) {
            NSString *newName = nil;
            if ( [scanner scanUpToString: @"\"" intoString: &newName] && newName && [newName length] ) { 
				//log(LOG_GENERAL, @"Account name: %@", newName);
				accountNameFound = YES;
            }
        }
		
		// if the user doesn't have "remember" checked, the above search will fail, so lets reset to find the account list! (maybe?)
		if ( !accountNameFound ){
			[scanner setScanLocation: scanSave];
		}
		
		// get the account list
		scanSave = [scanner scanLocation];
		log(LOG_GENERAL, @"Location: %d %d", [scanner scanLocation], [beforeAccountName length]);
        if ( [scanner scanUpToString: ACCOUNT_LIST_SEP intoString: &beforeAccountList] && [scanner scanString: ACCOUNT_LIST_SEP intoString: nil] ) {
            NSString *newName = nil;
            if ( [scanner scanUpToString: @"\"" intoString: &newName] && newName && [newName length] ) {
				//log(LOG_GENERAL, @"Account list: %@", newName);
				accountListFound = YES;
            }
        }
		
		// reset the location, in case we have info after our login info + can add it back to the config file!
		if ( !accountListFound ){
			[scanner setScanLocation: scanSave];
		}
		log(LOG_GENERAL, @"Location: %d %d", [scanner scanLocation], [beforeAccountList length]);
		// save what we have left in the scanner! There could be config data after our account name!
		NSString *endOfConfigFileData = [[scanner string]substringFromIndex:[scanner scanLocation]];
		
		// condition 1: we have an existing account! we need to replace it (and potentially an account list to add)
		if ( accountNameFound ){
			// add our new account name
			[newConfigFile appendString:beforeAccountName];
			[newConfigFile appendString:ACCOUNT_NAME_SEP];
			[newConfigFile appendString:account];
			[newConfigFile appendString:@"\""];
			
			// did we also have an account list to replace?
			if ( [accountList length] ){
				[newConfigFile appendString:@"\n"];
				[newConfigFile appendString:ACCOUNT_LIST_SEP];
				[newConfigFile appendString:accountList];
				[newConfigFile appendString:@"\""];
			}
		}
		
		// condition 2: only the account list was found, add the account name + potentially replace the account list
		else if ( accountListFound ){
			[newConfigFile appendString:beforeAccountList];
			[newConfigFile appendString:ACCOUNT_NAME_SEP];
			[newConfigFile appendString:account];
			[newConfigFile appendString:@"\""];
			
			if ( [accountList length] ){
				[newConfigFile appendString:@"\n"];
				[newConfigFile appendString:ACCOUNT_LIST_SEP];
				[newConfigFile appendString:accountList];
				[newConfigFile appendString:@"\""];
			}
		}
		
		// condition 3: nothing was found
		else{
			[newConfigFile appendString:beforeAccountList];
			[newConfigFile appendString:ACCOUNT_NAME_SEP];
			[newConfigFile appendString:account];
			[newConfigFile appendString:@"\""];
			
			if ( [accountList length] ){
				[newConfigFile appendString:@"\n"];
				[newConfigFile appendString:ACCOUNT_LIST_SEP];
				[newConfigFile appendString:accountList];
				[newConfigFile appendString:@"\""];
			}
		}
		
		// only add data if we found an account name or list!
		if ( ( accountListFound || accountNameFound ) && [endOfConfigFileData length] ){
			[newConfigFile appendString:endOfConfigFileData];
		}
		
	}
	
	// write our new config file!
	[newConfigFile writeToFile:configFileBackup atomically:YES encoding:NSUnicodeStringEncoding error:nil];
	log(LOG_GENERAL, @"[Bot] New config file written to '%@'", configFilePath);
	
	// make sure wow is open
	if ( [controller isWoWOpen] ){
		
		[chatController sendKeySequence:account];
		usleep(50000);
		[chatController sendKeySequence:password];	   
		
	}
}

#pragma Testing/Development Info (Generally Reversing)

@end
