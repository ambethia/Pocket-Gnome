//
// LogController.m
// Pocket Gnome
//
// Created by benemorius on 12/17/09.
// Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "LogController.h"


@implementation LogController

+ (BOOL) canLog:(char*)type_s, ...
{
	
	
	return YES;
	
	// Check to see whether or not extended logging is even on
	if ( [[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] ) {

		// Extended logging is on so lets see if we're supposed to log the requested type
		NSString* type = [NSString stringWithFormat:@"ExtendedLogging%s", type_s];
		
		if ([[NSUserDefaults standardUserDefaults] objectForKey: type])
			return( [[[NSUserDefaults standardUserDefaults] objectForKey: type] boolValue] );

		//			return([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: type] boolValue]);

	} else {
		// These are the types we supress when Extended Logging isn't enabled

      if (strcmp(type_s, LOG_CONDITION)		== 0) return NO;
      if (strcmp(type_s, LOG_RULE)			== 0) return NO;
      if (strcmp(type_s, LOG_MOVEMENT)		== 0) return NO;
      if (strcmp(type_s, LOG_DEV)			== 0) return NO;
      if (strcmp(type_s, LOG_WAYPOINT)		== 0) return NO;
      if (strcmp(type_s, LOG_BINDINGS)		== 0) return NO;
      if (strcmp(type_s, LOG_STATISTICS)	== 0) return NO;
      if (strcmp(type_s, LOG_MACRO)			== 0) return NO;
      if (strcmp(type_s, LOG_EVALUATE)		== 0) return NO;
      if (strcmp(type_s, LOG_BLACKLIST)		== 0) return NO;
      if (strcmp(type_s, LOG_FUNCTION)		== 0) return NO;
      if (strcmp(type_s, LOG_MEMORY)		== 0) return NO;
	//if (strcmp(type_s, LOG_PROCEDURE)		== 0) return NO;
      if (strcmp(type_s, LOG_CONTROLLER)	== 0) return NO;

	}

	// If it's not been supressed let's allow it
	return YES;
	
}

+ (NSString*) log:(char*)type_s, ...
{
	NSString* type = [NSString stringWithFormat:@"%s", type_s];
	va_list args;
	va_start(args, type_s);
	NSString* format = va_arg(args, NSString*);
	NSMutableString* output = [[NSMutableString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	output = [NSString stringWithFormat:@"[%@] %@", type, output];
	return output;
}

@end
