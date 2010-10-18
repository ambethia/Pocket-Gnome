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
 * $Id: FileController.h 315 2010-04-23 04:12:45Z Tanaris4 $
 *
 */

#import "FileController.h"
#import "FileObject.h"

// types of files we're saving
#import "RouteCollection.h"
#import "CombatProfile.h"
#import "MailActionProfile.h"
#import "Behavior.h"
#import "PvPBehavior.h"
#import "RouteSet.h"

#define APPLICATION_SUPPORT_FOLDER	@"~/Library/Application Support/PocketGnome/"

@interface FileController (Internal)
- (NSString*)applicationSupportFolder;
- (NSString*)pathWithFilename:(NSString*)filename;
- (BOOL)saveObject:(FileObject*)obj;
- (NSString*)pathForObject:(FileObject*)obj;
- (NSString*)extensionForClass:(Class)class;
- (id)getObject:(NSString*)filename;
@end

@implementation FileController

static FileController *_sharedFileController = nil;

+ (FileController*)sharedFileController{
	if (_sharedFileController == nil)
		_sharedFileController = [[[self class] alloc] init];
	return _sharedFileController;
}

- (id) init {
    self = [super init];
    if ( self != nil ) {
		
		// create directory?
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *folder = [self applicationSupportFolder];
		
		// create folder?
		if ( [fileManager fileExistsAtPath: folder] == NO ) {
			PGLog(@"[FileManager] Save data folder does not exist! Creating %@", folder);
			[fileManager createDirectoryAtPath: folder attributes: nil];
		}
	}
	
    return self;
}

#pragma mark Public


// save all objects in the array
- (BOOL)saveObjects:(NSArray*)objects{
	
	for ( FileObject *obj in objects ){
		if ( obj.changed ){
			[self saveObject:obj];
		}
	}
	
	return YES;
}

// get all objects with the extension
- (NSArray*)getObjectsWithClass:(Class)class{
	
	// load a list of files at the directory
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *directoryList = [fileManager contentsOfDirectoryAtPath:[self applicationSupportFolder] error:&error];
	if ( error ){
		PGLog(@"[FileManager] Error when reading your objects from %@! %@", directoryList, error);
		return nil;
	}
	
	NSMutableArray *objectList = [NSMutableArray array];
	NSString *ext = [self extensionForClass:class];
	
	// if we get here then we're good!
	if ( directoryList && [directoryList count] ){
		
		// loop through directory list
		for ( NSString *fileName in directoryList ){
			
			// valid object file
			if ( [[fileName pathExtension] isEqualToString: ext] ){
				
				id object = [self getObject:fileName];
				
				// we JUST loaded this from the disk, we need to make sure we know it's not changed
				[(FileObject*)object setChanged:NO];
				
				// valid route - add it!
				if ( object != nil ){
					[objectList addObject:object];
				}
			}
		}
	}
	
	return [[objectList retain] autorelease];
}

- (BOOL)deleteObject:(FileObject*)obj{
	NSString *filename = [self filenameForObject:obj];
	return [self deleteObjectWithFilename:filename];
}

// delete the object with this file name
- (BOOL)deleteObjectWithFilename:(NSString*)filename{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = [self pathWithFilename:filename];
	
	log(LOG_FILEMANAGER, @"deleting %@", filePath);
	
	if ( [fileManager fileExistsAtPath: filePath] ){
		NSError *error = nil;
		if ( ![fileManager removeItemAtPath:filePath error:&error] ){
			PGLog(@"[FileManager] Error %@ when trying to delete object %@", error, filePath);
			return NO;
		}
	}
	return YES;
}

// old method, before we started storing them in files
- (NSArray*)dataForKey: (NSString*)key withClass:(Class)class{
	
	// do we have data?
	id data = [[NSUserDefaults standardUserDefaults] objectForKey: key];
	
	if ( data ){
		NSArray *allData = [NSKeyedUnarchiver unarchiveObjectWithData: data];
		
		// do a check to see if this is old-style information (not stored in files)
		if ( allData != nil && [allData count] > 0 ){
			
			// is this the correct kind of class?
			if ( [[allData objectAtIndex:0] isKindOfClass:class] ){
				
				NSMutableArray *objects = [NSMutableArray array];
				
				for ( FileObject *obj in allData ){
					obj.changed = YES;
					[objects addObject:obj];
				}
				
				PGLog(@"[FileManager] Imported %d objects of type %@", [objects count], [self extensionForClass:class]);
				
				return [[objects retain] autorelease];
			}
		}
	}
	
	return nil;
}

#pragma mark Save/Get

// save an object
- (BOOL)saveObject:(FileObject*)obj{
	NSString *filePath = [self pathForObject:obj];
	if ( !filePath || [filePath length] == 0 ){
		PGLog(@"[FileManager] Unable to save object %@", obj);
		return NO;
	}
	
	PGLog(@"[FileManager] Saving %@ to %@", obj, filePath);
	[NSKeyedArchiver archiveRootObject: obj toFile: filePath];
	[obj setChanged:NO];
	return YES;	
}

// grab a single object
- (id)getObject:(NSString*)filename{
	NSString *path = [self pathWithFilename:filename];
	
	// verify the file exists
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ( [fileManager fileExistsAtPath: path] == NO ) {
		PGLog(@"[FileManager] Object %@ is missing! Unable to load", filename);
		return nil;
	}
	
	id object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	
	// not sure why i saved it as a dictionary before, i am r tard
	if ( [object isKindOfClass:[NSDictionary class]] ){
		object = [object valueForKey:@"Route"];
	}
	
	return [object retain];
}

// delete all objects with a given extension
- (void)deleteAllWithExtension:(NSString*)ext{
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *dir = [self applicationSupportFolder];
	NSArray *directoryList = [fileManager contentsOfDirectoryAtPath:dir error:&error];
	if ( error ){
		PGLog(@"[FileManager] Error when deleting your objects from %@! %@", directoryList, error);
		return;
	}
	
	// if we get here then we're good!
	if ( directoryList && [directoryList count] ){
		
		// loop through directory list
		for ( NSString *fileName in directoryList ){
			
			// valid object file
			if ( [[fileName pathExtension] isEqualToString: ext] ){
				
				NSString *filePath = [dir stringByAppendingPathComponent: fileName];
				
				PGLog(@"[FileManager] Removing %@", filePath);
				if ( ![fileManager removeItemAtPath:filePath error:&error] ){
					PGLog(@"[FileManager] Error %@ when trying to delete object %@", error, filePath);
				}
			}
		}
	}
}

#pragma mark Helpers

// extension for a given object class
- (NSString*)extensionForClass:(Class)class{
	
	// route (we shouldn't really have these SAVED anymore, but could find some)
	if ( class == [RouteSet class] ){
		return @"route";
	}
	// route collection
	else if ( class == [RouteCollection class] ){
		return @"routecollection";
	}
	// combat profile
	else if ( class == [CombatProfile class] ){
		return @"combatprofile";
	}
	// behavior
	else if ( class == [Behavior class] ){
		return @"behavior";
	}
	else if ( class == [PvPBehavior class] ){
		return @"pvpbehavior";
	}
	else if ( class == [MailActionProfile class] ){
		return @"mailprofile";
	}
	
	return nil;
}

// our app support folder
- (NSString*)applicationSupportFolder{
	NSString *folder = APPLICATION_SUPPORT_FOLDER;
	folder = [folder stringByExpandingTildeInPath];
	return [[folder retain] autorelease];
}

// filename with extension for an object
- (NSString*)filenameForObject:(FileObject*)obj{
	NSString *ext = [self extensionForClass:[obj class]];
	return [[[NSString stringWithFormat:@"%@.%@", [obj name], ext] retain] autorelease];
}

// full path with the filename
- (NSString*)pathWithFilename:(NSString*)filename{
	NSString *folder = [self applicationSupportFolder];
	return [[[folder stringByAppendingPathComponent: filename] retain] autorelease];
}

// full path to an object
- (NSString*)pathForObject:(FileObject*)obj{
	NSString *filename = [self filenameForObject:obj];
	return [[[self pathWithFilename:filename] retain] autorelease];	
}

#pragma mark UI Options (optional)

- (void)showInFinder: (id)object{
	
	NSString *filePath = [self applicationSupportFolder];
	
	// show in finder!
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	[ws openFile: filePath];
}

@end
