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
 * $Id: ProfileController.h 315 2010-04-17 04:12:45Z Tanaris4 $
 *
 */

#import <Cocoa/Cocoa.h>

#define ProfilesLoaded @"ProfilesLoaded"

@class FileController;
@class Controller;
@class PlayersController;
@class MobController;

@class Profile;
@class CombatProfile;
@class MailActionProfile;

typedef enum SelectedTab{
	TabCombat = 1,
	TabMail = 2,
	TabTotal,
} SelectedTab;

@interface ProfileController : NSObject {
	IBOutlet FileController		*fileController;
	IBOutlet Controller			*controller;
	IBOutlet PlayersController	*playersController;
	IBOutlet MobController		*mobController;
	
	IBOutlet NSPopUpButton		*profileTypePopUp;
	IBOutlet NSTabView			*profileTabView;
	IBOutlet NSOutlineView		*profileOutlineView;
	IBOutlet NSTextField		*profileTitle;
	
	// combat profile only
	IBOutlet NSPopUpButton		*assistPopUpButton;
	IBOutlet NSPopUpButton		*tankPopUpButton;
	IBOutlet NSPopUpButton		*followPopUpButton;
	IBOutlet NSTableView		*ignoreTable;
	
	IBOutlet NSView *view;
	NSSize minSectionSize, maxSectionSize;
	
	CombatProfile		*_currentCombatProfile;
	MailActionProfile	*_currentMailActionProfile;
	
	SelectedTab _selectedTab;
	
	NSMutableArray *_profiles;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

@property (readwrite, retain) CombatProfile *currentCombatProfile;
@property (readwrite, retain) MailActionProfile *currentMailActionProfile;

- (void)importProfileAtPath: (NSString*)path;

// profile actions
- (IBAction)createProfile: (id)sender;
- (IBAction)renameProfile: (id)sender;
- (IBAction)duplicateProfile: (id)sender;
- (IBAction)importProfile: (id)sender;
- (IBAction)exportProfile: (id)sender;
- (IBAction)deleteProfile: (id)sender;
- (IBAction)showInFinder: (id)sender;

// combat profile only
- (IBAction)addIgnoreEntry: (id)sender;
- (IBAction)addIgnoreFromTarget: (id)sender;
- (IBAction)deleteIgnoreEntry: (id)sender;

- (NSArray*)profilesOfClass:(Class)objectClass;

- (void)addProfile:(Profile*)profile;
- (BOOL)removeProfile:(Profile*)profile;

- (void)populatePlayerLists;

- (Profile*)profileForUUID:(NSString*)uuid;

// for bindings
- (NSArray*)combatProfiles;

- (void)openEditor:(SelectedTab)tab;
- (void)setProfile:(Profile *)profile;

@end