//
//  Spell.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/22/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MaxSpellID 1000000

enum mountType {
    MOUNT_NONE       = 0,
    MOUNT_GROUND     = 1,
    MOUNT_AIR        = 2
};

@interface Spell : NSObject {
    NSNumber *_spellID;
    
    NSString *_name;
    NSNumber *_range;
    NSString *_dispelType;
    NSString *_school;
	NSString *_mechanic;
    NSNumber *_cooldown;
    NSNumber *_castTime;
	NSNumber *_speed;		// speed of mount
	NSNumber *_mount;		// 0 = no mount, 1 = ground mount, 2 = air mount
    BOOL _spellDataLoading;
    
    NSURLConnection *_connection;
    NSMutableData *_downloadData;
}
+ (id)spellWithID: (NSNumber*)spellID;
- (BOOL)isEqualToSpell: (Spell*)spell;

- (NSNumber*)ID;
- (void)setID: (NSNumber*)ID;
- (NSString*)name;
- (void)setName: (NSString*)name;
- (NSNumber*)range;
- (void)setRange: (NSNumber*)range;
- (NSNumber*)cooldown;
- (void)setCooldown: (NSNumber*)cooldown;
- (NSString*)school;
- (void)setSchool: (NSString*)school;
- (NSString*)mechanic;
- (void)setMechanic: (NSString*)mechanic;
- (NSString*)dispelType;
- (void)setDispelType: (NSString*)dispelType;
- (NSNumber*)mount;
- (void)setMount: (NSNumber*)mount;
- (NSNumber*)speed;
- (void)setSpeed: (NSNumber*)speed;

@property (readwrite, retain) NSNumber *castTime;

- (BOOL)isInstant;
- (BOOL)isMount;

- (NSString*)fullName;

/*- (NSNumber*)ID;
- (NSString*)name;
- (NSNumber*)rank;
- (NSNumber*)range;
- (NSString*)school;
- (NSNumber*)cooldown; */

- (void)reloadSpellData;


@end
