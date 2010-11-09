//
//  QuestItem.m
//  Pocket Gnome
//
//  Created by Josh on 4/23/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "QuestItem.h"


@implementation QuestItem

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.item = nil;
        self.quantity = nil;
    }
    return self;
}

@synthesize item = _item;
@synthesize quantity = _quantity;

- (void) dealloc {
    self.item = nil;
    self.quantity = nil;
	
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	if(self) {
        self.item = [decoder decodeObjectForKey: @"Item"];
        self.quantity = [decoder decodeObjectForKey: @"Quantity"];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: self.item forKey: @"Item"];
    [coder encodeObject: self.quantity forKey: @"Quantity"];
}

@end
