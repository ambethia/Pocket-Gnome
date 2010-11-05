//
//  Plugin.h
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "lua.h"

@interface Plugin : NSObject {
	
	BOOL _enabled;
	NSDictionary *_info;
	NSString *_path;
	
}

@property BOOL enabled;
@property (readonly) NSString *name;
@property (readonly) NSString *desc;
@property (readonly) NSString *version;
@property (readonly) NSString *author;
@property (readonly) NSString *releasedate;
@property (readonly) NSString *path;

+ (id)pluginWithPath: (NSString*)path;

-(BOOL)loadNib:(NSString *)filename;

@end
