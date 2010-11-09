//
//  QuestController.m
//  Pocket Gnome
//
//  Created by Josh on 4/22/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "QuestController.h"
#import "Controller.h"
#import "MemoryAccess.h"
#import "PlayerDataController.h"
#import "Player.h"
#import "Quest.h"
#import "QuestItem.h"

// 3.1.1 valid
// #define QUEST_START_STATIC			((IS_X86) ? 0x14125F0 : 0x0)

// Using QUEST_START_STATIC
/* This quest list is a bit confusing... here is an example:
 0x0		7905			<-- quest id
 0x4		12				<-- unknown  (this seems to be a counter... starts at 1 and goes up to the total number of quests)
 0x8		0				<-- unknown
 0xC		0				<-- unknown
 0x10	38				<-- Zone ID
 0x14	0
 0x18	1
 0x1C	0
 0x20	256				<-- quest id
 0x24	9
 0x28	0
 0x2C	0
 0x30	44				<-- Zone ID
 0x34	0
 0x38	1
 0x3C	0
 0x40	125				<-- quest id
 0x44	3
 0x48	0
 0x4C	0
 0x50	145				<-- quest id
 0x54	7
 0x58	0
 0x5C	0
 */

@implementation QuestController

- (id) init {
    self = [super init];
    if (self != nil) {
		_playerQuests = [[NSMutableArray array] retain];
    }
    return self;
}

- (void) dealloc
{
    [_playerQuests release];
    [super dealloc];
}


- (NSArray*)playerQuests {
    return [[_playerQuests retain] autorelease];
}


typedef struct QuestInfo {
    UInt32  questID;
    UInt32  bytes;
    UInt32  bytes1;
    UInt32  bytes2;
} QuestInfo;

- (void) reloadPlayerQuests{
	
	// Get access to memory
	/*MemoryAccess *wowMemory = [controller wowMemoryAccess];
	UInt32 playerAddress = [playerDataController baselineAddress];
	
	// Add the player's current quests to the array pls
	int i;
	for ( i = 0; i < 25; i++ ){
		QuestInfo quest;
		if([wowMemory loadDataForObject: self atAddress: (playerAddress + PlayerField_QuestStart) + i*sizeof(quest) Buffer:(Byte*)&quest BufLength: sizeof(quest)]) {
			if ( quest.questID > 0 ){
				[_playerQuests addObject: [Quest questWithID: [NSNumber numberWithInt: quest.questID]]];
			}
			else{
				break;
			}
		}
	}*/
	
	// Get the data for each quest from WoWHead
    for(Quest *quest in _playerQuests) {
        [quest reloadQuestData];
    }
	
	/*
	 // No real point in using the below unless you want to find the Title IDs (faction)...  The below bytes simply go from 1 up to the max quest number... (bytes... bytes1 and bytes2 are always 0)
	 if(wowMemory) {
	 // Shouldn't be more than 50 (25 quests + 25 potential headings)
	 for(i = 0; i< 50; i++)
	 {
	 UInt32 questStart = QUEST_START_STATIC;
	 
	 QuestInfo quest;
	 if([wowMemory loadDataForObject: self atAddress: (questStart) + i*sizeof(quest) Buffer:(Byte*)&quest BufLength: sizeof(quest)]) {
	 //log(LOG_GENERAL, @"ID: %d, 1:%d, 2:%d, 3:%d", quest.questID, quest.bytes, quest.bytes1, quest.bytes2);
	 
	 if ( quest.questID == 0 ) continue;
	 
	 // Check to see if this object exists (if it does then it's not a heading)
	 NSEnumerator *enumerator = [_playerQuests objectEnumerator];
	 Quest *obj;
	 
	 while ((obj = [enumerator nextObject]) != nil)
	 {
	 // Found a valid quest ID... lets save the extra data
	 if ( [[obj ID] intValue] == quest.questID )
	 {
	 log(LOG_GENERAL, @"Found quest %d (%d, %d, %D)", quest.questID, quest.bytes, quest.bytes1, quest.bytes2);
	 
	 obj._bytes1 = [NSNumber numberWithInt:quest.bytes];
	 obj._bytes2 = [NSNumber numberWithInt:quest.bytes1];
	 obj._bytes3 = [NSNumber numberWithInt:quest.bytes2];
	 
	 break;
	 } 
	 }
	 }
	 }
	 }*/
	
	/*
	 // For when i don't have the ability to start wow...
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:19]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:91]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:122]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:125]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:126]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:127]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:128]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:145]]];
	 
	 
	 // Get the data for each quest from WoWHead
	 int k;
	 for(k = 0; k < [_playerQuests count]; k++ ){
	 [[_playerQuests objectAtIndex:k] reloadQuestData];
	 }*/
}

- (void) dumpQuests{
	if ( !_playerQuests || ![_playerQuests count] ){
		return;
	}
	
	NSLog(@"Total quests: %i", [_playerQuests count] );
	for(Quest *quest in _playerQuests) {
		
		log(LOG_GENERAL, @"Quest: %@ %@", [quest questID], [quest name]);
		
        for(QuestItem *questItem in quest.itemRequirements){
            log(LOG_GENERAL, @"  Required Item: %@ Quantity: %@", [questItem item], [questItem quantity]);
        }
	}
}

@end
