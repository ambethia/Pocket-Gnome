//
//  Quest.h
//  Pocket Gnome
//
//  Created by Josh on 4/23/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MaxQuestID 1000000

@interface Quest : NSObject {
    NSNumber *_questID;
    NSString *_name;
	
	NSMutableArray *_itemRequirements;		// List of items that are needed to complete the quest
	
	NSNumber *_startNPC;
	NSNumber *_endNPC;
	
	NSNumber *_level;
	NSNumber *_requiredLevel;
	
	NSURLConnection *_connection;
    NSMutableData *_downloadData;
}

+ (Quest*)questWithID: (NSNumber*)questID;
- (id)initWithQuestID: (NSNumber*)questID;

@property (readwrite, retain) NSNumber *questID;
@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSNumber *level;
@property (readwrite, retain) NSNumber *requiredLevel;
@property (readwrite, retain) NSNumber *startNPC;
@property (readwrite, retain) NSNumber *endNPC;
@property (readwrite, retain) NSMutableArray *itemRequirements;

- (int)requiredItemTotal;

- (void)reloadQuestData;

@end
