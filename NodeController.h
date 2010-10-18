//
//  NodeController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/29/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Node.h"
#import "ObjectController.h"

@class PlayerDataController;
@class ObjectsController;

typedef enum {
    AnyNode = 0,
    MiningNode = 1,
    HerbalismNode = 2,
	FishingSchool = 3,
} NodeType;

@interface NodeController : ObjectController {
    IBOutlet id botController;
    IBOutlet id movementController;
    IBOutlet id memoryViewController;
	IBOutlet ObjectsController	*objectsController;
    
    IBOutlet NSPopUpButton *moveToList;

    NSMutableArray *_finishedNodes;
    
    // NSMutableDictionary *_nodeNames;

    NSDictionary *_miningDict;
    NSDictionary *_herbalismDict;
	
    int _nodeTypeFilter;
}

- (unsigned)nodeCount;

- (NSArray*)nodesOfType:(UInt32)nodeType shouldLock:(BOOL)lock;
- (NSArray*)allMiningNodes;
- (NSArray*)allHerbalismNodes;
- (NSArray*)nodesWithinDistance: (float)distance ofAbsoluteType: (GameObjectType)type;
- (NSArray*)nodesWithinDistance: (float)distance ofType: (NodeType)type maxLevel: (int)level;
- (NSArray*)nodesWithinDistance: (float)nodeDistance NodeIDs: (NSArray*)nodeIDs position:(Position*)position;
- (NSArray*)nodesWithinDistance: (float)nodeDistance EntryID: (int)entryID position:(Position*)position;
- (Node*)closestNode:(UInt32)entryID;
- (Node*)closestNodeForInteraction:(UInt32)entryID;
- (Node*)nodeWithEntryID:(UInt32)entryID;

- (NSArray*)uniqueNodesAlphabetized;
- (Node*)closestNodeWithName:(NSString*)nodeName;
/*
- (IBAction)filterNodes: (id)sender;
- (IBAction)resetList: (id)sender;
- (IBAction)faceNode: (id)sender;
- (IBAction)targetNode: (id)sender;
- (IBAction)filterList: (id)sender;

- (IBAction)moveToStart: (id)sender;
- (IBAction)moveToStop: (id)sender;*/

@end
