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

#import <Cocoa/Cocoa.h>

@class Mob;
@class Unit;
@class Rule;
@class Condition;
@class Behavior;
@class WoWObject;
@class Waypoint;
@class Route;
@class RouteSet;
@class RouteCollection;
@class CombatProfile;
@class PvPBehavior;
@class Position;

@class PTHotKey;
@class SRRecorderControl;
@class BetterSegmentedControl;

@class PlayerDataController;
@class PlayersController;
@class InventoryController;
@class AuraController;
@class NodeController;
@class MovementController;
@class CombatController;
@class SpellController;
@class MobController;
@class ChatController;
@class ChatLogController;
@class ChatLogEntry;
@class Controller;
@class WaypointController;
@class ProcedureController;
@class QuestController;
@class CorpseController;
@class LootController;
@class FishController;
@class MacroController;
@class OffsetController;
@class MemoryViewController;
@class BlacklistController;
@class StatisticsController;
@class BindingsController;
@class PvPController;
@class DatabaseManager;
@class ProfileController;

@class ScanGridView;

#define ErrorSpellNotReady				@"ErrorSpellNotReady"
#define ErrorTargetNotInLOS				@"ErrorTargetNotInLOS"
#define ErrorInvalidTarget				@"ErrorInvalidTarget"
#define ErrorTargetOutOfRange			@"ErrorTargetOutOfRange"
#define ErrorTargetNotInFront			@"ErrorTargetNotInFront"
#define ErrorHaveNoTarget				@"ErrorHaveNoTarget"
#define ErrorMorePowerfullSpellActive	@"ErrorMorePowerfullSpellActive"
#define ErrorCantDoThatWhileStunned		@"ErrorCantDoThatWhileStunned"

#define BotStarted					@"BotStarted"

// Hotkey set flags
#define	HotKeyStartStop				0x1
#define HotKeyInteractMouseover		0x2
#define HotKeyPrimary				0x4
#define HotKeyPetAttack				0x8

@interface BotController : NSObject {
    IBOutlet Controller             *controller;
    IBOutlet ChatController         *chatController;
	IBOutlet ChatLogController		*chatLogController;
    IBOutlet PlayerDataController   *playerController;
    IBOutlet MobController          *mobController;
    IBOutlet SpellController        *spellController;
    IBOutlet CombatController       *combatController;
    IBOutlet MovementController     *movementController;
    IBOutlet NodeController         *nodeController;
    IBOutlet AuraController         *auraController;
    IBOutlet InventoryController    *itemController;
    IBOutlet PlayersController      *playersController;
	IBOutlet LootController			*lootController;
	IBOutlet FishController			*fishController;
	IBOutlet MacroController		*macroController;
	IBOutlet OffsetController		*offsetController;
    IBOutlet WaypointController     *waypointController;
    IBOutlet ProcedureController    *procedureController;
	IBOutlet MemoryViewController	*memoryViewController;
	IBOutlet BlacklistController	*blacklistController;
	IBOutlet StatisticsController	*statisticsController;
	IBOutlet BindingsController		*bindingsController;
	IBOutlet PvPController			*pvpController;
	IBOutlet DatabaseManager		*databaseManager;
	IBOutlet ProfileController		*profileController;

	IBOutlet QuestController		*questController;
	IBOutlet CorpseController		*corpseController;

	IBOutlet Route					*Route;	// is this right?

    IBOutlet NSView *view;

	RouteCollection *_theRouteCollection;
	RouteCollection *_theRouteCollectionPvP;
    RouteSet *_theRouteSet;
    RouteSet *_theRouteSetPvP;
    Behavior *theBehavior;
    Behavior *theBehaviorPvP;
    CombatProfile *theCombatProfile;
	PvPBehavior *_pvpBehavior;
    //BOOL attackPlayers, attackNeutralNPCs, attackHostileNPCs, _ignoreElite;
    //int _currentAttackDistance, _minLevel, _maxLevel, _attackAnyLevel;
    
	BOOL _useRoute;
	BOOL _useRoutePvP;

	int _sleepTimer;
	UInt32 _lastSpellCastGameTime;
	UInt32 _lastSpellCast;
    BOOL _isBotting;
    BOOL _didPreCombatProcedure;
    NSString *_procedureInProgress;
	NSString *_evaluationInProgress;
	BOOL _evaluationIsActive;
	
	NSString *_lastProcedureExecuted;
    Mob *_mobToSkin;
	Mob *_mobJustSkinned;
    Unit *preCombatUnit;
	Unit *_castingUnit;		// the unit we're casting on!

    NSMutableArray *_mobsToLoot;
    int _reviveAttempt;
	int _ghostDance;
	int _skinAttempt;
    NSSize minSectionSize, maxSectionSize;
	NSDate *startDate;
	int _lastActionErrorCode;
	UInt32 _lastActionTime;
	int _zoneBeforeHearth;
	UInt64 _lastCombatProcedureTarget;
	
	BOOL _movingToCorpse;
	
	// healing shit
	BOOL _shouldFollow;
	Unit *_lastUnitAttemptedToHealed;
	BOOL _includeFriendly;
	BOOL _includeFriendlyPatrol;
	BOOL _includeCorpsesPatrol;
	
	// improved loot shit
	WoWObject *_lastAttemptedUnitToLoot;
	NSMutableDictionary *_lootDismountCount;
	int _lootMacroAttempt;
	WoWObject *_unitToLoot;
	NSDate *lootStartTime;
	NSDate *skinStartTime;
//	BOOL _lootUseItems;
	int _movingTowardMobCount;
	int _movingTowardNodeCount;
	
	NSMutableArray *_routesChecked;
	
	// new flying shit
	int _jumpAttempt;
	Position *_lastGoodFollowPosition;
	
	// mount correction (sometimes we can't mount)
	int _mountAttempt;
	NSDate *_mountLastAttempt;
	
    // pvp shit
    BOOL _isPvPing;
	BOOL _isPvpMonitoring;
	BOOL _pvpIsInBG;
	BOOL _pvpPlayWarning;
	NSTimer *_pvpTimer;
	BOOL _attackingInStrand;
	BOOL _strandDelay;
	int _strandDelayTimer;
	BOOL _waitingToLeaveBattleground;
	BOOL _waitForPvPQueue;
	BOOL _waitForPvPPreparation;
	BOOL _needToTakeQueue;

	// auto join WG options
	NSTimer *_wgTimer;
	int _lastNumWGMarks;
	NSDate *_dateWGEnded;
	
	// anti afk options
	NSTimer *_afkTimer;
	int _afkTimerCounter;
	BOOL _lastPressedWasForward;
	
	// log out options
	NSTimer *_logOutTimer;
    
	// Party
	Unit *_tankUnit;
	Unit *_assistUnit;
	BOOL _leaderBeenWaiting;
	int _partyEmoteIdleTimer;
	int _partyEmoteTimeSince;
	NSString *_lastEmote;
	int _lastEmoteShuffled;
	
	// Follow
	Route *_followRoute;
	Unit *_followUnit;
	BOOL _followSuspended;
	BOOL _followLastSeenPosition;
	BOOL _followingFlagCarrier;
	NSTimer *_followTimer;
	int _lootScanIdleTimer;
	BOOL _wasLootWindowOpen;
	
    // -----------------
    // -----------------
    
    IBOutlet NSButton *startStopButton;
    
    IBOutlet id attackWithinText;
    IBOutlet id routePopup;
    IBOutlet id routePvPPopup;
    IBOutlet id behaviorPopup;
    IBOutlet id behaviorPvPPopup;
    IBOutlet id combatProfilePopup;
    IBOutlet id combatProfilePvPPopup;
    IBOutlet id minLevelPopup;
    IBOutlet id maxLevelPopup;
    IBOutlet NSTextField *minLevelText, *maxLevelText;
    IBOutlet NSButton *anyLevelCheckbox;
    
	// Log Out options
	IBOutlet NSButton		*logOutOnBrokenItemsCheckbox;
	IBOutlet NSButton		*logOutOnFullInventoryCheckbox;
	IBOutlet NSButton		*logOutOnTimerExpireCheckbox;
	IBOutlet NSButton		*logOutAfterStuckCheckbox;
	IBOutlet NSButton		*logOutUseHearthstoneCheckbox;
	IBOutlet NSTextField	*logOutDurabilityTextField;
	IBOutlet NSTextField	*logOutAfterRunningTextField;
	
//    IBOutlet NSButton *miningCheckbox;
//    IBOutlet NSButton *herbalismCheckbox;
//	IBOutlet NSButton *netherwingEggCheckbox;
//    IBOutlet id miningSkillText;
//    IBOutlet id herbalismSkillText;
//    IBOutlet NSButton *skinningCheckbox;
//	IBOutlet NSButton *ninjaSkinCheckbox;
//    IBOutlet id skinningSkillText;
//    IBOutlet id gatherDistText;
//    IBOutlet NSButton *lootCheckbox;
	
//	IBOutlet NSTextField *fishingGatherDistanceText;
//	IBOutlet NSButton *fishingCheckbox;
//	IBOutlet NSButton *fishingApplyLureCheckbox;
//	IBOutlet NSButton *fishingOnlySchoolsCheckbox;
//	IBOutlet NSButton *fishingRecastCheckbox;
//	IBOutlet NSButton *fishingUseContainersCheckbox;
//	IBOutlet NSButton *fishingLurePopUpButton;
	
//	IBOutlet NSButton		*autoJoinWG;
	IBOutlet NSButton		*antiAFKButton;
	
//	IBOutlet NSButton *combatDisableRelease;
	
//	IBOutlet NSTextField *nodeIgnoreHostileDistanceText;
//	IBOutlet NSTextField *nodeIgnoreFriendlyDistanceText;
//	IBOutlet NSTextField *nodeIgnoreMobDistanceText;
//	IBOutlet NSButton *nodeIgnoreHostileCheckbox;
//	IBOutlet NSButton *nodeIgnoreFriendlyCheckbox;
//	IBOutlet NSButton *nodeIgnoreMobCheckbox;
	
//	IBOutlet NSButton *lootUseItemsCheckbox;
    
    IBOutlet NSPanel *hotkeyHelpPanel;
    IBOutlet NSPanel *lootHotkeyHelpPanel;
//	IBOutlet NSPanel *gatheringLootingPanel;
    IBOutlet SRRecorderControl *startstopRecorder;
    PTHotKey *StartStopBotGlobalHotkey;
    
    IBOutlet NSTextField *statusText;
	IBOutlet NSTextField *runningTimer;
    IBOutlet NSWindow *overlayWindow;
    IBOutlet ScanGridView *scanGrid;
	
	IBOutlet NSButton *allChatButton;
	IBOutlet NSButton *wallWalkButton;

	UInt32 _oldActionID;
	int _oldBarOffset;

}

@property (readonly) NSButton *logOutAfterStuckCheckbox;
@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite, assign) BOOL isBotting;
@property (assign) BOOL isPvPing;
@property (assign) BOOL pvpIsInBG;
@property (retain) NSString *procedureInProgress;
@property (retain) NSString *evaluationInProgress;

@property (readwrite, retain) RouteCollection *theRouteCollection;
@property (readwrite, retain) RouteCollection *theRouteCollectionPvP;
@property (readwrite, retain) RouteSet *theRouteSet;
@property (readwrite, retain) RouteSet *theRouteSetPvP;

@property (readonly, retain) Behavior *theBehavior;
@property (readonly, retain) Behavior *theBehaviorPvP;
@property (readonly, retain) PvPBehavior *pvpBehavior;
@property BOOL waitForPvPPreparation;
@property (readonly, assign) BOOL needToTakeQueue;
@property (readwrite, retain) CombatProfile *theCombatProfile;
@property (readonly, retain) Unit *preCombatUnit;
@property (readonly, retain) NSDate *lootStartTime;
@property (readonly, retain) NSDate *skinStartTime;
@property (readonly, retain) Unit *castingUnit;
@property (readonly, retain) Unit *followUnit;
@property (readonly, retain) Unit *assistUnit;
@property (readonly, retain) Unit *tankUnit;
@property (readwrite, assign) BOOL followSuspended;
@property (readonly, retain) Route *followRoute;
@property (readwrite, assign) BOOL wasLootWindowOpen;
@property (readonly, assign) BOOL includeCorpsesPatrol;
@property (readonly, assign) BOOL movingToCorpse;
@property (readonly, assign) BOOL waitForPvPQueue;
@property (readonly, assign) BOOL evaluationIsActive;
// @property (readonly, assign) BOOL nodeIgnoreMob;
// @property (readonly, assign) BOOL nodeIgnoreFriendly;
// @property (readonly, assign) BOOL nodeIgnoreHostile;

@property (readonly, retain) NSMutableArray *mobsToLoot;

- (void)testRule: (Rule*)rule;

- (BOOL)performProcedureUnitCheck: (Unit*)target withState:(NSDictionary*)state;
- (BOOL)lootScan;
- (void)resetLootScanIdleTimer;

// Input from CombatController
- (void)actOnUnit: (Unit*)unit;

// Input from MovementController;
- (void)cancelCurrentEvaluation;
- (void)cancelCurrentProcedure;
- (BOOL)combatProcedureValidForUnit: (Unit*)unit;
- (BOOL)evaluateConditionFriendlies: (Condition*)condition;
- (BOOL)evaluateConditionEnemies: (Condition*)condition;
- (void)finishedRoute: (Route*)route;
- (BOOL)evaluateSituation;
- (BOOL)evaluateForPVPQueue;
- (BOOL)evaluateForPVPBattleGround;
- (BOOL)evaluateForGhost;
- (BOOL)evaluateForParty;
- (BOOL)evaluateForFollow;
- (BOOL)evaluateForCombatContinuation;
- (BOOL)evaluateForRegen;
- (BOOL)evaluateForLoot;
- (BOOL)evaluateForCombatStart;
- (BOOL)evaluateForMiningAndHerbalism;
- (BOOL)evaluateForFishing;
- (BOOL)evaluateForPatrol;

// Party stuff
- (BOOL)establishTankUnit;
- (BOOL)establishAssistUnit;
- (BOOL)isTank:(Unit*)unit;
- (BOOL)leaderWait;
- (void)jumpIfAirMountOnGround;
- (NSString*)randomEmote: (Unit*)emoteUnit;
- (NSString*)emoteGeneral;
- (NSString*)emoteFriend;
- (NSString*)emoteSexy;

// Follow stuff
- (void)followRouteClear;
- (BOOL)followMountNow;
- (BOOL)followMountCheck;
- (Unit*)whisperCommandUnit:(ChatLogEntry*)entry;
- (BOOL)whisperCommandAllowed: (ChatLogEntry*)entry;
- (BOOL)verifyFollowUnit;
- (void)resetFollowTimer;
- (void)followRouteStartRecord;

- (IBAction)startBot: (id)sender;
- (IBAction)stopBot: (id)sender;
- (IBAction)startStopBot: (id)sender;
- (IBAction)testHotkey: (id)sender;
- (void)updateRunningTimer;

- (IBAction)editRoute: (id)sender;
- (IBAction)editRoutePvP: (id)sender;
- (IBAction)editBehavior: (id)sender;
- (IBAction)editBehaviorPvP: (id)sender;
- (IBAction)editProfile: (id)sender;
- (IBAction)editProfilePvP: (id)sender;

- (IBAction)updateStatus: (id)sender;
- (IBAction)hotkeyHelp: (id)sender;
- (IBAction)closeHotkeyHelp: (id)sender;
- (IBAction)lootHotkeyHelp: (id)sender;
- (IBAction)closeLootHotkeyHelp: (id)sender;
// - (IBAction)gatheringLootingOptions: (id)sender;
// - (IBAction)gatheringLootingSelectAction: (id)sender;

// Looting
- (BOOL)scaryUnitsNearNode: (WoWObject*)node doMob:(BOOL)doMobCheck doFriendy:(BOOL)doFriendlyCheck doHostile:(BOOL)doHostileCheck;

// PVP
- (BOOL)pvpIsBattlegroundEnding;
- (void)resetPvpTimer;
- (void)stopBotActions;
- (void)joinBGCheck;

// test stuff
- (IBAction)confirmOffsets: (id)sender;
- (IBAction)test: (id)sender;
- (IBAction)test2: (id)sender;
- (IBAction)maltby: (id)sender;
- (IBAction)login: (id)sender;

// Little more flexibility - casts spells! Uses items/macros!
- (BOOL)performAction: (int32_t)actionID;
- (int)errorValue: (NSString*)errorMessage;
- (BOOL)interactWithMouseoverGUID: (UInt64) guid;
- (void)interactWithMob:(UInt32)entryID;
- (void)interactWithNode:(UInt32)entryID;
- (void)logOut;

- (void)logOutWithMessage:(NSString*)message;

// for new action/conditions
- (BOOL)evaluateRule: (Rule*)rule withTarget: (Unit*)target asTest: (BOOL)test;
- (void)resetHotBarAction;

- (void) updateRunningTimer;

- (UInt8)isHotKeyInvalid;

// from movement controller (for new WP actions!)
- (void)changeCombatProfile:(CombatProfile*)profile;

@end
