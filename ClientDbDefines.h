
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
 * $Id: ClientDbDefines.h 315 2010-04-14 04:12:45Z Tanaris4 $
 *
 */

typedef struct SpellDbc{
	uint Id;						// 0
	uint Category;						
	uint Dispel;
	uint Mechanic;					// wonder how to know what all these are? but this can be Mounted (0x15 - for swift + non-swift flying)
	uint Attributes;				
	uint AttributesEx;				// 5
	uint AttributesEx2;
	uint AttributesEx3;
	uint AttributesEx4;
	uint AttributesEx5;
	uint AttributesEx6;				// 10
	uint AttributesEx7;
	uint Stances;
	uint unk_320_2;
	uint StancesNot;
	uint unk_320_3;					// 15
	uint Targets;
	uint TargetCreatureType;
	uint RequiresSpellFocus;
	uint FacingCasterFlags;
	uint CasterAuraState;			// 20
	uint TargetAuraState;
	uint CasterAuraStateNot;
	uint TargetAuraStateNot;
	uint casterAuraSpell;
	uint targetAuraSpell;			// 25
	uint excludeCasterAuraSpell;
	uint excludeTargetAuraSpell;
	uint CastingTimeIndex;			// Need to look this up in another table for the exact value, wtf? y blizz y!!!
	uint RecoveryTime;
	uint CategoryRecoveryTime;		// 30 (cooldown, divide it by 1000)
	uint InterruptFlags;
	uint AuraInterruptFlags;
	uint ChannelInterruptFlags;
	uint procFlags;
	uint procChance;				// 35
	uint procCharges;
	uint maxLevel;
	uint baseLevel;
	uint spellLevel;
	uint DurationIndex;				// 40
	uint powerType;
	uint manaCost;
	uint manaCostPerlevel;
	uint manaPerSecond;
	uint manaPerSecondPerLevel;		// 45
	uint rangeIndex;
	float speed;
	uint modalNextSpell;
	uint StackAmount;
	uint Totem[2];							// 50-51
	int Reagent[8];							// 52-59
	uint ReagentCount[8];					// 60-67
	int EquippedItemClass;					// 68
	int EquippedItemSubClassMask;			// 69
	int EquippedItemInventoryTypeMask;		// 70
	uint Effect[3];							// 71-73
	int EffectDieSides[3];					// 74-76
	int EffectBaseDice[3];					// 77-79
	float EffectDicePerLevel[3];			// 80-82
	float EffectRealPointsPerLevel[3];		// 83-85
	int EffectBasePoints[3];				// 86-88
	uint EffectMechanic[3];					// 89-91
	uint EffectImplicitTargetA[3];			// 92-94
	uint EffectImplicitTargetB[3];			// 95-97
	uint EffectRadiusIndex[3];				// 98-100
	uint EffectChainTarget[3];				// 101-103    (swapped this with EffectApplyAuraName @ 110)
	uint EffectAmplitude[3];				// 104-106
	float EffectMultipleValue[3];			// 107-109
	uint EffectApplyAuraName[3];			// 110-112				(at 110 found 18376 for a swift flying mount, 18357 for slow mount, which is the mounted aura - seems like this should be EffectApplyAuraName)
	uint EffectItemType[3];					// 113-115
	int EffectMiscValue[3];					// 116-118
	int EffectMiscValueB[3];				// 119-121
	uint EffectTriggerSpell[3];				// 122-124
	float EffectPointsPerComboPoint[3];		// 125-127
	uint EffectSpellClassMask[3];			// 128-130  Flag96
	uint SpellVisual[2];					// 131-132
	uint SpellIconID;
	uint activeIconID;
	uint spellPriority;				// 135
	uint SpellName;
	uint Rank;
	uint Description;
	uint ToolTip;
	uint ManaCostPercentage;		// 140
	uint StartRecoveryCategory;
	uint StartRecoveryTime;
	uint MaxTargetLevel;
	uint SpellFamilyName;
	uint SpellFamilyFlags[3];		// 145-147 Flag96
	uint MaxAffectedTargets;
	uint DmgClass;
	uint PreventionType;			// 150
	uint StanceBarOrder;
	float DmgMultiplier[3];			// 152-154
	uint MinFactionId;				// 155
	uint MinReputation;
	uint RequiredAuraVision;
	uint TotemCategory[2];			// 158-160
	int AreaGroupId;
	int SchoolMask;
	uint runeCostID;
	uint spellMissileID;
	uint PowerDisplayId;			// 165
	float unk_320_4[3];				// 166-168
	uint spellDescriptionVariableID;
	uint SpellDifficultyId;			// 170
} SpellDbc;