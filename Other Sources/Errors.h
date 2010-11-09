/*
 *  Errors.h
 *  Pocket Gnome
 *
 *  Created by Josh on 6/9/09.
 *  Copyright 2007 Savory Software, LLC. All rights reserved.
 *
 */

// Return types for performAction
//	More errors here: http://www.wowwiki.com/WoW_Constants/Errors
typedef enum CastError {
    ErrNone = 0,
	ErrNotFound = 1,
	ErrInventoryFull = 2,				// @"Inventory is Full"
	ErrTargetNotInLOS = 3,
	ErrCantMove = 4,
	ErrTargetNotInFrnt = 5,	
	ErrWrng_Way = 6,
	ErrSpell_Cooldown  = 7,
	ErrAttack_Stunned  = 8,
	ErrSpellNot_Ready  = 9,
	ErrTargetOutRange  = 10,
	ErrYouAreTooFarAway  = 11,
	//ErrSpellNot_Ready2  = 12,
	ErrSpellNotReady = 13,
	ErrInvalidTarget = 14,
	ErrTargetDead = 15,
	ErrCantAttackMounted = 16,
	ErrYouAreMounted = 17,
	ErrMorePowerfullSpellActive = 18,
	ErrHaveNoTarget = 19,
	ErrCantDoThatWhileStunned = 20,
	ErrCantDoThatWhileSilenced = 21,
	ErrCantDoThatWhileIncapacitated= 22,

} CastError;

#define INV_FULL			@"Inventory is full."
#define TARGET_LOS			@"Target not in line of sight"
#define SPELL_NOT_READY		@"Spell is not ready yet."
#define CANT_MOVE			@"Can't do that while moving"
#define TARGET_FRNT			@"Target needs to be in front of you."
#define WRNG_WAY			@"You are facing the wrong way!"
#define NOT_YET			    @"You can't do that yet"
#define SPELL_NOT_READY2    @"Spell is not ready yet."
#define NOT_RDY2			@"Ability is not ready yet."
#define ATTACK_STUNNED	    @"Can't attack while stunned."
#define TARGET_RNGE			@"Out of range."
#define TARGET_RNGE2		@"You are too far away!"
#define INVALID_TARGET		@"Invalid target"
#define TARGET_DEAD			@"Your target is dead"
#define CANT_ATTACK_MOUNTED	@"Can't attack while mounted."
#define YOU_ARE_MOUNTED		@"You are mounted."
#define CANT_ATTACK_TARGET	@"You cannot attack that target."
#define HAVE_NO_TARGET		@"You have no target."
#define MORE_POWERFUL_SPELL_ACTIVE	@"A more powerful spell is already active"
#define CANT_DO_THAT_WHILE_STUNNED 	@"Can't do that while stunned"
#define CANT_DO_THAT_WHILE_SILENCED 	@"Can't do that while silenced"
#define CANT_DO_THAT_WHILE_INCAPACITATED 	@"Can't do that while incapacitated"

//Must have a Fishing Pole equipped
//Not enough mana
//Not enough energy
