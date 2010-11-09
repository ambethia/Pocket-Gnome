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
 * $Id: MemoryViewController.h 435 2010-04-23 19:01:10Z ootoaoo $
 *
 */

#import <Cocoa/Cocoa.h>
#import "MemoryAccess.h"

@class Controller;
@class OffsetController;
@class InventoryController;
@class MobController;
@class PlayersController;
@class NodeController;

@interface MemoryViewController : NSView {
    IBOutlet Controller *controller;
	IBOutlet OffsetController *offsetController;
    IBOutlet id memoryTable;
    IBOutlet id memoryViewWindow;
	IBOutlet InventoryController *itemController;
	IBOutlet MobController *mobController;
	IBOutlet PlayersController *playersController;
	IBOutlet NodeController *nodeController;
	
	
    IBOutlet NSView *view;
    NSNumber *_currentAddress;
    NSTimer *_refreshTimer;
	NSMutableDictionary *_lastValues;
	int _formatOfSavedValues;
	
	IBOutlet NSTableView	*bitTableView;
	IBOutlet NSPanel		*bitPanel;
	
	// search options
	IBOutlet NSPanel		*searchPanel;
	IBOutlet NSPopUpButton	*searchTypePopUpButton;
	IBOutlet NSPopUpButton	*operatorPopUpButton;
	IBOutlet NSMatrix		*signMatrix;
	IBOutlet NSMatrix		*valueMatrix;
	IBOutlet NSTextField	*searchText;
	IBOutlet NSButton		*searchButton;
	IBOutlet NSButton		*clearButton;
	IBOutlet NSTableView	*searchTableView;
	NSArray					*_searchArray;
	
	// offset scanning
	IBOutlet NSPanel		*offsetScanPanel;
	IBOutlet NSTextView		*resultsTextView;
	IBOutlet NSTextField	*maskTextField;
	IBOutlet NSTextField	*signatureTextField;
	IBOutlet NSButton		*emulatePPCButton;
	
	// pointer scanning
	IBOutlet NSPanel				*pointerScanPanel;
	IBOutlet NSProgressIndicator	*pointerScanProgressIndicator;
	IBOutlet NSTextField			*pointerScanNumTextField;
	IBOutlet NSTextField			*pointerScanVariationTextField;
	IBOutlet NSButton				*pointerScanVariationButton;
	IBOutlet NSButton				*pointerScanCancelButton;
	IBOutlet NSButton				*pointerScanFindButton;
	NSThread *_pointerScanThread;
    
    float refreshFrequency;
    int _displayFormat;
    int _displayCount;
    //id callback;
	
	// new method to select non wow-processes
	NSTimer *_instanceListTimer;
	IBOutlet NSPopUpButton *instanceList;
	pid_t _attachedPID;
	MemoryAccess *_memory;
	
	// new pointer search
	NSMutableDictionary *_pointerList;
    
    id _wowObject;
	
    NSSize minSectionSize, maxSectionSize;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;    
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite) float refreshFrequency;

- (void)showObjectMemory: (id)object;

- (void)monitorObject: (id)object;
- (void)monitorObjects: (id)objects;

- (void)setBaseAddress: (NSNumber*)address;

- (IBAction)setCustomAddress: (id)sender;
- (IBAction)clearTable: (id)sender;
- (IBAction)snapshotMemory: (id)sender;
- (IBAction)saveValues: (id)sender;
- (IBAction)clearValues: (id)sender;

// menu options
- (IBAction)menuAction: (id)sender;

- (int)displayFormat;
- (void)setDisplayFormat: (int)displayFormat;

// search option
- (IBAction)openSearch: (id)sender;
- (IBAction)startSearch: (id)sender;
- (IBAction)clearSearch: (id)sender;
- (IBAction)typeSelected: (id)sender;

// offset scanning
- (IBAction)openOffsetPanel: (id)sender;
- (IBAction)offsetSelectAction: (id)sender;

// pointer scanning
- (IBAction)openPointerPanel: (id)sender;
- (IBAction)pointerSelectAction: (id)sender;

// new instance list
- (IBAction)selectInstance: (id)sender;

@end
