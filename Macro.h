//
//  Macro.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 6/24/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Macro : NSObject {
    NSString *name, *body;
    NSNumber *number;
    BOOL isCharacter;
}

+ (id)macroWithName: (NSString*)name number: (NSNumber*)number body: (NSString*)body isCharacter: (BOOL)isChar;

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSString *body;
@property (readwrite, retain) NSNumber *number;
@property BOOL isCharacter;

- (NSString*)nameWithType;

@end
