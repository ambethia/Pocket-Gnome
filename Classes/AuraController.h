//
//  AuraController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/26/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Unit;
@class PlayerDataController;

#define BuffGainNotification @"BuffGainNotification"
#define BuffFadeNotification @"BuffFadeNotification"

#define DispelTypeMagic     @"Magic"
#define DispelTypeCurse     @"Curse"
#define DispelTypePoison    @"Poison"
#define DispelTypeDisease   @"Disease"

@interface AuraController : NSObject {
    IBOutlet id controller;
    IBOutlet PlayerDataController *playerController;
    IBOutlet id spellController;
    IBOutlet id mobController;

    BOOL _firstRun;
    NSMutableArray *_auras;
    
    IBOutlet NSPanel *aurasPanel;
    IBOutlet NSTableView *aurasPanelTable;
    NSMutableArray *_playerAuras;
}
+ (AuraController *)sharedController;

- (void)showAurasPanel;

// IDs: NO - returns an array of Auras
// IDs: YES - returns an array of NSNumbers (spell ID)
- (NSArray*)aurasForUnit: (Unit*)unit idsOnly: (BOOL)IDs;

// hasAura & hasAuraNamed functions return the stack count of the spell (even though it says BOOL)
// auraType functions only return a BOOL
- (BOOL)unit: (Unit*)unit hasAura: (unsigned)spellID;
- (BOOL)unit: (Unit*)unit hasAuraNamed: (NSString*)spellName;
- (BOOL)unit: (Unit*)unit hasAuraType: (NSString*)spellName;

// return stack count
- (BOOL)unit: (Unit*)unit hasDebuff: (unsigned)spellID;
- (BOOL)unit: (Unit*)unit hasBuff: (unsigned)spellID;

// return stack count
- (BOOL)unit: (Unit*)unit hasDebuffNamed: (NSString*)spellName;
- (BOOL)unit: (Unit*)unit hasBuffNamed: (NSString*)spellName;

- (BOOL)unit: (Unit*)unit hasBuffType: (NSString*)type;
- (BOOL)unit: (Unit*)unit hasDebuffType: (NSString*)type;

//- (BOOL)playerHasBuffNamed: (NSString*)spellName;

//- (BOOL)unit: (Unit*)unit hasBuff: (unsigned)spellID;
//- (BOOL)unit: (Unit*)unit hasDebuff: (unsigned)spellID;

//- (BOOL)unit: (Unit*)unit hasBuffNamed: (NSString*)spellName;
//- (BOOL)unit: (Unit*)unit hasDebuffNamed: (NSString*)spellName;

//- (BOOL)unit: (Unit*)unit hasBuffType: (NSString*)type;
//- (BOOL)unit: (Unit*)unit hasDebuffType: (NSString*)type;

@end
