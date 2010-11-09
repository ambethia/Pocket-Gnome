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
 * $Id: Defines.h 315 2010-04-12 04:12:45Z Tanaris4 $
 *
 */

// from http://trinitycore.googlecode.com/hg/src/game/SharedDefines.h


// Spell.dbc

enum Powers
{
    POWER_MANA                          = 0,
    POWER_RAGE                          = 1,
    POWER_FOCUS                         = 2,
    POWER_ENERGY                        = 3,
    POWER_HAPPINESS                     = 4,
    POWER_RUNE                          = 5,
    POWER_RUNIC_POWER                   = 6,
    MAX_POWERS                          = 7,
    POWER_ALL                           = 127,    // default for class?
    POWER_HEALTH                        = 0xFFFFFFFE    // (-2 as signed value)
};

enum SpellSchools
{
    SPELL_SCHOOL_NORMAL                 = 0,
    SPELL_SCHOOL_HOLY                   = 1,
    SPELL_SCHOOL_FIRE                   = 2,
    SPELL_SCHOOL_NATURE                 = 3,
    SPELL_SCHOOL_FROST                  = 4,
    SPELL_SCHOOL_SHADOW                 = 5,
    SPELL_SCHOOL_ARCANE                 = 6
};

#define MAX_SPELL_SCHOOL                  7

enum SpellSchoolMask
{
    SPELL_SCHOOL_MASK_NONE    = 0x00,                       // not exist
    SPELL_SCHOOL_MASK_NORMAL  = (1 << SPELL_SCHOOL_NORMAL), // PHYSICAL (Armor)
    SPELL_SCHOOL_MASK_HOLY    = (1 << SPELL_SCHOOL_HOLY),
    SPELL_SCHOOL_MASK_FIRE    = (1 << SPELL_SCHOOL_FIRE),
    SPELL_SCHOOL_MASK_NATURE  = (1 << SPELL_SCHOOL_NATURE),
    SPELL_SCHOOL_MASK_FROST   = (1 << SPELL_SCHOOL_FROST),
    SPELL_SCHOOL_MASK_SHADOW  = (1 << SPELL_SCHOOL_SHADOW),
    SPELL_SCHOOL_MASK_ARCANE  = (1 << SPELL_SCHOOL_ARCANE),
	
    // unions
	
    // 124, not include normal and holy damage
    SPELL_SCHOOL_MASK_SPELL   = (SPELL_SCHOOL_MASK_FIRE   |
								 SPELL_SCHOOL_MASK_NATURE | SPELL_SCHOOL_MASK_FROST  |
								 SPELL_SCHOOL_MASK_SHADOW | SPELL_SCHOOL_MASK_ARCANE),
    // 126
    SPELL_SCHOOL_MASK_MAGIC   = (SPELL_SCHOOL_MASK_HOLY | SPELL_SCHOOL_MASK_SPELL),
	
    // 127
    SPELL_SCHOOL_MASK_ALL     = (SPELL_SCHOOL_MASK_NORMAL | SPELL_SCHOOL_MASK_MAGIC)
};

enum SpellCategory
{
    SPELL_CATEGORY_FOOD             = 11,
    SPELL_CATEGORY_DRINK            = 59,
};


// ***********************************
// Spell Attributes definitions
// ***********************************

#define SPELL_ATTR_UNK0                           0x00000001            // 0
#define SPELL_ATTR_REQ_AMMO                       0x00000002            // 1
#define SPELL_ATTR_ON_NEXT_SWING                  0x00000004            // 2 on next swing
#define SPELL_ATTR_UNK3                           0x00000008            // 3 not set in 3.0.3
#define SPELL_ATTR_UNK4                           0x00000010            // 4
#define SPELL_ATTR_TRADESPELL                     0x00000020            // 5 trade spells, will be added by client to a sublist of profession spell
#define SPELL_ATTR_PASSIVE                        0x00000040            // 6 Passive spell
#define SPELL_ATTR_UNK7                           0x00000080            // 7 visible?
#define SPELL_ATTR_UNK8                           0x00000100            // 8
#define SPELL_ATTR_UNK9                           0x00000200            // 9
#define SPELL_ATTR_UNK10                          0x00000400            // 10 on next swing 2
#define SPELL_ATTR_UNK11                          0x00000800            // 11
#define SPELL_ATTR_DAYTIME_ONLY                   0x00001000            // 12 only useable at daytime, not set in 2.4.2
#define SPELL_ATTR_NIGHT_ONLY                     0x00002000            // 13 only useable at night, not set in 2.4.2
#define SPELL_ATTR_INDOORS_ONLY                   0x00004000            // 14 only useable indoors, not set in 2.4.2
#define SPELL_ATTR_OUTDOORS_ONLY                  0x00008000            // 15 Only useable outdoors.
#define SPELL_ATTR_NOT_SHAPESHIFT                 0x00010000            // 16 Not while shapeshifted
#define SPELL_ATTR_ONLY_STEALTHED                 0x00020000            // 17 Must be in stealth
#define SPELL_ATTR_UNK18                          0x00040000            // 18
#define SPELL_ATTR_LEVEL_DAMAGE_CALCULATION       0x00080000            // 19 spelldamage depends on caster level
#define SPELL_ATTR_STOP_ATTACK_TARGET             0x00100000            // 20 Stop attack after use this spell (and not begin attack if use)
#define SPELL_ATTR_IMPOSSIBLE_DODGE_PARRY_BLOCK   0x00200000            // 21 Cannot be dodged/parried/blocked
#define SPELL_ATTR_UNK22                          0x00400000            // 22 shoot spells
#define SPELL_ATTR_CASTABLE_WHILE_DEAD            0x00800000            // 23 castable while dead?
#define SPELL_ATTR_CASTABLE_WHILE_MOUNTED         0x01000000            // 24 castable while mounted
#define SPELL_ATTR_DISABLED_WHILE_ACTIVE          0x02000000            // 25 Activate and start cooldown after aura fade or remove summoned creature or go
#define SPELL_ATTR_NEGATIVE_1                     0x04000000            // 26 Many negative spells have this attr
#define SPELL_ATTR_CASTABLE_WHILE_SITTING         0x08000000            // 27 castable while sitting
#define SPELL_ATTR_CANT_USED_IN_COMBAT            0x10000000            // 28 Cannot be used in combat
#define SPELL_ATTR_UNAFFECTED_BY_INVULNERABILITY  0x20000000            // 29 unaffected by invulnerability (hmm possible not...)
#define SPELL_ATTR_BREAKABLE_BY_DAMAGE            0x40000000            // 30
#define SPELL_ATTR_CANT_CANCEL                    0x80000000            // 31 positive aura can't be canceled

#define SPELL_ATTR_EX_DISMISS_PET                 0x00000001            // 0 dismiss pet and not allow to summon new one?
#define SPELL_ATTR_EX_DRAIN_ALL_POWER             0x00000002            // 1 use all power (Only paladin Lay of Hands and Bunyanize)
#define SPELL_ATTR_EX_CHANNELED_1                 0x00000004            // 2 channeled target
#define SPELL_ATTR_EX_PUT_CASTER_IN_COMBAT        0x00000008            // 3 spells that cause a caster to enter a combat
#define SPELL_ATTR_EX_UNK4                        0x00000010            // 4 stealth and whirlwind
#define SPELL_ATTR_EX_NOT_BREAK_STEALTH           0x00000020            // 5 Not break stealth
#define SPELL_ATTR_EX_CHANNELED_2                 0x00000040            // 6 channeled self
#define SPELL_ATTR_EX_NEGATIVE                    0x00000080            // 7
#define SPELL_ATTR_EX_NOT_IN_COMBAT_TARGET        0x00000100            // 8 Spell req target not to be in combat state
#define SPELL_ATTR_EX_UNK9                        0x00000200            // 9 melee spells
#define SPELL_ATTR_EX_UNK10                       0x00000400            // 10 no generates threat on cast 100%? (old NO_INITIAL_AGGRO)
#define SPELL_ATTR_EX_UNK11                       0x00000800            // 11 aura
#define SPELL_ATTR_EX_UNK12                       0x00001000            // 12
#define SPELL_ATTR_EX_UNK13                       0x00002000            // 13
#define SPELL_ATTR_EX_STACK_FOR_DIFF_CASTERS      0x00004000            // 14
#define SPELL_ATTR_EX_DISPEL_AURAS_ON_IMMUNITY    0x00008000            // 15 remove auras on immunity
#define SPELL_ATTR_EX_UNAFFECTED_BY_SCHOOL_IMMUNE 0x00010000            // 16 on immuniy
#define SPELL_ATTR_EX_UNAUTOCASTABLE_BY_PET       0x00020000            // 17
#define SPELL_ATTR_EX_UNK18                       0x00040000            // 18
#define SPELL_ATTR_EX_CANT_TARGET_SELF            0x00080000            // 19 Applies only to unit target - for example Divine Intervention (19752)
#define SPELL_ATTR_EX_REQ_COMBO_POINTS1           0x00100000            // 20 Req combo points on target
#define SPELL_ATTR_EX_UNK21                       0x00200000            // 21
#define SPELL_ATTR_EX_REQ_COMBO_POINTS2           0x00400000            // 22 Req combo points on target
#define SPELL_ATTR_EX_UNK23                       0x00800000            // 23
#define SPELL_ATTR_EX_UNK24                       0x01000000            // 24 Req fishing pole??
#define SPELL_ATTR_EX_UNK25                       0x02000000            // 25
#define SPELL_ATTR_EX_UNK26                       0x04000000            // 26 works correctly with [target=focus] and [target=mouseover] macros?
#define SPELL_ATTR_EX_UNK27                       0x08000000            // 27
#define SPELL_ATTR_EX_IGNORE_IMMUNITY             0x10000000            // 28 removed from Chains of Ice 3.3.0
#define SPELL_ATTR_EX_UNK29                       0x20000000            // 29
#define SPELL_ATTR_EX_ENABLE_AT_DODGE             0x40000000            // 30 Overpower, Wolverine Bite
#define SPELL_ATTR_EX_UNK31                       0x80000000            // 31

#define SPELL_ATTR_EX2_UNK0                       0x00000001            // 0
#define SPELL_ATTR_EX2_UNK1                       0x00000002            // 1 ? many triggered spells have this flag
#define SPELL_ATTR_EX2_CANT_REFLECTED             0x00000004            // 2 ? used for detect can or not spell reflected
#define SPELL_ATTR_EX2_UNK3                       0x00000008            // 3
#define SPELL_ATTR_EX2_UNK4                       0x00000010            // 4
#define SPELL_ATTR_EX2_AUTOREPEAT_FLAG            0x00000020            // 5
#define SPELL_ATTR_EX2_UNK6                       0x00000040            // 6
#define SPELL_ATTR_EX2_UNK7                       0x00000080            // 7
#define SPELL_ATTR_EX2_UNK8                       0x00000100            // 8 not set in 3.0.3
#define SPELL_ATTR_EX2_UNK9                       0x00000200            // 9
#define SPELL_ATTR_EX2_UNK10                      0x00000400            // 10
#define SPELL_ATTR_EX2_HEALTH_FUNNEL              0x00000800            // 11
#define SPELL_ATTR_EX2_UNK12                      0x00001000            // 12
#define SPELL_ATTR_EX2_UNK13                      0x00002000            // 13 Items enchanted by spells with this flag preserve the enchant to arenas
#define SPELL_ATTR_EX2_UNK14                      0x00004000            // 14
#define SPELL_ATTR_EX2_UNK15                      0x00008000            // 15 not set in 3.0.3
#define SPELL_ATTR_EX2_TAME_BEAST                 0x00010000            // 16
#define SPELL_ATTR_EX2_NOT_RESET_AUTOSHOT         0x00020000            // 17 Hunters Shot and Stings only have this flag
#define SPELL_ATTR_EX2_UNK18                      0x00040000            // 18 Only Revive pet - possible req dead pet
#define SPELL_ATTR_EX2_NOT_NEED_SHAPESHIFT        0x00080000            // 19 does not necessarly need shapeshift
#define SPELL_ATTR_EX2_UNK20                      0x00100000            // 20
#define SPELL_ATTR_EX2_DAMAGE_REDUCED_SHIELD      0x00200000            // 21 for ice blocks, pala immunity buffs, priest absorb shields, but used also for other spells -> not sure!
#define SPELL_ATTR_EX2_UNK22                      0x00400000            // 22
#define SPELL_ATTR_EX2_UNK23                      0x00800000            // 23 Only mage Arcane Concentration have this flag
#define SPELL_ATTR_EX2_UNK24                      0x01000000            // 24
#define SPELL_ATTR_EX2_UNK25                      0x02000000            // 25
#define SPELL_ATTR_EX2_UNK26                      0x04000000            // 26 unaffected by school immunity
#define SPELL_ATTR_EX2_UNK27                      0x08000000            // 27
#define SPELL_ATTR_EX2_UNK28                      0x10000000            // 28 no breaks stealth if it fails??
#define SPELL_ATTR_EX2_CANT_CRIT                  0x20000000            // 29 Spell can't crit
#define SPELL_ATTR_EX2_TRIGGERED_CAN_TRIGGER      0x40000000            // 30 spell can trigger even if triggered
#define SPELL_ATTR_EX2_FOOD_BUFF                  0x80000000            // 31 Food or Drink Buff (like Well Fed)

#define SPELL_ATTR_EX3_UNK0                       0x00000001            // 0
#define SPELL_ATTR_EX3_UNK1                       0x00000002            // 1
#define SPELL_ATTR_EX3_UNK2                       0x00000004            // 2
#define SPELL_ATTR_EX3_BLOCKABLE_SPELL            0x00000008            // 3 Only dmg class melee in 3.1.3
#define SPELL_ATTR_EX3_UNK4                       0x00000010            // 4 Druid Rebirth only this spell have this flag
#define SPELL_ATTR_EX3_UNK5                       0x00000020            // 5
#define SPELL_ATTR_EX3_UNK6                       0x00000040            // 6
#define SPELL_ATTR_EX3_STACK_FOR_DIFF_CASTERS     0x00000080            // 7 separate stack for every caster
#define SPELL_ATTR_EX3_PLAYERS_ONLY               0x00000100            // 8 Player only?
#define SPELL_ATTR_EX3_TRIGGERED_CAN_TRIGGER_2    0x00000200            // 9 triggered from effect?
#define SPELL_ATTR_EX3_MAIN_HAND                  0x00000400            // 10 Main hand weapon required
#define SPELL_ATTR_EX3_BATTLEGROUND               0x00000800            // 11 Can casted only on battleground
#define SPELL_ATTR_EX3_UNK12                      0x00001000            // 12
#define SPELL_ATTR_EX3_UNK13                      0x00002000            // 13
#define SPELL_ATTR_EX3_UNK14                      0x00004000            // 14 "Honorless Target" only this spells have this flag
#define SPELL_ATTR_EX3_UNK15                      0x00008000            // 15 Auto Shoot, Shoot, Throw,  - this is autoshot flag
#define SPELL_ATTR_EX3_UNK16                      0x00010000            // 16 no triggers effects that trigger on casting a spell?? (15290 - 2.2ptr change)
#define SPELL_ATTR_EX3_NO_INITIAL_AGGRO           0x00020000            // 17 Soothe Animal, 39758, Mind Soothe
#define SPELL_ATTR_EX3_UNK18                      0x00040000            // 18 added to Explosive Trap Effect 3.3.0, removed from Mutilate 3.3.0
#define SPELL_ATTR_EX3_DISABLE_PROC               0x00080000            // 19 during aura proc no spells can trigger (20178, 20375)
#define SPELL_ATTR_EX3_DEATH_PERSISTENT           0x00100000            // 20 Death persistent spells
#define SPELL_ATTR_EX3_UNK21                      0x00200000            // 21
#define SPELL_ATTR_EX3_REQ_WAND                   0x00400000            // 22 Req wand
#define SPELL_ATTR_EX3_UNK23                      0x00800000            // 23
#define SPELL_ATTR_EX3_REQ_OFFHAND                0x01000000            // 24 Req offhand weapon
#define SPELL_ATTR_EX3_UNK25                      0x02000000            // 25 no cause spell pushback ?
#define SPELL_ATTR_EX3_CAN_PROC_TRIGGERED         0x04000000            // 26
#define SPELL_ATTR_EX3_DRAIN_SOUL                 0x08000000            // 27 only drain soul has this flag
#define SPELL_ATTR_EX3_UNK28                      0x10000000            // 28
#define SPELL_ATTR_EX3_NO_DONE_BONUS              0x20000000            // 29 Ignore caster spellpower and done damage mods?
#define SPELL_ATTR_EX3_UNK30                      0x40000000            // 30 Shaman's Fire Nova 3.3.0, Sweeping Strikes 3.3.0
#define SPELL_ATTR_EX3_UNK31                      0x80000000            // 31

#define SPELL_ATTR_EX4_UNK0                       0x00000001            // 0
#define SPELL_ATTR_EX4_UNK1                       0x00000002            // 1 proc on finishing move?
#define SPELL_ATTR_EX4_UNK2                       0x00000004            // 2
#define SPELL_ATTR_EX4_CANT_PROC_FROM_SELFCAST    0x00000008            // 3
#define SPELL_ATTR_EX4_UNK4                       0x00000010            // 4 This will no longer cause guards to attack on use??
#define SPELL_ATTR_EX4_UNK5                       0x00000020            // 5
#define SPELL_ATTR_EX4_NOT_STEALABLE              0x00000040            // 6 although such auras might be dispellable, they cannot be stolen
#define SPELL_ATTR_EX4_UNK7                       0x00000080            // 7
#define SPELL_ATTR_EX4_FIXED_DAMAGE               0x00000100            // 8 decimate, share damage?
#define SPELL_ATTR_EX4_UNK9                       0x00000200            // 9
#define SPELL_ATTR_EX4_SPELL_VS_EXTEND_COST       0x00000400            // 10 Rogue Shiv have this flag
#define SPELL_ATTR_EX4_UNK11                      0x00000800            // 11
#define SPELL_ATTR_EX4_UNK12                      0x00001000            // 12
#define SPELL_ATTR_EX4_UNK13                      0x00002000            // 13
#define SPELL_ATTR_EX4_UNK14                      0x00004000            // 14
#define SPELL_ATTR_EX4_UNK15                      0x00008000            // 15
#define SPELL_ATTR_EX4_NOT_USABLE_IN_ARENA        0x00010000            // 16 not usable in arena
#define SPELL_ATTR_EX4_USABLE_IN_ARENA            0x00020000            // 17 usable in arena
#define SPELL_ATTR_EX4_UNK18                      0x00040000            // 18
#define SPELL_ATTR_EX4_UNK19                      0x00080000            // 19
#define SPELL_ATTR_EX4_NOT_CHECK_SELFCAST_POWER   0x00100000            // 20 supersedes message "More powerful spell applied" for self casts.
#define SPELL_ATTR_EX4_UNK21                      0x00200000            // 21
#define SPELL_ATTR_EX4_UNK22                      0x00400000            // 22
#define SPELL_ATTR_EX4_UNK23                      0x00800000            // 23
#define SPELL_ATTR_EX4_UNK24                      0x01000000            // 24
#define SPELL_ATTR_EX4_UNK25                      0x02000000            // 25 pet scaling auras
#define SPELL_ATTR_EX4_CAST_ONLY_IN_OUTLAND       0x04000000            // 26 Can only be used in Outland.
#define SPELL_ATTR_EX4_UNK27                      0x08000000            // 27
#define SPELL_ATTR_EX4_UNK28                      0x10000000            // 28
#define SPELL_ATTR_EX4_UNK29                      0x20000000            // 29
#define SPELL_ATTR_EX4_UNK30                      0x40000000            // 30
#define SPELL_ATTR_EX4_UNK31                      0x80000000            // 31

#define SPELL_ATTR_EX5_UNK0                       0x00000001            // 0
#define SPELL_ATTR_EX5_NO_REAGENT_WHILE_PREP      0x00000002            // 1 not need reagents if UNIT_FLAG_PREPARATION
#define SPELL_ATTR_EX5_UNK2                       0x00000004            // 2
#define SPELL_ATTR_EX5_USABLE_WHILE_STUNNED       0x00000008            // 3 usable while stunned
#define SPELL_ATTR_EX5_UNK4                       0x00000010            // 4
#define SPELL_ATTR_EX5_SINGLE_TARGET_SPELL        0x00000020            // 5 Only one target can be apply at a time
#define SPELL_ATTR_EX5_UNK6                       0x00000040            // 6
#define SPELL_ATTR_EX5_UNK7                       0x00000080            // 7
#define SPELL_ATTR_EX5_UNK8                       0x00000100            // 8
#define SPELL_ATTR_EX5_START_PERIODIC_AT_APPLY    0x00000200            // 9  begin periodic tick at aura apply
#define SPELL_ATTR_EX5_UNK10                      0x00000400            // 10
#define SPELL_ATTR_EX5_UNK11                      0x00000800            // 11
#define SPELL_ATTR_EX5_UNK12                      0x00001000            // 12
#define SPELL_ATTR_EX5_UNK13                      0x00002000            // 13
#define SPELL_ATTR_EX5_UNK14                      0x00004000            // 14
#define SPELL_ATTR_EX5_UNK15                      0x00008000            // 15
#define SPELL_ATTR_EX5_UNK16                      0x00010000            // 16
#define SPELL_ATTR_EX5_USABLE_WHILE_FEARED        0x00020000            // 17 usable while feared
#define SPELL_ATTR_EX5_USABLE_WHILE_CONFUSED      0x00040000            // 18 usable while confused
#define SPELL_ATTR_EX5_UNK19                      0x00080000            // 19
#define SPELL_ATTR_EX5_UNK20                      0x00100000            // 20
#define SPELL_ATTR_EX5_UNK21                      0x00200000            // 21
#define SPELL_ATTR_EX5_UNK22                      0x00400000            // 22
#define SPELL_ATTR_EX5_UNK23                      0x00800000            // 23
#define SPELL_ATTR_EX5_UNK24                      0x01000000            // 24
#define SPELL_ATTR_EX5_UNK25                      0x02000000            // 25
#define SPELL_ATTR_EX5_UNK26                      0x04000000            // 26
#define SPELL_ATTR_EX5_UNK27                      0x08000000            // 27
#define SPELL_ATTR_EX5_UNK28                      0x10000000            // 28
#define SPELL_ATTR_EX5_UNK29                      0x20000000            // 29
#define SPELL_ATTR_EX5_UNK30                      0x40000000            // 30
#define SPELL_ATTR_EX5_UNK31                      0x80000000            // 31 Forces all nearby enemies to focus attacks caster

#define SPELL_ATTR_EX6_UNK0                       0x00000001            // 0 Only Move spell have this flag
#define SPELL_ATTR_EX6_ONLY_IN_ARENA              0x00000002            // 1 only usable in arena
#define SPELL_ATTR_EX6_IGNORE_CASTER_AURAS        0x00000004            // 2
#define SPELL_ATTR_EX6_UNK3                       0x00000008            // 3
#define SPELL_ATTR_EX6_UNK4                       0x00000010            // 4
#define SPELL_ATTR_EX6_UNK5                       0x00000020            // 5
#define SPELL_ATTR_EX6_UNK6                       0x00000040            // 6
#define SPELL_ATTR_EX6_UNK7                       0x00000080            // 7
#define SPELL_ATTR_EX6_UNK8                       0x00000100            // 8
#define SPELL_ATTR_EX6_UNK9                       0x00000200            // 9
#define SPELL_ATTR_EX6_UNK10                      0x00000400            // 10
#define SPELL_ATTR_EX6_NOT_IN_RAID_INSTANCE       0x00000800            // 11 not usable in raid instance
#define SPELL_ATTR_EX6_UNK12                      0x00001000            // 12
#define SPELL_ATTR_EX6_UNK13                      0x00002000            // 13
#define SPELL_ATTR_EX6_UNK14                      0x00004000            // 14
#define SPELL_ATTR_EX6_UNK15                      0x00008000            // 15 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK16                      0x00010000            // 16
#define SPELL_ATTR_EX6_UNK17                      0x00020000            // 17
#define SPELL_ATTR_EX6_UNK18                      0x00040000            // 18
#define SPELL_ATTR_EX6_UNK19                      0x00080000            // 19
#define SPELL_ATTR_EX6_UNK20                      0x00100000            // 20
#define SPELL_ATTR_EX6_CLIENT_UI_TARGET_EFFECTS   0x00200000            // 21 it's only client-side attribute
#define SPELL_ATTR_EX6_UNK22                      0x00400000            // 22
#define SPELL_ATTR_EX6_UNK23                      0x00800000            // 23 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK24                      0x01000000            // 24 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK25                      0x02000000            // 25 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK26                      0x04000000            // 26 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK27                      0x08000000            // 27 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK28                      0x10000000            // 28 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK29                      0x20000000            // 29 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK30                      0x40000000            // 30 not set in 3.0.3
#define SPELL_ATTR_EX6_UNK31                      0x80000000            // 31 not set in 3.0.3

#define SPELL_ATTR_EX7_UNK0                       0x00000001            // 0  Shaman's new spells (Call of the ...), Feign Death.
#define SPELL_ATTR_EX7_UNK1                       0x00000002            // 1  Not set in 3.2.2a.
#define SPELL_ATTR_EX7_REACTIVATE_AT_RESURRECT    0x00000004            // 2  Paladin's auras and 65607 only.
#define SPELL_ATTR_EX7_UNK3                       0x00000008            // 3  Only 43574 test spell.
#define SPELL_ATTR_EX7_UNK4                       0x00000010            // 4  Only 66109 test spell.
#define SPELL_ATTR_EX7_SUMMON_PLAYER_TOTEM        0x00000020            // 5  Only Shaman player totems.
#define SPELL_ATTR_EX7_UNK6                       0x00000040            // 6  Dark Surge, Surge of Light, Burning Breath triggers (boss spells).
#define SPELL_ATTR_EX7_UNK7                       0x00000080            // 7  66218 (Launch) spell.
#define SPELL_ATTR_EX7_UNK8                       0x00000100            // 8  Teleports, mounts and other spells.
#define SPELL_ATTR_EX7_UNK9                       0x00000200            // 9  Teleports, mounts and other spells.
#define SPELL_ATTR_EX7_DISPEL_CHARGES             0x00000400            // 10 Dispel and Spellsteal individual charges instead of whole aura.
#define SPELL_ATTR_EX7_INTERRUPT_ONLY_NONPLAYER   0x00000800            // 11 Only non-player casts interrupt, though Feral Charge - Bear has it.
#define SPELL_ATTR_EX7_UNK12                      0x00001000            // 12 Not set in 3.2.2a.
#define SPELL_ATTR_EX7_UNK13                      0x00002000            // 13 Not set in 3.2.2a.
#define SPELL_ATTR_EX7_UNK14                      0x00004000            // 14 Only 52150 (Raise Dead - Pet) spell.
#define SPELL_ATTR_EX7_UNK15                      0x00008000            // 15 Exorcism. Usable on players? 100% crit chance on undead and demons?
#define SPELL_ATTR_EX7_UNK16                      0x00010000            // 16 Druid spells (29166, 54833, 64372, 68285).
#define SPELL_ATTR_EX7_UNK17                      0x00020000            // 17 Only 27965 (Suicide) spell.
#define SPELL_ATTR_EX7_HAS_CHARGE_EFFECT          0x00040000            // 18 Only spells that have Charge among effects.
#define SPELL_ATTR_EX7_ZONE_TELEPORT              0x00080000            // 19 Teleports to specific zones.

// Spell aura states
enum AuraState
{   // (C) used in caster aura state     (T) used in target aura state
    // (c) used in caster aura state-not (t) used in target aura state-not
    AURA_STATE_NONE                         = 0,            // C   |
    AURA_STATE_DEFENSE                      = 1,            // C   |
    AURA_STATE_HEALTHLESS_20_PERCENT        = 2,            // CcT |
    AURA_STATE_BERSERKING                   = 3,            // C T |
    AURA_STATE_FROZEN                       = 4,            //  c t| frozen target
    AURA_STATE_JUDGEMENT                    = 5,            // C   |
    //AURA_STATE_UNKNOWN6                   = 6,            //     | not used
    AURA_STATE_HUNTER_PARRY                 = 7,            // C   |
    //AURA_STATE_UNKNOWN7                   = 7,            //  c  | creature cheap shot / focused bursts spells
    //AURA_STATE_UNKNOWN8                   = 8,            //    t| test spells
    //AURA_STATE_UNKNOWN9                   = 9,            //     |
    AURA_STATE_WARRIOR_VICTORY_RUSH         = 10,           // C   | warrior victory rush
    //AURA_STATE_UNKNOWN11                  = 11,           // C  t| 60348 - Maelstrom Ready!, test spells
    AURA_STATE_FAERIE_FIRE                  = 12,           //  c t|
    AURA_STATE_HEALTHLESS_35_PERCENT        = 13,           // C T |
    AURA_STATE_CONFLAGRATE                  = 14,           //   T |
    AURA_STATE_SWIFTMEND                    = 15,           //   T |
    AURA_STATE_DEADLY_POISON                = 16,           //   T |
    AURA_STATE_ENRAGE                       = 17,           // C   |
    AURA_STATE_BLEEDING                     = 18,           //    T|
    //AURA_STATE_UNKNOWN19                  = 19,           //     | not used
    //AURA_STATE_UNKNOWN20                  = 20,           //  c  | only (45317 Suicide)
    //AURA_STATE_UNKNOWN21                  = 21,           //     | not used
    //AURA_STATE_UNKNOWN22                  = 22,           // C  t| varius spells (63884, 50240)
    AURA_STATE_HEALTH_ABOVE_75_PERCENT      = 23,           // C   |
};

// Spell mechanics
enum Mechanics
{
    MECHANIC_NONE             = 0,
    MECHANIC_CHARM            = 1,
    MECHANIC_DISORIENTED      = 2,
    MECHANIC_DISARM           = 3,
    MECHANIC_DISTRACT         = 4,
    MECHANIC_FEAR             = 5,
    MECHANIC_GRIP             = 6,
    MECHANIC_ROOT             = 7,
    MECHANIC_PACIFY           = 8,                          //0 spells use this mechanic
    MECHANIC_SILENCE          = 9,
    MECHANIC_SLEEP            = 10,
    MECHANIC_SNARE            = 11,
    MECHANIC_STUN             = 12,
    MECHANIC_FREEZE           = 13,
    MECHANIC_KNOCKOUT         = 14,
    MECHANIC_BLEED            = 15,
    MECHANIC_BANDAGE          = 16,
    MECHANIC_POLYMORPH        = 17,
    MECHANIC_BANISH           = 18,
    MECHANIC_SHIELD           = 19,
    MECHANIC_SHACKLE          = 20,
    MECHANIC_MOUNT            = 21,
    MECHANIC_INFECTED         = 22,
    MECHANIC_TURN             = 23,
    MECHANIC_HORROR           = 24,
    MECHANIC_INVULNERABILITY  = 25,
    MECHANIC_INTERRUPT        = 26,
    MECHANIC_DAZE             = 27,
    MECHANIC_DISCOVERY        = 28,
    MECHANIC_IMMUNE_SHIELD    = 29,                         // Divine (Blessing) Shield/Protection and Ice Block
    MECHANIC_SAPPED           = 30,
    MECHANIC_ENRAGED          = 31
};

// Spell dispell type
enum DispelType
{
    DISPEL_NONE         = 0,
    DISPEL_MAGIC        = 1,
    DISPEL_CURSE        = 2,
    DISPEL_DISEASE      = 3,
    DISPEL_POISON       = 4,
    DISPEL_STEALTH      = 5,
    DISPEL_INVISIBILITY = 6,
    DISPEL_ALL          = 7,
    DISPEL_SPE_NPC_ONLY = 8,
    DISPEL_ENRAGE       = 9,
    DISPEL_ZG_TICKET    = 10,
    DESPEL_OLD_UNUSED   = 11
};

//To all Immune system,if target has immunes,
//some spell that related to ImmuneToDispel or ImmuneToSchool or ImmuneToDamage type can't cast to it,
//some spell_effects that related to ImmuneToEffect<effect>(only this effect in the spell) can't cast to it,
//some aura(related to Mechanics or ImmuneToState<aura>) can't apply to it.
enum SpellImmunity
{
    IMMUNITY_EFFECT                = 0,                     // enum SpellEffects
    IMMUNITY_STATE                 = 1,                     // enum AuraType
    IMMUNITY_SCHOOL                = 2,                     // enum SpellSchoolMask
    IMMUNITY_DAMAGE                = 3,                     // enum SpellSchoolMask
    IMMUNITY_DISPEL                = 4,                     // enum DispelType
    IMMUNITY_MECHANIC              = 5,                     // enum Mechanics
    IMMUNITY_ID                    = 6
};

enum TotemCategory
{
    TC_SKINNING_SKIFE_OLD          = 1,
    TC_EARTH_TOTEM                 = 2,
    TC_AIR_TOTEM                   = 3,
    TC_FIRE_TOTEM                  = 4,
    TC_WATER_TOTEM                 = 5,
    TC_COPPER_ROD                  = 6,
    TC_SILVER_ROD                  = 7,
    TC_GOLDEN_ROD                  = 8,
    TC_TRUESILVER_ROD              = 9,
    TC_ARCANITE_ROD                = 10,
    TC_MINING_PICK_OLD             = 11,
    TC_PHILOSOPHERS_STONE          = 12,
    TC_BLACKSMITH_HAMMER_OLD       = 13,
    TC_ARCLIGHT_SPANNER            = 14,
    TC_GYROMATIC_MA                = 15,
    TC_MASTER_TOTEM                = 21,
    TC_FEL_IRON_ROD                = 41,
    TC_ADAMANTITE_ROD              = 62,
    TC_ETERNIUM_ROD                = 63,
    TC_HOLLOW_QUILL                = 81,
    TC_RUNED_AZURITE_ROD           = 101,
    TC_VIRTUOSO_INKING_SET         = 121,
    TC_DRUMS                       = 141,
    TC_GNOMISH_ARMY_KNIFE          = 161,
    TC_BLACKSMITH_HAMMER           = 162,
    TC_MINING_PICK                 = 165,
    TC_SKINNING_KNIFE              = 166,
    TC_HAMMER_PICK                 = 167,
    TC_BLADED_PICKAXE              = 168,
    TC_FLINT_AND_TINDER            = 169,
    TC_RUNED_COBALT_ROD            = 189,
    TC_RUNED_TITANIUM_ROD          = 190
};

enum SpellFamilyNames
{
    SPELLFAMILY_GENERIC     = 0,
    SPELLFAMILY_UNK1        = 1,                            // events, holidays
    // 2 - unused
    SPELLFAMILY_MAGE        = 3,
    SPELLFAMILY_WARRIOR     = 4,
    SPELLFAMILY_WARLOCK     = 5,
    SPELLFAMILY_PRIEST      = 6,
    SPELLFAMILY_DRUID       = 7,
    SPELLFAMILY_ROGUE       = 8,
    SPELLFAMILY_HUNTER      = 9,
    SPELLFAMILY_PALADIN     = 10,
    SPELLFAMILY_SHAMAN      = 11,
    SPELLFAMILY_UNK2        = 12,                           // 2 spells (silence resistance)
    SPELLFAMILY_POTION      = 13,
    // 14 - unused
    SPELLFAMILY_DEATHKNIGHT = 15,
    // 16 - unused
    SPELLFAMILY_PET         = 17
};

