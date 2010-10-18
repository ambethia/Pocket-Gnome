//
//  NodeController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/29/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "NodeController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "MemoryViewController.h"
#import "MovementController.h"
#import "ObjectsController.h"
#import "Waypoint.h"
#import "Offsets.h"

#import "ImageAndTextCell.h"

#import <Growl/GrowlApplicationBridge.h>

typedef enum {
    Filter_All              = -100,
    Filter_Mine_Herb        = -4,
    Filter_Container_Quest  = -3,
    Filter_Herbs            = -2,
    Filter_Minerals         = -1,
    Filter_Transport        = 11,
} FilterType;

@interface NodeController (Internal)

- (int)nodeLevel: (Node*)node;
- (BOOL)trackingNode: (Node*)trackingNode;
- (void)reloadNodeData: (id)sender;
- (void)fishingCheck;

@end

@implementation NodeController

- (id) init
{
    self = [super init];
    if (self != nil) {

        _finishedNodes = [[NSMutableArray array] retain];
        
        // load in our gathering dictionaries
        NSDictionary *gatheringDict = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Gathering" ofType: @"plist"]];
        if(gatheringDict) {
            _miningDict = [[gatheringDict objectForKey: @"Mining"] retain];
            _herbalismDict = [[gatheringDict objectForKey: @"Herbalism"] retain];
        } else {
            log(LOG_GENERAL, @"Unable to load Gathering information.");
        }
        
        // load in node names
        //id nodeNames = [[NSUserDefaults standardUserDefaults] objectForKey: @"NodeNames"];
//        if(nodeNames) {
//            _nodeNames = [[NSKeyedUnarchiver unarchiveObjectWithData: nodeNames] mutableCopy];            
//        } else
//            _nodeNames = [[NSMutableDictionary dictionary] retain];
		
		//
		
		NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   @"1.0",								@"NodeControllerUpdateFrequency",
									   [NSNumber numberWithInt: -100],      @"NodeFilterType", nil];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
		[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
    }
    return self;
}

- (void)dealloc{
	[_objectList release];
	[_objectDataList release];
	[_finishedNodes release];
	[_miningDict release];
	[_herbalismDict release];

	[super dealloc];
}

#pragma mark Dataset Modification

- (unsigned)nodeCount {
    return [_objectList count];
}

#pragma mark Internal

- (int)nodeLevel: (Node*)node {
    NSString *key = [node name];
    if([_herbalismDict objectForKey: key])
        return [[[_herbalismDict objectForKey: key] objectForKey: @"Skill"] intValue];
    if([_miningDict objectForKey: key])
        return [[[_miningDict objectForKey: key] objectForKey: @"Skill"] intValue];
    return 0;
}

//- (NSString*)nodeName: (Node*)node {
//    return [node name];
//
//    NSNumber *keyNum = [NSNumber numberWithInt: [node entryID]];
//    NSString *keyStr = [keyNum stringValue];
//    if([_herbalismDict objectForKey: keyStr])
//        return [[_herbalismDict objectForKey: keyStr] objectForKey: @"Name"];
//    if([_miningDict objectForKey: keyStr])
//        return [[_miningDict objectForKey: keyStr] objectForKey: @"Name"];
//    if([_fishingDict objectForKey: keyStr])
//        return [[_fishingDict objectForKey: keyStr] objectForKey: @"Name"];
//    if([_otherDict objectForKey: keyStr])
//        return [[_otherDict objectForKey: keyStr] objectForKey: @"Name"];
//        
//    if([_nodeNames objectForKey: keyNum])
//        return [_nodeNames objectForKey: keyNum];
//        
//    return nil;
//}


- (BOOL)trackingNode: (Node*)trackingNode {
    for(Node *node in _objectList) {
        if( [node isEqualToObject: trackingNode] ) {
            return YES;
        }
    }
    return NO;
}

#pragma mark External Query


- (NSArray*)nodesOfType:(UInt32)nodeType shouldLock:(BOOL)lock {
	
	// Make a copy or we will run into some "Collection <NSCFArray: 0x13a0e0> was mutated while being enumerated." errors and crash
	//   Mainly b/c we access this from another thread
	NSArray *nodeList = nil;
	if (lock ){
		@synchronized(_objectList){
			nodeList = [[_objectList copy] autorelease];
		}
	}
	else{
		nodeList = [[_objectList copy] autorelease];
	}
	
	NSMutableArray *nodes = [NSMutableArray array];
	for(Node *node in nodeList) {
		if ( [node nodeType] == nodeType ){
			[nodes addObject: node];
		}
	}
	
	return nodes;
}

- (NSArray*)allMiningNodes {
    NSMutableArray *nodes = [NSMutableArray array];
    
    for(Node *node in _objectList) {
        if( [_miningDict objectForKey: [node name]])
            [nodes addObject: node];
    }
    
    return nodes;
}

- (NSArray*)allHerbalismNodes {
    NSMutableArray *nodes = [NSMutableArray array];
    
    for(Node *node in _objectList) {
        if( [_herbalismDict objectForKey: [node name]])
            [nodes addObject: node];
    }
    
    return nodes;
}
- (NSArray*)nodesWithinDistance: (float)nodeDistance NodeIDs: (NSArray*)nodeIDs position:(Position*)position{
	
	NSMutableArray *nearbyNodes = [NSMutableArray array];
    for(Node *node in _objectList) {
		
		// Just return nearby nodes
		if ( nodeIDs == nil ){
			float distance = [position distanceToPosition: [node position]];
			if((distance != INFINITY) && (distance <= nodeDistance)) {
				[nearbyNodes addObject: node];
			}
		}
		else{
			for ( NSNumber *entryID in nodeIDs ){
				if ( [node entryID] == [entryID intValue] ){
					float distance = [position distanceToPosition: [node position]];
					log(LOG_GENERAL, @"Found %d == %d with distance of %0.2f", [node entryID], [entryID intValue], distance);
					if((distance != INFINITY) && (distance <= nodeDistance)) {
						[nearbyNodes addObject: node];
					}
				}
			}
		}
	}
	
	return nearbyNodes;
}

- (NSArray*)nodesWithinDistance: (float)nodeDistance EntryID: (int)entryID position:(Position*)position{
	
	log(LOG_GENERAL, @"Searching for %d", entryID);
	NSMutableArray *nearbyNodes = [NSMutableArray array];
    for(Node *node in _objectList) {
		if ( [node entryID] == entryID ){
			float distance = [position distanceToPosition: [node position]];
			log(LOG_GENERAL, @"Found %d == %d with distance of %0.2f", [node entryID], entryID, distance);
			if((distance != INFINITY) && (distance <= nodeDistance)) {
				[nearbyNodes addObject: node];
			}
		}
	}
	
	return nearbyNodes;
}

- (NSArray*)nodesWithinDistance: (float)distance ofAbsoluteType: (GameObjectType)type {
    NSMutableArray *finalList = [NSMutableArray array];
    Position *playerPosition = [(PlayerDataController*)playerData position];
    for(Node* node in _objectList) {
        if(   [node isValid]
           && [node validToLoot]
           && ([playerPosition distanceToPosition: [node position]] <= distance)
           && ([node nodeType] == type)) {
            [finalList addObject: node];
        }
    }
    return finalList;
}

- (NSArray*)nodesWithinDistance: (float)distance ofType: (NodeType)type maxLevel: (int)level {
    NSArray *nodeList = nil;
    NSMutableArray *finalList = [NSMutableArray array];
    if(type == AnyNode)         nodeList = _objectList;
    if(type == MiningNode)      nodeList = [self allMiningNodes];
    if(type == HerbalismNode)   nodeList = [self allHerbalismNodes];
	if(type == FishingSchool)	nodeList = [self nodesOfType:GAMEOBJECT_TYPE_FISHINGHOLE shouldLock:NO];
	
    Position *playerPosition = [(PlayerDataController*)playerData position];
    for(Node* node in nodeList) {
        if(   [node isValid]
           && [node validToLoot]
           && ([playerPosition distanceToPosition: [node position]] <= distance)
           && ([self nodeLevel: node] <= level)
           && ![_finishedNodes containsObject: node]) {
            [finalList addObject: node];
        }
    }
    return finalList;
}

- (Node*)closestNodeForInteraction:(UInt32)entryID {
    NSArray *nodeList = _objectList;
    Position *playerPosition = [(PlayerDataController*)playerData position];
    for(Node* node in nodeList) {
		
		if ( [node entryID]==entryID ){
			log(LOG_GENERAL, @"Node id found! %d", [node entryID]);
			
			log(LOG_GENERAL, @"%d %d %d", [node isValid], [node isUseable], ([playerPosition distanceToPosition: [node position]] <= 10) );
		}
		
		if( [node isValid] && [node entryID]==entryID && [node isUseable] && ([playerPosition distanceToPosition: [node position]] <= 10) ) {
            return node;
        }
    }
	log(LOG_GENERAL, @"[Node] No node for interaction");
    return nil;
}

- (Node*)closestNode:(UInt32)entryID {
    NSArray *nodeList = _objectList;
    Position *playerPosition = [(PlayerDataController*)playerData position];
	Node *closestNode = nil;
	float closestDistance = INFINITY;
	float distance = 0.0f;
    for(Node* node in nodeList) {
		distance = [playerPosition distanceToPosition: [node position]];
		if( [node isValid] && [node entryID]==entryID && (distance <= closestDistance) ) {
            closestDistance = distance;
			closestNode = node;			
        }
    }
    return closestNode;
}

- (Node*)nodeWithEntryID:(UInt32)entryID{
	for(Node* node in _objectList) {
		if ( [node entryID] == entryID ){
			return node;
		}
    }
	
    return nil;
}

#pragma mark ObjectsController helpers

- (NSArray*)uniqueNodesAlphabetized{
	
	NSMutableArray *addedNodeNames = [NSMutableArray array];
	
	for ( Node *node in _objectList ){
		if ( ![addedNodeNames containsObject:[node name]] ){
			[addedNodeNames addObject:[node name]];
		}
	}
	
	[addedNodeNames sortUsingSelector:@selector(compare:)];
	
	return [[addedNodeNames retain] autorelease];
}

- (Node*)closestNodeWithName:(NSString*)nodeName{
	
	NSMutableArray *nodesWithName = [NSMutableArray array];
	
	// find mobs with the name!
	for ( Node *node in _objectList ){
		if ( [nodeName isEqualToString:[node name]] ){
			[nodesWithName addObject:node];
		}
	}
	
	if ( [nodesWithName count] == 1 ){
		return [nodesWithName objectAtIndex:0];
	}
	
	Position *playerPosition = [playerData position];
	Node *closestNode = nil;
	float closestDistance = INFINITY;
	for ( Node *node in nodesWithName ){
		
		float distance = [playerPosition distanceToPosition:[node position]];
		if ( distance < closestDistance ){
			closestDistance = distance;
			closestNode = node;
		}
	}
	
	return closestNode;	
}

#pragma mark Sub Class implementations

- (void)objectAddedToList:(WoWObject*)obj{
	// we could do a check to make sure the object is valid and remove if not?
	// probably not though
}

- (id)objectWithAddress:(NSNumber*) address inMemory:(MemoryAccess*)memory{
	return [Node nodeWithAddress:address inMemory:memory];
}

- (NSString*)updateFrequencyKey{
	return @"NodeControllerUpdateFrequency";
}

- (unsigned int)objectCountWithFilters{
	
	int filterType = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NodeFilterType"] intValue];
	
	if ( [_objectDataList count] || filterType != -100 )
		return [_objectDataList count];
	
	return [_objectList count];
}

- (void)refreshData{
	
	// remove old objects
	[_objectDataList removeAllObjects];
	
	// is tab viewable?
	if ( ![objectsController isTabVisible:Tab_Nodes] )
		return;
	
    if ( ![playerData playerIsValid:self] ) return;
    
	int filterType = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NodeFilterType"] intValue];  
	NSString *filterString = [objectsController nameFilter];
	Position *playerPosition = [(PlayerDataController*)playerData position];
	
    for ( Node *node in _objectList ) {
        NSString *name = [node name];
        name = ((name && [name length]) ? name : @"Unknown");
        
        float distance = [playerPosition distanceToPosition: [node position]];
        
        NSString *type = nil;
        int typeVal = [node nodeType];
        if( [_miningDict objectForKey: name])       type = @"Mining";
        if( [_herbalismDict objectForKey: name])    type = @"Herbalism";
		
        // first, do type filter
        if ( filterType < 0 ) {
            // all              = -100
            // minerals         = -1
            // herbs            = -2
            // quest container  = -3
            // mine/herb        = -4
            // transport        = 11
			
            if ( ( filterType == Filter_Minerals)     && ![type isEqualToString: @"Mining"] )		continue;
            if ( ( filterType == Filter_Herbs)        && ![type isEqualToString: @"Herbalism"] )	continue;
            if ( ( filterType == Filter_Mine_Herb)    && !type)										continue;
            if ( ( filterType == Filter_Container_Quest)) {
                if ( ( typeVal != 3 ) || ( ( [node flags] & GAMEOBJECT_FLAG_CANT_TARGET ) != GAMEOBJECT_FLAG_CANT_TARGET ) ) {
                    continue;   // must be a container, and flagged as quest
                }
            }
            
        } 
		else{
            if ( filterType == Filter_Transport ){
                if ( ( typeVal != 11 ) || ( typeVal != 15 ) ) continue; // both types of transport
            }
			else{
                if ( filterType != typeVal )
                    continue;
            }
        }
        
        // then, do string filter

        if ( filterString ){
            if([[node name] rangeOfString: filterString options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location == NSNotFound) {
                continue;
            }
        }
        
        // get the string if we don't have it already
        if ( !type )  type = [node stringForNodeType: typeVal];
        
        // invalid no longer working in 3.0.2
        name = ([node validToLoot] ? name : [name stringByAppendingString: @" [Invalid]"]);
        
        [_objectDataList addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                   node,                                                        @"Node",
                                   name,                                                        @"Name",
                                   [NSNumber numberWithInt: [node entryID]],                    @"ID",
                                   [NSString stringWithFormat: @"0x%X", [node baseAddress]],    @"Address",
                                   [NSNumber numberWithFloat: distance],                        @"Distance",
                                   type,                                                        @"Type",
                                   [node imageForNodeType: [node nodeType]],                    @"NameIcon",
								   [NSNumber numberWithUnsignedInt:[node objectHealth]],		@"Health",		// probably wrong, dunno
                                   nil]];
    }
	
	// sort
	[_objectDataList sortUsingDescriptors: [[objectsController nodeTable] sortDescriptors]];
	
	// reload table
	[objectsController loadTabData];
}

- (WoWObject*)objectForRowIndex:(int)rowIndex{
	if ( rowIndex >= [_objectDataList count] ) return nil;
	return [[_objectDataList objectAtIndex: rowIndex] objectForKey: @"Node"];
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if ( rowIndex == -1 || rowIndex >= [_objectDataList count] ) return nil;
    
    if ( [[aTableColumn identifier] isEqualToString: @"Distance"] )
        return [NSString stringWithFormat: @"%.2f", [[[_objectDataList objectAtIndex: rowIndex] objectForKey: @"Distance"] floatValue]];
    
    return [[_objectDataList objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex
{
    if ( aRowIndex == -1 || aRowIndex >= [_objectDataList count] ) return;
	
    if ( [[aTableColumn identifier] isEqualToString: @"Name"] ){
        [(ImageAndTextCell*)aCell setImage: [[_objectDataList objectAtIndex: aRowIndex] objectForKey: @"NameIcon"]];
    }
}

- (void)tableDoubleClick: (id)sender {
    if ( [sender clickedRow] == -1 ) return;
    
    [memoryViewController showObjectMemory: [[_objectDataList objectAtIndex: [sender clickedRow]] objectForKey: @"Node"]];
    [controller showMemoryView];
}

@end
