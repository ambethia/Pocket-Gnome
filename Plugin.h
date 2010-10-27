//
//  Plugin.h
//  Pocket Gnome
//
//  Created by Josh on 10/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Plugin : NSObject {
	
	NSString *_path;
}

@property BOOL enabled;


+ (id)pluginWithPath: (NSString*)path;

- (void)load;

@end
