//
//  QuestItem.h
//  Pocket Gnome
//
//  Created by Josh on 4/23/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QuestItem : NSObject {
	NSNumber *_item;
	NSNumber *_quantity;
}

@property (readwrite, retain) NSNumber *item;
@property (readwrite, retain) NSNumber *quantity;

@end
