//
//  Procedure.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/4/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Rule.h"

@interface Procedure : NSObject <NSCoding, NSCopying> {
    NSString *_name;
    NSMutableArray *_rules;
}

+ (id)procedureWithName: (NSString*)name;

@property (readwrite, copy) NSString *name;
@property (readonly, retain) NSArray *rules;

- (unsigned)ruleCount;
- (Rule*)ruleAtIndex: (unsigned)index;

- (void)addRule: (Rule*)rule;
- (void)insertRule: (Rule*)rule atIndex: (unsigned)index;
- (void)replaceRuleAtIndex: (int)index withRule: (Rule*)rule;
- (void)removeRule: (Rule*)rule;
- (void)removeRuleAtIndex: (unsigned)index;

@end
